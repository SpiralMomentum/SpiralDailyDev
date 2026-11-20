import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:utils/utils.dart';

import '../../domain/entities/evaluation.dart';
import '../flow/attempt_flow.dart';
import 'attempt_event.dart';
import 'attempt_state.dart';

/// 대기 중 광고 제안 여부를 정한다. 광고 기능은 앱 조립 영역이 연결한다 (feature 간 직접 참조 금지).
typedef AdOfferDecider = Future<bool> Function({required bool manifested});

/// 보상형 광고를 보여 주고 보상 여부를 돌려준다.
typedef RewardedAdShower = Future<Result<bool>> Function();

/// 한 번의 시행(문항 -> 대기 -> 결과)을 이끈다. 채널 시행과 이야기 만남은 [AttemptFlow] 로
/// 같은 방식으로 다룬다. 시행마다(첫 진입, 한 번 더) [createFlow] 로 새 흐름을 만든다.
/// 핸들러가 4개라 bloc_guideline 수치 기준에 따라 Bloc 을 쓴다. 이벤트는 기본 동시 처리지만
/// 각 핸들러가 현재 단계/광고 상태를 확인하므로 중복 탭은 무시된다. 특히 마지막 답 이후의
/// 탭은 generating 단계에서 걸러져 계획(기록 저장)은 한 시행에 한 번만 일어난다.
/// 계획이 실패하면 failure 단계로 가며, 같은 흐름으로 다시 계획하지 않는다.
/// 대기 단계에서 발현이 있고 온라인이면 보상형 광고를 제안하고, 문장 생성은 병렬로 진행한다.
class AttemptBloc extends Bloc<AttemptEvent, AttemptState> {
  AttemptBloc({
    required AttemptFlow Function() createFlow,
    required AdOfferDecider decideAdOffer,
    required RewardedAdShower showRewardedAd,
  }) : _createFlow = createFlow,
       _decideAdOffer = decideAdOffer,
       _showRewardedAd = showRewardedAd,
       super(const AttemptState()) {
    on<AttemptStarted>(_onStarted);
    on<ChoiceSelected>(_onChoiceSelected);
    on<AdWatchRequested>(_onAdWatchRequested);
    on<AdSkipped>(_onAdSkipped);
  }

  final AttemptFlow Function() _createFlow;
  final AdOfferDecider _decideAdOffer;
  final RewardedAdShower _showRewardedAd;

  AttemptFlow? _flow;
  Future<EvaluationResult>? _composing;

  Future<void> _onStarted(
    AttemptStarted event,
    Emitter<AttemptState> emit,
  ) async {
    final flow = _createFlow();
    _flow = flow;
    _composing = null;
    // 한 번 더: 이전 결과를 지우고 문항이 실릴 때까지 빈 화면.
    if (state != const AttemptState()) emit(const AttemptState());
    final started = await flow.start();
    // 시작을 기다리는 사이 새 시행이 시작되었으면 이 결과는 버린다.
    if (!identical(_flow, flow)) return;
    switch (started) {
      case Success(:final data):
        emit(
          AttemptState(
            art: flow.art,
            intro: data.intro,
            questions: data.questions,
          ),
        );
      case ErrorResult(:final failure):
        emit(
          AttemptState(
            phase: AttemptPhase.failure,
            errorMessage: failure.message,
          ),
        );
    }
  }

  Future<void> _onChoiceSelected(
    ChoiceSelected event,
    Emitter<AttemptState> emit,
  ) async {
    final flow = _flow;
    if (state.phase != AttemptPhase.quiz ||
        state.currentQuestion == null ||
        flow == null) {
      return;
    }
    final answers = [...state.answers, event.choiceId];
    emit(state.copyWith(answers: answers));
    if (answers.length < state.questions.length) return;

    emit(state.copyWith(phase: AttemptPhase.generating));
    final planned = await flow.plan(answers);
    if (!identical(_flow, flow)) return;
    switch (planned) {
      case ErrorResult(:final failure):
        emit(
          state.copyWith(
            phase: AttemptPhase.failure,
            errorMessage: failure.message,
          ),
        );
        return;
      case Success(data: final offerReward):
        _composing = flow.compose();
        // 보상 제안이 의미 없는 흐름(이야기)은 false 라 광고를 제안하지 않는다.
        if (await _decideAdOffer(manifested: offerReward)) {
          emit(state.copyWith(adStatus: AdStatus.offered));
          return;
        }
        await _finish(emit, flow, rewarded: false);
    }
  }

  Future<void> _onAdWatchRequested(
    AdWatchRequested event,
    Emitter<AttemptState> emit,
  ) async {
    final flow = _flow;
    if (state.adStatus != AdStatus.offered || flow == null) return;
    emit(state.copyWith(adStatus: AdStatus.watching));
    final shown = await _showRewardedAd();
    final rewarded = shown.dataOrNull ?? false;
    emit(
      state.copyWith(
        adStatus: shown.isError
            ? AdStatus.failed
            : rewarded
            ? AdStatus.rewarded
            : AdStatus.declined,
      ),
    );
    await _finish(emit, flow, rewarded: rewarded);
  }

  Future<void> _onAdSkipped(AdSkipped event, Emitter<AttemptState> emit) async {
    final flow = _flow;
    if (state.adStatus != AdStatus.offered || flow == null) return;
    emit(state.copyWith(adStatus: AdStatus.declined));
    await _finish(emit, flow, rewarded: false);
  }

  Future<void> _finish(
    Emitter<AttemptState> emit,
    AttemptFlow flow, {
    required bool rewarded,
  }) async {
    final composed = await _composing!;
    final result = rewarded ? flow.extend(composed) : composed;
    emit(state.copyWith(phase: AttemptPhase.result, result: result));
  }
}
