import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:self_eval_sim/features/simulation/domain/entities/accumulation.dart';
import 'package:self_eval_sim/features/simulation/domain/entities/catalog.dart';
import 'package:self_eval_sim/features/simulation/domain/entities/evaluation.dart';
import 'package:self_eval_sim/features/simulation/domain/entities/quiz_question.dart';
import 'package:self_eval_sim/features/simulation/domain/story/story_world.dart';
import 'package:self_eval_sim/features/simulation/domain/repositories/narration_engine.dart';
import 'package:self_eval_sim/features/simulation/domain/usecases/compose_result_use_case.dart';
import 'package:self_eval_sim/features/simulation/domain/usecases/extend_result_use_case.dart';
import 'package:self_eval_sim/features/simulation/domain/usecases/plan_attempt_use_case.dart';
import 'package:self_eval_sim/features/simulation/domain/usecases/start_attempt_use_case.dart';
import 'package:self_eval_sim/features/simulation/presentation/attempt_page.dart';
import 'package:self_eval_sim/features/simulation/presentation/bloc/attempt_bloc.dart';
import 'package:self_eval_sim/features/simulation/presentation/flow/attempt_flow.dart';
import 'package:self_eval_sim/features/simulation/presentation/home_page.dart';
import 'package:utils/utils.dart';

import '../../../support/fixtures.dart';
import '../../../support/pump.dart';
import '../../../support/story_fixtures.dart';

/// 이름과 도입 문장만 가진 흐름. 어느 흐름으로 들어갔는지 화면으로 확인한다.
class _NamedFlow implements AttemptFlow {
  _NamedFlow(this.intro);

  final List<String> intro;

  @override
  String get art => 'wuxia';

  @override
  Future<Result<({List<String> intro, List<QuizQuestion> questions})>> start() async => Success((
        intro: intro,
        questions: const [
          QuizQuestion(id: 'q1', text: '흐름 질문', choices: [QuizChoice(id: 'c1', text: '흐름 선택')]),
        ],
      ));

  @override
  Future<Result<bool>> plan(List<String> choiceIds) async => const Success(false);

  @override
  Future<EvaluationResult> compose() => throw UnimplementedError();

  @override
  EvaluationResult extend(EvaluationResult result) => result;
}

class _Engine implements NarrationEngine {
  @override
  Future<Result<Narration>> baseLines(BaseNarrationRequest request, Random random) async =>
      Success(Narration(lines: request.fallbackLines, source: NarrationSource.template));

  @override
  Future<Result<ManifestationText>> manifestation(ManifestationRequest request, Random random) async =>
      const Success(ManifestationText(lines: ['기억 줄'], separateSpeaker: '목소리', separatePlace: '공허'));
}

