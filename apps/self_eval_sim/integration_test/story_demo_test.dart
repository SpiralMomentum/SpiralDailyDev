import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:self_eval_sim/app/app_config.dart';
import 'package:self_eval_sim/app/bootstrap.dart';
import 'package:self_eval_sim/features/monetization/domain/monetization.dart';
import 'package:self_eval_sim/features/share/data/share_impl.dart';

// 실제 무협 이야기 에셋으로 만남 3번을 보여 주는 시연용 통합 테스트 (영상 녹화용).
//   1. 객잔 주인 첫 만남
//   2. 객잔 주인 재회: 지난 답을 짚는 도입, 결과 첫 줄의 확신/의외 접두
//   3. 대장장이 첫 만남: 객잔 주인에게 들은 소문으로 시작
// 녹화: DEVICE=emulator-5554 TARGET=integration_test/story_demo_test.dart \
//   MODEL_URL=http://10.0.2.2:8765/gemma-4-E2B-it.litertlm tool/record_integration.sh

class _Online implements ConnectivityRepository {
  @override
  Future<bool> isOnline() async => true;
}

class _NoShare implements ShareSink {
  @override
  Future<void> shareFile(String path, {required String text}) async {}
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  Future<void> hold(WidgetTester tester, [int ms = 900]) async {
    await Future<void>.delayed(Duration(milliseconds: ms));
    await tester.pump();
  }

  Future<void> waitFor(
    WidgetTester tester,
    Finder finder, {
    int seconds = 60,
  }) async {
    final end = DateTime.now().add(Duration(seconds: seconds));
    while (finder.evaluate().isEmpty) {
      if (DateTime.now().isAfter(end)) {
        throw TestFailure('timeout waiting for $finder');
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await tester.pump();
    }
    await tester.pump();
  }

  Future<void> tapKey(WidgetTester tester, String key, {int holdMs = 700}) async {
    await tester.tap(find.byKey(Key(key)));
    await tester.pump();
    await hold(tester, holdMs);
  }

  String dialogue(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('dialogue_text'))).data!;

  /// 도입을 읽을 시간을 준 뒤 4문항에 답한다. 매 문항 질문 문장을 기록한다.
  Future<List<String>> play(WidgetTester tester, List<int> picks) async {
    final asked = <String>[];
    await waitFor(tester, find.byKey(const Key('question_text')));
    await hold(tester, 4500);
    for (final pick in picks) {
      asked.add(
        tester.widget<Text>(find.byKey(const Key('question_text'))).data!,
      );
      await hold(tester, 2200);
      await tapKey(tester, 'choice_$pick', holdMs: 400);
    }
    return asked;
  }

  /// 결과 대사를 끝까지 읽어 넘긴다.
  Future<List<String>> readThrough(WidgetTester tester) async {
    await waitFor(
      tester,
      find.byKey(const Key('result_tap_area')),
      seconds: 240,
    );
    final lines = <String>[];
    for (var i = 0; i < 30; i++) {
      await hold(tester, 1500);
      for (var settled = dialogue(tester), k = 0; k < 60; k++) {
        await hold(tester, 150);
        if (dialogue(tester) == settled) break;
        settled = dialogue(tester);
      }
      await hold(tester, 1200);
      if (lines.isEmpty || lines.last != dialogue(tester)) {
        lines.add(dialogue(tester));
      }
      if (find.byKey(const Key('share_button')).evaluate().isNotEmpty) break;
      await tester.tap(find.byKey(const Key('result_tap_area')));
      await tester.pump();
    }
    await hold(tester, 2500);
    return lines;
  }

  testWidgets('무협 이야기 시연: 첫 만남, 재회, 소문', (tester) async {
    final docs = Directory(
      '${(await getTemporaryDirectory()).path}/demo_${DateTime.now().millisecondsSinceEpoch}',
    )..createSync(recursive: true);
    File('${docs.path}/settings.json').writeAsStringSync('{"language":"ko"}');
    final app = await bootstrap(
      AppConfig(
        random: Random(2026),
        documentsDirectory: () async => docs,
        bundle: rootBundle,
        connectivity: _Online(),
        shareSink: _NoShare(),
        adDuration: const Duration(seconds: 3),
      ),
    );
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
    if (find.byKey(const Key('gate_title')).evaluate().isNotEmpty) {
      await tester.tap(find.byKey(const Key('gate_download')));
      await tester.pump();
      await waitFor(
        tester,
        find.byKey(const Key('channel_wuxia')),
        seconds: 1200,
      );
    }
    await waitFor(tester, find.byKey(const Key('channel_wuxia')));
    await hold(tester, 1500);

    final log = <String>[];
    await tapKey(tester, 'channel_wuxia');
    for (final picks in [
      [0, 0, 0, 0],
      [0, 0, 0, 0],
      [0, 1, 0, 2],
    ]) {
      final intro = find.byKey(const Key('quiz_intro'));
      await waitFor(tester, find.byKey(const Key('question_text')));
      log.add(
        intro.evaluate().isEmpty
            ? '(도입 없음)'
            : tester
                  .widgetList<Text>(
                    find.descendant(of: intro, matching: find.byType(Text)),
                  )
                  .map((t) => t.data ?? '')
                  .join(' / '),
      );
      log.addAll(await play(tester, picks));
      log.addAll(await readThrough(tester));
      log.add('---');
      if (log.where((l) => l == '---').length < 3) {
        await tapKey(tester, 'again_button', holdMs: 1200);
      }
    }
    binding.reportData = {'demo': log};
    for (final l in log) {
      debugPrint('DEMO $l');
    }
  });
}
