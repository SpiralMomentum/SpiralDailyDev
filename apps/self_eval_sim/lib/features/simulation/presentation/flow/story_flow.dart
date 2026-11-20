import 'package:utils/utils.dart';

import '../../domain/entities/catalog.dart';
import '../../domain/entities/evaluation.dart';
import '../../domain/story/story_composer.dart';
import '../../domain/story/story_text.dart';
import '../../domain/story/story_use_cases.dart';
import '../../domain/story/story_world.dart';
import 'attempt_flow.dart';

/// 이야기 만남 한 번. 시작에서 인물/질문/도입을 정하고, 계획에서 만남과 누적을 저장한다.
///
/// 만남 기록과 누적 저장은 원자적이지 않으므로 같은 준비로 계획을 두 번 하지 않는다
/// (중복 호출은 첫 결과를 돌려주고, 실패해도 다시 계획하지 않는다).
/// 광고 보상 확장 장면은 이번 범위 밖이라 [extend] 는 결과를 그대로 돌려주고, 보상이 없는
/// 광고를 띄우지 않도록 [plan] 은 발현해도 보상 제안 없음(false)을 돌려준다.
/// 확장 장면이 생기면 [plan] 이 발현 여부를 돌려주게 바꾼다.
class StoryFlow implements AttemptFlow {
  StoryFlow(
    this._world,
    this._content,
    this._startMeeting,
    this._planMeeting,
    this._composeMeeting, {
    required String channelArt,
  }) : _channelArt = channelArt;

  final StoryWorld _world;
  final LocalizedContent _content;
  final StartMeetingUseCase _startMeeting;
  final PlanMeetingUseCase _planMeeting;
  final ComposeMeetingUseCase _composeMeeting;

  /// 인물 배경이 없을 때(또는 시작 전) 쓰는 채널 배경.
  final String _channelArt;

  MeetingSetup? _setup;
  Future<Result<bool>>? _planning;
  MeetingPlan? _plan;

  @override
  String get art => switch (_setup) {
    final setup? => _content.text.characterArt(
      _world.id,
      setup.character.id,
      _channelArt,
    ),
    null => _channelArt,
  };

  @override
  Future<Result<AttemptStart>> start() async {
    final started = await _startMeeting(_world, _content.text);
    return started.map((setup) {
      _setup = setup;
      return (
        intro: setup.intro,
        questions: StoryComposer.questions(_world, _content.text, setup),
      );
    });
  }

  @override
  Future<Result<bool>> plan(List<String> choiceIds) =>
      _planning ??= _doPlan(choiceIds);

  Future<Result<bool>> _doPlan(List<String> choiceIds) async {
    final setup = _setup;
    if (setup == null) {
      return const ErrorResult(BusinessRuleFailure(message: 'not started'));
    }
    final planned = await _planMeeting(
      world: _world,
      setup: setup,
      choiceIds: choiceIds,
    );
    _plan = planned.dataOrNull;
    // 확장 장면이 없으므로 발현해도 보상 광고는 제안하지 않는다.
    return planned.map((_) => false);
  }

  @override
  Future<EvaluationResult> compose() {
    final plan = _plan;
    if (plan == null) throw StateError('compose before plan');
    return _composeMeeting(world: _world, text: _content.text, plan: plan);
  }

  @override
  EvaluationResult extend(EvaluationResult result) => result;
}
