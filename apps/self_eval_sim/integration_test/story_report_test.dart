import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:self_eval_sim/app/app_config.dart';
import 'package:self_eval_sim/app/bootstrap.dart';
import 'package:self_eval_sim/app/di/service_locator.dart';
import 'package:self_eval_sim/features/model_pack/domain/model_pack.dart';
import 'package:self_eval_sim/features/simulation/data/engine/flutter_gemma_client.dart';
import 'package:self_eval_sim/features/simulation/domain/entities/catalog.dart';
import 'package:self_eval_sim/features/simulation/domain/entities/text_book.dart';
import 'package:self_eval_sim/features/simulation/domain/story/story_composer.dart';
import 'package:self_eval_sim/features/simulation/domain/story/story_judge.dart';
import 'package:self_eval_sim/features/simulation/domain/story/story_text.dart';
import 'package:self_eval_sim/features/simulation/domain/story/story_use_cases.dart';
import 'package:self_eval_sim/features/simulation/domain/story/story_world.dart';
import 'package:self_eval_sim/features/simulation/domain/usecases/load_content_use_case.dart';

// 무협 이야기 모드를 실제 온디바이스 모델로 연속 실행해 만남마다 결과를 모은다 (UI 없이 앱 유스케이스 직접 호출).
//   flutter drive --driver=test_driver/report_driver.dart \
//     --target=integration_test/story_report_test.dart \
//     --dart-define=MODEL_URL=http://10.0.2.2:8765/gemma-4-E2B-it.litertlm \
//     --dart-define=SIM_MEETINGS=36 -d <device>
// 결과: build/simulation/report.json (드라이버가 저장, SIM_REPORT 로 경로 변경). 집계: tool/sim_report.py
// `flutter test integration_test/story_report_test.dart -d <device>` 로도 돌지만 JSON 은 저장되지 않고 로그(STORY 줄)만 남는다.
//
// 실행 조건:
// - 인물/관계/틀/변주/발현은 앱과 같은 코드가 시드 2026 난수로 돈다.
// - 사용자: consistent (시드 2026). 태그 원천 이론마다 선호 극(양극 축은 축마다 하나, 단극 범주는 하나)을 정해 두고,
//   선호 극 수 - 같은 축 반대 극 수가 가장 큰 선택지를 고른다 (동점은 무작위).
//   정책 시뮬레이션(test/.../story_simulation_test.dart)의 consistent 사용자와 같은 규칙이다.
const _meetings = int.fromEnvironment('SIM_MEETINGS', defaultValue: 36);

Map<String, Set<String>> _preferences(StoryWorld world, Random random) => {
  for (final t in world.theories)
    t.id: t.axes.every((a) => a.length > 1)
        ? {for (final axis in t.axes) axis[random.nextInt(axis.length)]}
        : {
            () {
              final poles = [for (final a in t.axes) ...a];
              return poles[random.nextInt(poles.length)];
            }(),
          },
};

