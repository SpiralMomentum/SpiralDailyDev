import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:utils/utils.dart';

import '../../domain/entities/accumulation.dart';
import '../../domain/entities/catalog.dart';
import '../../domain/entities/evaluation.dart';
import '../../domain/usecases/compose_result_use_case.dart';
import '../../domain/usecases/extend_result_use_case.dart';
import '../../domain/usecases/plan_attempt_use_case.dart';
import '../../domain/usecases/start_attempt_use_case.dart';
import 'attempt_event.dart';
import 'attempt_state.dart';

/// 대기 중 광고 제안 여부를 정한다. 광고 기능은 앱 조립 영역이 연결한다 (feature 간 직접 참조 금지).
typedef AdOfferDecider = Future<bool> Function({required bool manifested});

/// 보상형 광고를 보여 주고 보상 여부를 돌려준다.
typedef RewardedAdShower = Future<Result<bool>> Function();

/// 한 번의 시행(문항 -> 대기 -> 결과)을 이끈다.
/// 핸들러가 4개라 bloc_guideline 수치 기준에 따라 Bloc 을 쓴다. 이벤트는 기본 동시 처리지만
/// 각 핸들러가 현재 단계/광고 상태를 확인하므로 중복 탭은 무시된다.
/// 대기 단계에서 발현이 있고 온라인이면 보상형 광고를 제안하고, 문장 생성은 병렬로 진행한다.
class AttemptBloc extends Bloc<AttemptEvent, AttemptState> {
  AttemptBloc({
    required this.channel,
    required this.content,
    required StartAttemptUseCase startAttempt,
    required PlanAttemptUseCase planAttempt,
    required ComposeResultUseCase composeResult,
    required ExtendResultUseCase extendResult,
    required AdOfferDecider decideAdOffer,
    required RewardedAdShower showRewardedAd,
  })  : _startAttempt = startAttempt,
        _planAttempt = planAttempt,
        _composeResult = composeResult,
        _extendResult = extendResult,
        _decideAdOffer = decideAdOffer,
        _showRewardedAd = showRewardedAd,
        super(const AttemptState()) {
    on<AttemptStarted>(_onStarted);
    on<ChoiceSelected>(_onChoiceSelected);
    on<AdWatchRequested>(_onAdWatchRequested);
    on<AdSkipped>(_onAdSkipped);
  }

  final Channel channel;
  final LocalizedContent content;
  final StartAttemptUseCase _startAttempt;
  final PlanAttemptUseCase _planAttempt;
  final ComposeResultUseCase _composeResult;
  final ExtendResultUseCase _extendResult;
  final AdOfferDecider _decideAdOffer;
  final RewardedAdShower _showRewardedAd;

  Future<EvaluationResult>? _composing;

  void _onStarted(AttemptStarted event, Emitter<AttemptState> emit) => emit(
        AttemptState(
          questions: _startAttempt(channel, content.catalog.questionsPerAttempt),
        ),
      );

  Future<void> _onChoiceSelected(ChoiceSelected event, Emitter<AttemptState> emit) async {
    final question = state.currentQuestion;
    if (state.phase != AttemptPhase.quiz || question == null) return;
    final answers = [
      ...state.answers,
      Answer(questionId: question.id, choiceId: event.choiceId),
    ];
    emit(state.copyWith(answers: answers));
    if (answers.length < state.questions.length) return;

    emit(state.copyWith(phase: AttemptPhase.generating));
    final planned = await _planAttempt(channel: channel, answers: answers);
    if (planned case ErrorResult(:final failure)) {
      emit(state.copyWith(phase: AttemptPhase.failure, errorMessage: failure.message));
      return;
    }
    final plan = planned.dataOrNull!;
    _composing = _composeResult(channel: channel, plan: plan, text: content.text);
    if (await _decideAdOffer(manifested: plan.manifested)) {
      emit(state.copyWith(adStatus: AdStatus.offered));
      return;
    }
    await _finish(emit, rewarded: false);
  }

  Future<void> _onAdWatchRequested(AdWatchRequested event, Emitter<AttemptState> emit) async {
    if (state.adStatus != AdStatus.offered) return;
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
    await _finish(emit, rewarded: rewarded);
  }

  Future<void> _onAdSkipped(AdSkipped event, Emitter<AttemptState> emit) async {
    if (state.adStatus != AdStatus.offered) return;
    emit(state.copyWith(adStatus: AdStatus.declined));
    await _finish(emit, rewarded: false);
  }

  Future<void> _finish(Emitter<AttemptState> emit, {required bool rewarded}) async {
    final composed = await _composing!;
    final result = rewarded ? _extendResult(composed, channel, content.text) : composed;
    emit(state.copyWith(phase: AttemptPhase.result, result: result));
  }
}
