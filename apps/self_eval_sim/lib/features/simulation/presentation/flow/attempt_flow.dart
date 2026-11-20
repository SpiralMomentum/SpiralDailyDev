import 'package:utils/utils.dart';

import '../../domain/entities/accumulation.dart';
import '../../domain/entities/catalog.dart';
import '../../domain/entities/evaluation.dart';
import '../../domain/entities/quiz_question.dart';
import '../../domain/story/story_world.dart';
import '../../domain/usecases/compose_result_use_case.dart';
import '../../domain/usecases/extend_result_use_case.dart';
import '../../domain/usecases/plan_attempt_use_case.dart';
import '../../domain/usecases/start_attempt_use_case.dart';

/// 시작 결과: 첫 질문 위에 보일 도입 문장과 화면에 그대로 그릴 문항.
typedef AttemptStart = ({List<String> intro, List<QuizQuestion> questions});

/// 한 시행(문항 -> 계획 -> 결과)의 진행 방식. 채널 시행과 이야기 만남이 같은 모양으로 동작한다.
/// 한 시행 동안의 상태(질문, 계획)를 들고 있는 단발성 객체다. 새 시행은 새 객체로 한다.
abstract interface class AttemptFlow {
  /// 문항/대기 화면의 배경 키.
  String get art;

  Future<Result<AttemptStart>> start();

  /// 답을 확정하고 기록을 저장한다. 성공 값은 보상형 광고 제안이 의미 있는지(offerReward)다:
  /// 보상으로 열어 줄 확장 장면이 있고 발현했을 때만 true. 광고 제안 판단에 그대로 쓰인다.
  /// 한 시행에 한 번만 저장한다: 두 번째 호출부터는 첫 호출의 결과를 그대로 돌려준다.
  Future<Result<bool>> plan(List<String> choiceIds);

  /// 확정된 계획으로 결과 장면을 만든다. [plan] 성공 전에 부르면 [StateError].
  Future<EvaluationResult> compose();

  /// 보상형 광고 보상으로 결과를 확장한다.
  EvaluationResult extend(EvaluationResult result);
}

/// 채널에 이야기가 있으면 이야기 흐름, 없으면 채널 흐름을 만드는 팩토리를 고른다.
abstract final class AttemptFlows {
  static AttemptFlow Function() select({
    required Channel channel,
    required LocalizedContent content,
    required AttemptFlow Function() channelFlow,
    required AttemptFlow Function(StoryWorld world, Channel channel) storyFlow,
  }) => switch (content.stories[channel.id]) {
    final world? => () => storyFlow(world, channel),
    null => channelFlow,
  };
}

/// 기존 채널 시행. 질문 문장은 채널 문장(`text.question/choice`)으로 풀고, 도입은 없다.
/// 확장 장면이 있으므로 발현이면 보상 광고를 제안한다 (offerReward = 발현 여부).
class ChannelFlow implements AttemptFlow {
  ChannelFlow(
    this._channel,
    this._content,
    this._startAttempt,
    this._planAttempt,
    this._composeResult,
    this._extendResult,
  );

  final Channel _channel;
  final LocalizedContent _content;
  final StartAttemptUseCase _startAttempt;
  final PlanAttemptUseCase _planAttempt;
  final ComposeResultUseCase _composeResult;
  final ExtendResultUseCase _extendResult;

  List<Question> _questions = const [];
  Future<Result<bool>>? _planning;
  AttemptPlan? _plan;

  @override
  String get art => _channel.art;

  @override
  Future<Result<AttemptStart>> start() async {
    _questions = _startAttempt(_channel, _content.catalog.questionsPerAttempt);
    final text = _content.text;
    return Success((
      intro: const <String>[],
      questions: [
        for (final q in _questions)
          QuizQuestion(
            id: q.id,
            text: text.question(_channel.id, q.id),
            choices: [
              for (final c in q.choices)
                QuizChoice(
                  id: c.id,
                  text: text.choice(_channel.id, q.id, c.id),
                ),
            ],
          ),
      ],
    ));
  }

  @override
  Future<Result<bool>> plan(List<String> choiceIds) =>
      _planning ??= _doPlan(choiceIds);

  Future<Result<bool>> _doPlan(List<String> choiceIds) async {
    if (choiceIds.length != _questions.length) {
      return const ErrorResult(BusinessRuleFailure(message: 'choices'));
    }
    final planned = await _planAttempt(
      catalog: _content.catalog,
      channel: _channel,
      answers: [
        for (final (i, q) in _questions.indexed)
          Answer(questionId: q.id, choiceId: choiceIds[i]),
      ],
    );
    _plan = planned.dataOrNull;
    return planned.map((p) => p.manifested);
  }

  @override
  Future<EvaluationResult> compose() {
    final plan = _plan;
    if (plan == null) throw StateError('compose before plan');
    return _composeResult(
      channel: _channel,
      plan: plan,
      text: _content.text,
      catalog: _content.catalog,
    );
  }

  @override
  EvaluationResult extend(EvaluationResult result) =>
      _extendResult(result, _channel, _content.text);
}
