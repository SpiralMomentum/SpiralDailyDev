import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:self_eval_sim/app/app_config.dart';
import 'package:self_eval_sim/app/bootstrap.dart';
import 'package:self_eval_sim/features/monetization/domain/monetization.dart';
import 'package:self_eval_sim/features/share/data/share_impl.dart';

// 실제 앱 전체 흐름 통합 테스트 (온디바이스 Gemma 4 E2B 로 실제 생성). 영상 녹화와 함께 돌리려면:
//   cd apps/self_eval_sim && tool/record_integration.sh
// 단독 실행 (호스트에 모델 미러를 띄운 경우):
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/app_flow_test.dart \
//     --dart-define=MODEL_URL=http://10.0.2.2:8765/gemma-4-E2B-it.litertlm -d <device>
//
// 결정적 실행을 위해 바꾼 것 (앱 로직은 그대로):
// - 난수: nextInt 는 항상 0, nextBool 은 [separate, mixed] 순서. 발현 규칙(시작 0%, 증가, 초기화, 천장)은 실제 코드가 돈다.
//   nextInt=0 이면 확률 증가폭은 0.1%p 이고, 추첨값 0 은 확률이 0 보다 크기만 하면 발현한다.
//   그래서 1회차 미발현(0%) -> 2회차 발현 -> 3회차 미발현(초기화 0%) -> 4회차 발현 순서가 정해진다.
// - 저장 위치: 누적 기록/설정은 실행마다 새 임시 디렉터리. 모델 파일은 앱 저장소에 남으므로 두 번째 실행부터는 관문을 건너뛴다.
// - 연결 상태: 테스트가 온라인/오프라인을 바꾼다.
// - 언어: 앱 언어 설정 파일에 ko 를 미리 저장 (에뮬레이터 기기 언어가 영어여도 한국어로 시작).
// - 공유 시트: OS 공유 시트 대신 파일 경로를 기록하는 싱크 (GIF 파일은 실제로 만든다).

class _ScriptedRandom implements Random {
  _ScriptedRandom(this._bools);

  final List<bool> _bools;
  int _i = 0;

  @override
  int nextInt(int max) => 0;

  @override
  bool nextBool() => _bools[_i++ % _bools.length];

  @override
  double nextDouble() => 0;
}

class _SwitchableConnectivity implements ConnectivityRepository {
  bool online = true;

  @override
  Future<bool> isOnline() async => online;
}

class _RecordingShareSink implements ShareSink {
  final paths = <String>[];

  @override
  Future<void> shareFile(String path, {required String text}) async =>
      paths.add(path);
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // 기본 정책(fadePointers)은 테스트가 pump 할 때만 화면을 그려 타자 애니메이션 중간 프레임이 녹화되지 않는다.
  // 실제 앱처럼 엔진 프레임을 모두 그리게 한다.
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  /// 사람이 영상에서 볼 수 있게 실제 시간으로 멈춘다.
  Future<void> hold(WidgetTester tester, [int ms = 900]) async {
    await Future<void>.delayed(Duration(milliseconds: ms));
    await tester.pump();
  }

