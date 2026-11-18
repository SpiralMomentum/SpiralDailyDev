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
import 'package:self_eval_sim/features/simulation/domain/entities/accumulation.dart';
import 'package:self_eval_sim/features/simulation/domain/repositories/accumulation_repository.dart';
import 'package:self_eval_sim/features/simulation/domain/usecases/compose_result_use_case.dart';
import 'package:self_eval_sim/features/simulation/domain/usecases/load_content_use_case.dart';
import 'package:self_eval_sim/features/simulation/domain/usecases/plan_attempt_use_case.dart';
import 'package:self_eval_sim/features/simulation/domain/usecases/start_attempt_use_case.dart';

// 실제 온디바이스 모델로 시행을 연속 실행해 개별 결과와 누적 발현 결과를 모은다 (UI 없이 앱 유스케이스 직접 호출).
//   flutter drive --driver=test_driver/report_driver.dart \
//     --target=integration_test/simulation_report_test.dart \
//     --dart-define=MODEL_URL=http://10.0.2.2:8765/gemma-4-E2B-it.litertlm \
//     --dart-define=SIM_ATTEMPTS=30 -d <device>
// 결과: build/simulation/report.json (드라이버가 저장)
//
// 시행 조건:
// - 발현 규칙/재료 선택/발현 형태는 앱과 같은 코드가 시드 2026 난수로 돈다 (확률 조작 없음).
// - 사용자 선택은 별도 시드 7 난수로 고른다.
// - 언어: SIM_LANGS 순서대로 돌아가며 (기본 ko 만). 누적은 언어와 무관하게 하나로 쌓인다.
const _attempts = int.fromEnvironment('SIM_ATTEMPTS', defaultValue: 30);
const _langs = String.fromEnvironment('SIM_LANGS', defaultValue: 'ko');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('온디바이스 모델 시뮬레이션', timeout: const Timeout(Duration(hours: 3)), (tester) async {
    final docs = Directory(
      '${(await getTemporaryDirectory()).path}/sim_${DateTime.now().millisecondsSinceEpoch}',
    )..createSync(recursive: true);
    await bootstrap(AppConfig(random: Random(2026), documentsDirectory: () async => docs));
    if (!await sl<CheckModelPackUseCase>()()) {
      final events = await sl<DownloadModelPackUseCase>()().toList();
      expect(events.last, isA<DownloadCompleted>(), reason: '${events.last}');
    }
    final load = Stopwatch()..start();
    await sl<FlutterGemmaClient>().warmUp();
    final loadMs = load.elapsedMilliseconds;

    final pick = Random(7);
    final langs = _langs.split(',');
    final content = {for (final l in langs) l: (await sl<LoadContentUseCase>()(l)).dataOrNull!};
    final records = <Map<String, Object?>>[];
    for (var i = 0; i < _attempts; i++) {
      final lang = langs[i % langs.length];
      final c = content[lang]!;
      final channel = c.catalog.channels[pick.nextInt(c.catalog.channels.length)];
      final questions = sl<StartAttemptUseCase>()(channel, c.catalog.questionsPerAttempt);
      final answers = [
        for (final q in questions)
          Answer(questionId: q.id, choiceId: q.choices[pick.nextInt(q.choices.length)].id),
      ];
      final gaugeBefore = (await sl<AccumulationRepository>().load()).dataOrNull!.gaugePermille;
      final plan = (await sl<PlanAttemptUseCase>()(channel: channel, answers: answers)).dataOrNull!;
      final sw = Stopwatch()..start();
      final result = await sl<ComposeResultUseCase>()(channel: channel, plan: plan, text: c.text);
      final ms = sw.elapsedMilliseconds;
      records.add({
        'index': plan.attempt.index,
        'lang': lang,
        'channel': c.text.channelName(channel.id),
        'speaker': c.text.speaker(channel.id),
        'answers': [
          for (final a in answers)
            {'q': c.text.question(channel.id, a.questionId), 'c': c.text.choice(channel.id, a.questionId, a.choiceId)},
        ],
        'title': result.title,
        'gaugeBeforePermille': gaugeBefore,
        'manifested': plan.manifested,
        'form': plan.manifestation?.form.name,
        'materials': [
          for (final m in plan.manifestation?.materials ?? const <MaterialRef>[])
            {
              'kind': m.kind.name,
              'ago': plan.attempt.index - m.sourceIndex,
              'channel': c.text.channelName(m.channelId),
              'choice': c.text.choice(m.channelId, m.questionId, m.choiceId),
            },
        ],
        'baseSource': result.baseSource.name,
        'manifestationSource': result.manifestationSource?.name,
        'scenes': [
          for (final s in result.scenes)
            {'kind': s.kind.name, 'speaker': s.speaker, 'place': s.place, 'lines': s.lines},
        ],
        'composeMs': ms,
      });
      // ignore: avoid_print
      print('SIM ${plan.attempt.index} $lang ${channel.id} manifested=${plan.manifested} '
          'base=${result.baseSource.name} ms=$ms ${result.scenes.expand((s) => s.lines).join(' / ')}');
    }
    binding.reportData = {
      'model': 'gemma-4-E2B-it.litertlm (flutter_gemma 0.16.5, CPU)',
      'device': 'Android emulator API 34 arm64, 8GB RAM, 6 cores (M1 Pro host)',
      'attempts': _attempts,
      'langs': langs,
      'loadMs': loadMs,
      'records': records,
    };
    expect(records, hasLength(_attempts));
  });
}
