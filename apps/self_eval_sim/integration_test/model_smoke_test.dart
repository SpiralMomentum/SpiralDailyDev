import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:self_eval_sim/app/app_config.dart';
import 'package:self_eval_sim/app/bootstrap.dart';
import 'package:self_eval_sim/app/di/service_locator.dart';
import 'package:self_eval_sim/features/model_pack/domain/model_pack.dart';
import 'package:self_eval_sim/features/simulation/data/engine/flutter_gemma_client.dart';
import 'package:self_eval_sim/features/simulation/data/engine/llm_narration_engine.dart';
import 'package:self_eval_sim/features/simulation/domain/entities/accumulation.dart';
import 'package:self_eval_sim/features/simulation/domain/entities/evaluation.dart';
import 'package:self_eval_sim/features/simulation/domain/policies/personality_scorer.dart';
import 'package:self_eval_sim/features/simulation/domain/policies/result_composer.dart';
import 'package:self_eval_sim/features/simulation/domain/usecases/load_content_use_case.dart';

// 모델 스모크: 실제 다운로드 경로로 설치하고, 실제 프롬프트 한 개로 생성 시간을 잰다.
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/model_smoke_test.dart \
//     --dart-define=MODEL_URL=http://10.0.2.2:8765/gemma-4-E2B-it.litertlm -d <device>
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Gemma 4 E2B 설치 후 한국어 대사 생성', (tester) async {
    await bootstrap(AppConfig());
    final report = <String, Object>{};
    final sw = Stopwatch()..start();
    if (!await sl<CheckModelPackUseCase>()()) {
      final events = await sl<DownloadModelPackUseCase>()().toList();
      expect(events.last, isA<DownloadCompleted>(), reason: '${events.last}');
    }
    report['installMs'] = sw.elapsedMilliseconds;

    final client = sl<FlutterGemmaClient>();
    sw.reset();
    await client.warmUp();
    report['loadMs'] = sw.elapsedMilliseconds;

    final prompts = await rootBundle.loadString(
      'assets/narration/prompts.json',
    );
    expect(prompts, contains('ko'));
    const prompt =
        "너는 '골목 끝 작은 보석상'에 있는 '보석상 주인'이다. 방금 상대가 고른 답을 보고 상대를 평가한다.\n"
        "상대가 고른 답:\n- 곤란한 부탁을 받았다. → 하루 생각해 보고 답한다\n"
        "규칙:\n- 존댓말로, 상대에게 직접 하는 대사 2줄. 줄마다 줄바꿈. 한 줄 40자 이내.";
    final times = <int>[];
    final outputs = <String>[];
    for (var i = 0; i < 3; i++) {
      sw.reset();
      outputs.add(
        await client.generate(prompt, seed: Random(i).nextInt(1 << 30)),
      );
      times.add(sw.elapsedMilliseconds);
    }
    report['generateMs'] = times;
    report['outputs'] = outputs;

    // 실제 앱 프롬프트(128 토큰 초과, 프리필 1024 경로)로 결과 대사를 만든다. 짧은 프롬프트만으로는
    // maxTokens 와 프리필 길이 불일치를 잡지 못했으므로 반드시 함께 검사한다.
    final content = (await sl<LoadContentUseCase>()('ko')).dataOrNull!;
    final channel = content.catalog.channels.first;
    final engine = LlmNarrationEngine(
      client,
      () => rootBundle.loadString('assets/narration/prompts.json'),
    );
    final attempt = AttemptRecord(
      index: 1,
      channelId: channel.id,
      archetype: 0,
      at: DateTime(2026),
      theoryId: content.catalog.theories.first.id,
      answers: [
        for (final q in channel.questions.take(4))
          Answer(questionId: q.id, choiceId: q.choices.first.id),
      ],
    );
    final request = ResultComposer.baseRequest(
      channel,
      AttemptPlan(
        channelId: channel.id,
        attempt: attempt,
        manifestation: null,
        reading: PersonalityScorer.readAttempts(
          content.catalog,
          content.catalog.theories.first,
          [attempt],
        ),
      ),
      content.text,
      catalog: content.catalog,
    );
    sw.reset();
    final real = await engine.baseLines(request, Random(5));
    report['realPromptMs'] = sw.elapsedMilliseconds;
    report['realPrompt'] = real.isSuccess
        ? real.dataOrNull!.lines
        : 'FAILED ${real.failureOrNull?.cause}';
    // ignore: avoid_print
    print('MODEL_SMOKE $report');
    binding.reportData = report;
    expect(outputs.every((o) => o.trim().isNotEmpty), isTrue);
    expect(
      real.isSuccess || real.failureOrNull is NarrationRejected,
      isTrue,
      reason: '${real.failureOrNull?.cause}',
    );
  });
}