String _consistentChoice(
  Theory theory,
  Set<String> preferred,
  StoryFrame frame,
  Random random,
) {
  int score(FrameChoice c) {
    var s = 0;
    for (final p in StoryJudge.poles(theory, c)) {
      if (preferred.contains(p)) {
        s += 1;
      } else if (theory.axes.any(
        (a) => a.contains(p) && a.any(preferred.contains),
      )) {
        s -= 1;
      }
    }
    return s;
  }

  final best = frame.choices.map(score).reduce(max);
  final top = frame.choices.where((c) => score(c) == best).toList();
  return top[random.nextInt(top.length)].id;
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('무협 이야기 온디바이스 리포트', timeout: const Timeout(Duration(hours: 3)), (
    tester,
  ) async {
    final docs = Directory(
      '${(await getTemporaryDirectory()).path}/story_${DateTime.now().millisecondsSinceEpoch}',
    )..createSync(recursive: true);
    await bootstrap(
      AppConfig(random: Random(2026), documentsDirectory: () async => docs),
    );
    if (!await sl<CheckModelPackUseCase>()()) {
      final events = await sl<DownloadModelPackUseCase>()().toList();
      expect(events.last, isA<DownloadCompleted>(), reason: '${events.last}');
    }
    final load = Stopwatch()..start();
    await sl<FlutterGemmaClient>().warmUp();
    final loadMs = load.elapsedMilliseconds;

    final content = (await sl<LoadContentUseCase>()('ko')).dataOrNull!;
    final world = content.stories['wuxia']!;
    final TextBook text = content.text;
    final pick = Random(2026);
    final preferred = _preferences(world, pick);

    final records = <Map<String, Object?>>[];
    for (var i = 0; i < _meetings; i++) {
      final setup = (await sl<StartMeetingUseCase>()(world, text)).dataOrNull!;
      final theory = world.theoryById(setup.character.theoryId)!;
      final source = world.theoryById(theory.tagSource)!;
      final choiceIds = [
        for (final p in setup.frames)
          _consistentChoice(source, preferred[source.id]!, p.frame, pick),
      ];
      final questions = StoryComposer.questions(world, text, setup);
      final plan = (await sl<PlanMeetingUseCase>()(
        world: world,
        setup: setup,
        choiceIds: choiceIds,
      )).dataOrNull!;
      final request = StoryComposer.baseRequest(world, text, plan);
      final sw = Stopwatch()..start();
      final result = await sl<ComposeMeetingUseCase>()(
        world: world,
        text: text,
        plan: plan,
      );
      final ms = sw.elapsedMilliseconds;
      final c = setup.character;
      records.add({
        'index': setup.number,
        'character': c.id,
        'speaker': text.characterName(world.id, c.id),
        'theory': theory.id,
        'relationship': plan.meeting.relationship.name,
        'event': setup.event?.id,
        'intro': setup.intro,
        'answers': [
          for (final (j, p) in setup.frames.indexed)
            {
              'frame': p.frame.id,
              'q': questions[j].text,
              'recall': p.recallChoiceId == null
                  ? null
                  : text.frameRecall(
                      world.id,
                      p.frame.id,
                      p.recallChoiceId!,
                      p.variant,
                    ),
              'c': text.frameChoice(world.id, p.frame.id, choiceIds[j]),
              't': request.answers[j].$3,
            },
        ],
        'outcome': plan.judgment.outcome,
        'tone': plan.judgment.tone.name,
        'title': result.title,
        'context': request.context,
        'pastChoice': plan.pastAnswer == null
            ? null
            : text.frameChoice(
                world.id,
                plan.pastAnswer!.frameId,
                plan.pastAnswer!.choiceId,
              ),
        'rumorSource': plan.rumorSourceId,
        'manifested': plan.attemptPlan.manifestation != null,
        'form': plan.attemptPlan.manifestation?.form.name,
        'baseSource': result.baseSource.name,
        'manifestationSource': result.manifestationSource?.name,
        'scenes': [
          for (final s in result.scenes)
            {
              'kind': s.kind.name,
              'speaker': s.speaker,
              'place': s.place,
              'lines': s.lines,
            },
        ],
        'composeMs': ms,
      });
      // ignore: avoid_print
      print(
        'STORY ${setup.number} ${c.id} ${plan.meeting.relationship.name} '
        '${plan.judgment.outcome}/${plan.judgment.tone.name} '
        'base=${result.baseSource.name} ms=$ms '
        '${result.scenes.expand((s) => s.lines).join(' / ')}',
      );
    }
    binding.reportData = {
      'kind': 'story',
      'model': 'gemma-4-E2B-it.litertlm (flutter_gemma 0.16.5, CPU)',
      'device': 'Android emulator API 34 arm64, 8GB RAM, 6 cores (M1 Pro host)',
      'user': 'consistent (seed 2026)',
      'meetings': _meetings,
      'loadMs': loadMs,
      'avoid': text.storyAvoid(world.id),
      'records': records,
    };
    expect(records, hasLength(_meetings));
  });
}