void main() {
  final channel = testChannel(questions: 2);
  final content = LocalizedContent(
    catalog: ContentCatalog(channels: [channel, testChannel(id: 'gem')], questionsPerAttempt: 2),
    text: testText(),
  );

  group('HomePage', () {
    testWidgets('채널 카드를 언어 문장으로 보이고 탭/설정 콜백', (tester) async {
      Channel? opened;
      var settings = 0;
      await tester.pumpLocalized(
        HomePage(
          languageCode: 'ko',
          loadContent: (_) async => Success(content),
          onOpenChannel: (_, c, _) => opened = c,
          onOpenSettings: (_) => settings++,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('어디에서 평가받을까요?'), findsOneWidget);
      expect(find.text('wuxia-name'), findsOneWidget);
      expect(find.text('gem-tagline'), findsOneWidget);
      await tester.tap(find.byKey(const Key('channel_gem')));
      await tester.tap(find.byKey(const Key('settings_button')));
      expect(opened!.id, 'gem');
      expect(settings, 1);
    });

    testWidgets('콘텐츠 로드 실패 시 오류 문구', (tester) async {
      await tester.pumpLocalized(
        HomePage(
          languageCode: 'ko',
          loadContent: (_) async => const ErrorResult(ParsingFailure()),
          onOpenChannel: (_, _, _) {},
          onOpenSettings: (_) {},
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('home_error')), findsOneWidget);
    });
  });

  group('AttemptPage (실제 유스케이스 + 메모리 저장소)', () {
    Widget page(
      InMemoryAccumulationRepository repo, {
      required bool offer,
      List<bool>? adCalls,
      ContentReporter? reportContent,
    }) =>
        AttemptPage(
          createBloc: () => AttemptBloc(
            createFlow: () => ChannelFlow(
              channel,
              content,
              StartAttemptUseCase(Random(1)),
              PlanAttemptUseCase(repo, ScriptedRandom(bools: [false]), () => DateTime.utc(2026)),
              ComposeResultUseCase(_Engine(), Random(1)),
              const ExtendResultUseCase(),
            ),
            decideAdOffer: ({required manifested}) async => manifested && offer,
            showRewardedAd: () async {
              adCalls?.add(true);
              return const Success(true);
            },
          ),
          shareFrames: (_, _) async => true,
          reportContent: reportContent,
        );

    Future<void> answerAll(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('choice_0')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('choice_0')));
      // 발현 + 온라인이면 광고 제안, 아니면 결과 화면이 나온다.
      await tester.pumpUntil(
        find.byWidgetPredicate(
          (w) => w.key == const Key('ad_offer') || w.key == const Key('result_tap_area'),
        ),
      );
    }

    Future<void> tapThrough(WidgetTester tester) async {
      for (var i = 0; i < 12 && find.byKey(const Key('share_button')).evaluate().isEmpty; i++) {
        await tester.tap(find.byKey(const Key('result_tap_area')));
        await tester.pumpAndSettle();
      }
    }

    testWidgets('첫 시행: 문항 2개 -> 기본 결과, 기록 1건', (tester) async {
      final repo = InMemoryAccumulationRepository();
      await tester.pumpLocalized(page(repo, offer: true));
      await tester.pumpAndSettle();
      expect(find.text('1 / 2'), findsOneWidget);
      await answerAll(tester);
      expect(find.text('wuxia-speaker'), findsOneWidget);
      await tapThrough(tester);
      expect(find.byKey(const Key('again_button')), findsOneWidget);
      expect(repo.state.attempts, hasLength(1));
      expect(repo.state.manifestations, isEmpty);
    });

    testWidgets('신고: 메일 앱을 열지 못하면 본문을 복사하고 보낼 주소를 알린다', (tester) async {
      final reported = <EvaluationResult>[];
      final clipboard = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') clipboard.add((call.arguments as Map)['text'] as String);
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
      await tester.pumpLocalized(page(InMemoryAccumulationRepository(), offer: false, reportContent: (r) async {
        reported.add(r);
        return false;
      }));
      await tester.pumpAndSettle();
      await answerAll(tester);
      await tester.tap(find.byKey(const Key('report_button')));
      await tester.pumpAndSettle();
      expect(reported, hasLength(1));
      expect(clipboard.single, contains('wuxia-speaker'));
      expect(find.textContaining('spiraldailydev@gmail.com'), findsOneWidget);
    });

    testWidgets('천장 상태: 발현 -> 광고 제안 -> 시청 -> 별도 발현 장면 + 확장 장면', (tester) async {
      final repo = InMemoryAccumulationRepository(AccumulationState(attempts: [attempt(1)], gaugePermille: 1000));
      final adCalls = <bool>[];
      await tester.pumpLocalized(page(repo, offer: true, adCalls: adCalls));
      await tester.pumpAndSettle();
      await answerAll(tester);
      expect(find.byKey(const Key('ad_offer')), findsOneWidget);
      await tester.tap(find.byKey(const Key('watch_ad')));
      await tester.pumpUntil(find.byKey(const Key('result_tap_area')));
      expect(adCalls, [true]);
      await tapThrough(tester);
      // 마지막 장면은 확장 장면
      expect(find.text('wuxia-ext-place'), findsOneWidget);
      expect(repo.state.manifestations, hasLength(1));
      expect(repo.state.gaugePermille, 0);
    });

    testWidgets('한 번 더: 새 문항으로 다시 시작', (tester) async {
      final repo = InMemoryAccumulationRepository();
      await tester.pumpLocalized(page(repo, offer: false));
      await tester.pumpAndSettle();
      await answerAll(tester);
      await tapThrough(tester);
      await tester.tap(find.byKey(const Key('again_button')));
      await tester.pumpAndSettle();
      expect(find.text('1 / 2'), findsOneWidget);
      await answerAll(tester);
      await tapThrough(tester);
      expect(repo.state.attempts.map((a) => a.index), [1, 2]);
    });
  });

  testWidgets('이야기가 있는 채널은 이야기 흐름으로 들어간다', (tester) async {
    final storyContent = LocalizedContent(
      catalog: content.catalog,
      text: content.text,
      stories: {'wuxia': quizWorld},
    );
    final opened = <String>[];
    Widget open(Channel c) => AttemptPage(
          key: ValueKey(c.id),
          createBloc: () => AttemptBloc(
            createFlow: AttemptFlows.select(
              channel: c,
              content: storyContent,
              channelFlow: () {
                opened.add('channel:${c.id}');
                return _NamedFlow(const []);
              },
              storyFlow: (StoryWorld w, Channel _) {
                opened.add('story:${w.id}');
                return _NamedFlow(const ['이야기 도입']);
              },
            ),
            decideAdOffer: ({required manifested}) async => false,
            showRewardedAd: () async => const Success(false),
          ),
          shareFrames: (_, _) async => true,
        );

    await tester.pumpLocalized(open(channel));
    await tester.pumpAndSettle();
    expect(opened, ['story:${quizWorld.id}']);
    expect(find.byKey(const Key('quiz_intro')), findsOneWidget);
    expect(find.textContaining('이야기 도입'), findsOneWidget);
    expect(find.text('흐름 질문'), findsOneWidget);

    await tester.pumpLocalized(open(testChannel(id: 'gem')));
    await tester.pumpAndSettle();
    expect(opened.last, 'channel:gem');
    expect(find.byKey(const Key('quiz_intro')), findsNothing);
  });
}