  Future<void> waitFor(
    WidgetTester tester,
    Finder finder, {
    int seconds = 30,
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

  Future<void> tapKey(
    WidgetTester tester,
    String key, {
    int holdMs = 700,
  }) async {
    await tester.tap(find.byKey(Key(key)));
    await tester.pump();
    await hold(tester, holdMs);
  }

  String dialogue(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('dialogue_text'))).data!;

  Future<void> answer(WidgetTester tester, List<int> picks) async {
    for (var i = 0; i < picks.length; i++) {
      expect(find.text('${i + 1} / ${picks.length}'), findsOneWidget);
      await hold(tester, 600);
      await tapKey(tester, 'choice_${picks[i]}', holdMs: 300);
    }
  }

  /// 결과 대사를 한 줄씩 넘기며 지나간 화자/장소/대사를 모은다.
  Future<
    ({
      Set<String> speakers,
      Set<String> places,
      List<String> lines,
    })
  >
  readThrough(WidgetTester tester) async {
    final speakers = <String>{};
    final places = <String>{};
    final lines = <String>[];
    for (var i = 0; i < 30; i++) {
      await hold(tester, 1300);
      // 긴 줄은 1.3초 안에 다 타자되지 않는다. 글자가 더 늘지 않을 때까지 기다린 뒤 읽는다.
      for (var settled = dialogue(tester), k = 0; k < 40; k++) {
        await hold(tester, 150);
        if (dialogue(tester) == settled) break;
        settled = dialogue(tester);
      }
      speakers.add(
        tester.widget<Text>(find.byKey(const Key('speaker_name'))).data!,
      );
      places.add(
        tester
            .widget<Text>(
              find.descendant(
                of: find.byKey(const Key('scene_place')),
                matching: find.byType(Text),
              ),
            )
            .data!,
      );
      if (lines.isEmpty || lines.last != dialogue(tester)) {
        lines.add(dialogue(tester));
      }
      if (find.byKey(const Key('share_button')).evaluate().isNotEmpty) break;
      await tester.tap(find.byKey(const Key('result_tap_area')));
      await tester.pump();
    }
    expect(find.byKey(const Key('share_button')), findsOneWidget);
    // 성격 이론/유형 이름은 사용자에게 보이지 않는다.
    final theoryNames = RegExp(
      r'빅파이브|에니어그램|MBTI|16유형|4기질|[EI][SN][TF][JP]|(개방|성실|외향|우호|신경)성|(다혈|담즙|우울|점액)질',
    );
    expect(lines.where(theoryNames.hasMatch), isEmpty, reason: '$lines');
    return (speakers: speakers, places: places, lines: lines);
  }

  testWidgets('최초 실행부터 누적 발현, 광고 보상, 공유, 설정까지', (tester) async {
    final docs = Directory(
      '${(await getTemporaryDirectory()).path}/flow_${DateTime.now().millisecondsSinceEpoch}',
    )..createSync(recursive: true);
    // 기기 언어와 무관하게 한국어로 시작한다 (앱의 언어 설정 저장 형식을 그대로 사용).
    File('${docs.path}/settings.json').writeAsStringSync('{"language":"ko"}');
    final connectivity = _SwitchableConnectivity();
    final shareSink = _RecordingShareSink();
    final app = await bootstrap(
      AppConfig(
        random: _ScriptedRandom([false, true]),
        documentsDirectory: () async => docs,
        connectivity: connectivity,
        shareSink: shareSink,
        adDuration: const Duration(seconds: 3),
      ),
    );
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    // 1. 최초 실행: 모델(2.4GB)을 내려받기 전에는 사용 불가
    if (find.byKey(const Key('gate_title')).evaluate().isNotEmpty) {
      expect(find.byKey(const Key('channel_wuxia')), findsNothing);
      await hold(tester, 2500); // 녹화 시작 여유
      await tester.tap(find.byKey(const Key('gate_download')));
      await tester.pump();
      await waitFor(tester, find.byKey(const Key('gate_progress')));
      await waitFor(
        tester,
        find.byKey(const Key('channel_wuxia')),
        seconds: 1200,
      );
    }
    await waitFor(tester, find.byKey(const Key('channel_wuxia')));
    await hold(tester, 1500);

    // 2. 1회차 무협: 확률 0% 이므로 개별 시행 결과
    await tapKey(tester, 'channel_wuxia');
    await answer(tester, [0, 1, 0, 2]);
    await waitFor(
      tester,
      find.byKey(const Key('result_tap_area')),
      seconds: 240,
    );
    expect(find.byKey(const Key('ad_offer')), findsNothing);
    final first = await readThrough(tester);
    expect(first.speakers, {'백발의 검객'});
    // 첫 줄은 결과 유형을 밝히는 문장, 이어서 성격 설명 3~4줄, 끝 줄은 명언.
    expect(
      first.lines.first,
      allOf(startsWith('너는 '), endsWith(' 같은 사람이다.')),
    );
    expect(first.lines.length, inInclusiveRange(5, 6));

    // 공유: 미연시 장면 GIF 생성
    await tapKey(tester, 'share_button', holdMs: 300);
    await waitFor(tester, find.byKey(const Key('share_making')));
    await waitFor(tester, find.byKey(const Key('share_button')), seconds: 60);
    for (var i = 0; i < 300 && shareSink.paths.isEmpty; i++) {
      await hold(tester, 100);
    }
    final gif = File(shareSink.paths.single);
    expect(String.fromCharCodes(gif.readAsBytesSync().sublist(0, 6)), 'GIF89a');
    expect(gif.lengthSync(), greaterThan(10 * 1024));
    await hold(tester, 1200);

    // 3. 2회차 무협(한 번 더): 누적 발현 + 온라인 -> 보상형 광고 제안 -> 시청 -> 확장 장면
    await tapKey(tester, 'again_button');
    await answer(tester, [2, 2, 1, 0]);
    await waitFor(tester, find.byKey(const Key('ad_offer')));
    await hold(tester, 1500);
    await tapKey(tester, 'watch_ad', holdMs: 300);
    await waitFor(tester, find.byKey(const Key('ad_countdown')));
    await waitFor(
      tester,
      find.byKey(const Key('result_tap_area')),
      seconds: 240,
    );
    final second = await readThrough(tester);
    expect(
      second.speakers,
      containsAll(['백발의 검객', '낯선 목소리']),
    ); // separate 형태: 별도 장면
    expect(second.places, contains('산 아래, 너를 지켜보던 사람들')); // 광고 보상 추가 장면
    expect(
      second.lines.length,
      greaterThanOrEqualTo(5 + 2 + 2),
    ); // 기본 5~6 + 발현 2~3 + 확장 2
    await hold(tester, 1200);

    // 4. 3회차 보석: 발현 직후라 확률 0% -> 광고 제안 없음
    await tapKey(tester, 'home_button');
    await tapKey(tester, 'channel_gem');
    await answer(tester, [1, 0, 2, 1]);
    await waitFor(
      tester,
      find.byKey(const Key('result_tap_area')),
      seconds: 240,
    );
    expect(find.byKey(const Key('ad_offer')), findsNothing);
    final third = await readThrough(tester);
    expect(third.speakers, {'보석상 주인'});
    expect(
      third.lines.first,
      allOf(startsWith('당신은 '), endsWith('처럼 보이네요.')),
    );
    expect(third.lines.length, inInclusiveRange(5, 6));

    // 5. 4회차 동물, 오프라인: 발현은 일어나지만 광고는 없다 (mixed 형태: 같은 장면에 섞임)
    connectivity.online = false;
    await tapKey(tester, 'home_button');
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    await tapKey(tester, 'channel_animal');
    await answer(tester, [0, 0, 1, 2]);
    await waitFor(
      tester,
      find.byKey(const Key('result_tap_area')),
      seconds: 240,
    );
    expect(find.byKey(const Key('ad_offer')), findsNothing);
    final fourth = await readThrough(tester);
    expect(fourth.speakers, {'숲의 늙은 올빼미'});
    expect(fourth.lines.length, greaterThan(5));
    expect(fourth.places, isNot(contains('새벽 안개 낀 호숫가')));

    // 6. 설정: 누적 기록, 언어 변경, 전체 삭제
    await tapKey(tester, 'home_button');
    await tapKey(tester, 'settings_button');
    expect(find.text('시행 4회 · 발현 2회'), findsOneWidget);
    await hold(tester, 1200);
    await tapKey(tester, 'language_en', holdMs: 1200);
    expect(find.text('Settings'), findsOneWidget);
    await tester.tap(find.byKey(const Key('delete_all')));
    await tester.pumpAndSettle();
    await hold(tester, 900);
    await tapKey(tester, 'confirm_delete', holdMs: 1500);
    expect(find.text('Tries: 0 · Manifested: 0'), findsOneWidget);
    expect(File('${docs.path}/accumulation.json').existsSync(), isFalse);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await hold(tester, 1500);
    expect(find.text('Where do you want to be evaluated?'), findsOneWidget);
    expect(find.text('Wuxia'), findsOneWidget);
  });
}
