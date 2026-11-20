import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:self_eval_sim/features/simulation/domain/entities/evaluation.dart';
import 'package:self_eval_sim/features/simulation/domain/entities/quiz_question.dart';
import 'package:self_eval_sim/features/simulation/presentation/bloc/attempt_state.dart';
import 'package:self_eval_sim/features/simulation/presentation/widgets/frame_plan.dart';
import 'package:self_eval_sim/features/simulation/presentation/widgets/generating_view.dart';
import 'package:self_eval_sim/features/simulation/presentation/widgets/quiz_view.dart';
import 'package:self_eval_sim/features/simulation/presentation/widgets/result_view.dart';

import '../../../support/pump.dart';

void main() {
  group('QuizView', () {
    const question = QuizQuestion(
      id: 'q2',
      text: '풀린 질문 2',
      choices: [
        QuizChoice(id: 'c1', text: '풀린 선택 1'),
        QuizChoice(id: 'c2', text: '풀린 선택 2'),
        QuizChoice(id: 'c3', text: '풀린 선택 3'),
      ],
    );

    Widget view({required int current, ValueChanged<String>? onChoice}) =>
        QuizView(
          art: 'wuxia',
          question: question,
          intro: const ['도입 첫 줄', '도입 둘째 줄'],
          current: current,
          total: 4,
          onChoice: onChoice ?? (_) {},
        );

    testWidgets('진행도, 질문, 선택지 3개를 보이고 탭하면 선택 id 를 넘긴다', (tester) async {
      String? picked;
      await tester.pumpLocalized(view(current: 2, onChoice: (id) => picked = id));
      expect(find.text('2 / 4'), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('question_text'))).data,
        '풀린 질문 2',
      );
      expect(find.text('풀린 선택 3'), findsOneWidget);
      await tester.tap(find.byKey(const Key('choice_2')));
      expect(picked, 'c3');
    });

    testWidgets('첫 질문에는 도입 문장이 보이고 둘째 질문부터는 안 보인다', (tester) async {
      await tester.pumpLocalized(view(current: 1));
      expect(find.byKey(const Key('quiz_intro')), findsOneWidget);
      expect(find.textContaining('도입 첫 줄'), findsOneWidget);
      expect(find.textContaining('도입 둘째 줄'), findsOneWidget);

      await tester.pumpLocalized(view(current: 2));
      expect(find.byKey(const Key('quiz_intro')), findsNothing);
      expect(find.textContaining('도입 첫 줄'), findsNothing);
    });

    testWidgets('도입 문장이 길어도 넘치지 않고 선택지가 보인다', (tester) async {
      await tester.pumpLocalized(
        QuizView(
          art: 'wuxia',
          question: question,
          intro: [for (var i = 0; i < 40; i++) '긴 도입 문장 $i'],
          current: 1,
          total: 4,
          onChoice: (_) {},
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('choice_2')).hitTestable(), findsOneWidget);
    });

    testWidgets('도입 문장이 없으면 첫 질문에도 도입 영역이 없다', (tester) async {
      await tester.pumpLocalized(
        QuizView(
          art: 'wuxia',
          question: question,
          intro: const [],
          current: 1,
          total: 4,
          onChoice: (_) {},
        ),
      );
      expect(find.byKey(const Key('quiz_intro')), findsNothing);
    });
  });

  group('GeneratingView', () {
    Future<void> pump(
      WidgetTester tester,
      AdStatus status, {
      VoidCallback? watch,
      VoidCallback? skip,
    }) => tester.pumpLocalized(
      GeneratingView(
        art: 'gem',
        adStatus: status,
        onWatchAd: watch ?? () {},
        onSkipAd: skip ?? () {},
      ),
    );

    testWidgets('광고 제안은 offered 일 때만 보인다', (tester) async {
      await pump(tester, AdStatus.none);
      expect(find.byKey(const Key('generating_title')), findsOneWidget);
      expect(find.byKey(const Key('ad_offer')), findsNothing);
      await pump(tester, AdStatus.watching);
      expect(find.byKey(const Key('ad_offer')), findsNothing);
    });

    testWidgets('offered: 보기/건너뛰기 콜백', (tester) async {
      var watched = 0;
      var skipped = 0;
      await pump(
        tester,
        AdStatus.offered,
        watch: () => watched++,
        skip: () => skipped++,
      );
      expect(find.text('기다리는 동안 광고를 보면 장면이 더 길어져요'), findsOneWidget);
      await tester.tap(find.byKey(const Key('watch_ad')));
      await tester.tap(find.byKey(const Key('skip_ad')));
      expect((watched, skipped), (1, 1));
    });

    testWidgets('rewarded: 보상 안내', (tester) async {
      await pump(tester, AdStatus.rewarded);
      expect(find.byKey(const Key('ad_rewarded')), findsOneWidget);
    });
  });

  group('ResultView', () {
    const result = EvaluationResult(
      channelId: 'wuxia',
      attemptIndex: 3,
      archetype: 1,
      title: '무당의 태극권사',
      manifestationForm: null,
      scenes: [
        Scene(
          kind: SceneKind.base,
          art: 'wuxia',
          place: '비무장',
          speaker: '검객',
          lines: ['첫 줄입니다', '둘째 줄'],
        ),
        Scene(
          kind: SceneKind.manifestation,
          art: 'manifestation',
          place: '어딘가',
          speaker: '목소리',
          lines: ['발현 줄'],
        ),
      ],
    );

    String dialogue(WidgetTester tester) =>
        tester.widget<Text>(find.byKey(const Key('dialogue_text'))).data!;

    testWidgets('타자기처럼 한 글자씩 보이고, 탭하면 줄을 끝까지, 다시 탭하면 다음 줄/장면', (tester) async {
      var shared = 0;
      await tester.pumpLocalized(
        ResultView(
          result: result,
          onShare: () => shared++,
          onAgain: () {},
          onHome: () {},
        ),
      );
      expect(find.text('평가 · 무당의 태극권사'), findsOneWidget);
      expect(find.text('검객'), findsOneWidget);
      expect(dialogue(tester), '');
      await tester.pump(const Duration(milliseconds: 36));
      expect(dialogue(tester), '첫');
      await tester.tap(find.byKey(const Key('result_tap_area')));
      await tester.pump();
      expect(dialogue(tester), '첫 줄입니다');
      expect(find.byKey(const Key('share_button')), findsNothing);

      await tester.tap(find.byKey(const Key('result_tap_area')));
      await tester.pumpAndSettle();
      expect(dialogue(tester), '둘째 줄');
      expect(find.textContaining('2/3'), findsOneWidget);

      await tester.tap(find.byKey(const Key('result_tap_area')));
      await tester.pumpAndSettle();
      expect(find.text('목소리'), findsOneWidget);
      expect(find.text('어딘가'), findsOneWidget);
      expect(dialogue(tester), '발현 줄');

      expect(find.byKey(const Key('share_button')), findsOneWidget);
      await tester.tap(find.byKey(const Key('share_button')));
      expect(shared, 1);
      // 마지막에서 더 탭해도 그대로
      await tester.tap(find.byKey(const Key('result_tap_area')));
      await tester.pumpAndSettle();
      expect(dialogue(tester), '발현 줄');
    });
  });

  group('FramePlan', () {
    test('줄마다 타자 5장 + 멈춤 1장, 최대 6줄', () {
      final scenes = [
        const Scene(
          kind: SceneKind.base,
          art: 'a',
          place: 'p',
          speaker: 's',
          lines: ['가나다라마바', '12345', 'x', 'y'],
        ),
        const Scene(
          kind: SceneKind.extension,
          art: 'a',
          place: 'p',
          speaker: 's',
          lines: ['z', 'w', 'v'],
        ),
      ];
      final plan = FramePlan.build(scenes);
      expect(plan, hasLength(6 * FramePlan.typingSteps));
      expect(plan.first, (
        scene: 0,
        line: 0,
        visibleChars: 1,
        durationMs: FramePlan.typingMs,
      ));
      expect(plan[5], (
        scene: 0,
        line: 0,
        visibleChars: 6,
        durationMs: FramePlan.holdMs,
      ));
      expect(plan.last.scene, 1);
      expect(plan.last.line, 1);
      final totalMs = plan.fold<int>(0, (n, f) => n + f.durationMs);
      expect(totalMs, 6 * (5 * 80 + 1400));
    });
  });
}
