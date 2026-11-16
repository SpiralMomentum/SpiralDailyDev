import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:luck_insight/app/di/service_locator.dart';
import 'package:luck_insight/app/luck_insight_app.dart';

// 마케팅 스크린샷 생성용 통합 테스트.
//   cd apps/luck_insight
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/screenshots_test.dart -d <simulator udid>
// 결과: tools/marketing/assets/shots/luck_insight/ko/<n>_<name>.png
// 주의: 운세 결과는 앱이 현재 시각으로 무작위 추첨하므로 실행마다 결과 화면 문구가 달라진다.

/// 화면 캡처가 가능한 플랫폼 (integration_test 의 captureScreenshot 은 iOS/Android 만 구현).
final canCapture = !kIsWeb && (Platform.isIOS || Platform.isAndroid);

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// focus: 이 화면의 핵심 위젯. 위치를 모아 테스트 끝에 reportData 로 보내면 드라이버가 사이드카 JSON 으로 남긴다.
  final focus = <String, Object>{};
  Future<void> shot(WidgetTester tester, String name, Finder target) async {
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
    final r = tester.getRect(target);
    focus[name] = {'rect': [r.left, r.top, r.right, r.bottom], 'dpr': tester.view.devicePixelRatio};
    // 캡처는 iOS/Android 기기에서만 (flutter drive). 그 밖(CI 리눅스, flutter-tester)에서는 흐름과 expect 만 검증한다.
    if (canCapture) {
      if (Platform.isAndroid) await binding.convertFlutterSurfaceToImage();
      await binding.takeScreenshot(name);
    }
  }

  testWidgets('마케팅 스크린샷', (WidgetTester tester) async {
    WidgetsApp.debugAllowBannerOverride = false;
    await ServiceLocator.setup();
    await tester.pumpWidget(const LuckInsightApp());
    await tester.pumpAndSettle();
    expect(find.text('?'), findsNWidgets(4), reason: '물음표 4개');
    await shot(tester, '0_pick', find.byType(Wrap));

    // 1. 첫 결과
    await tester.tap(find.text('?').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('상위'), findsOneWidget, reason: '결과에 상위 % 표시');
    expect(find.text('다시하기'), findsOneWidget);
    expect(find.text('?'), findsNothing, reason: '결과 후 물음표는 숨겨짐');
    await shot(tester, '1_result', find.textContaining('상위'));

    // 2. 1등 기록 (앱 메모리 기록이라 새로 켜면 비어 있다. 1등 확률 0.2%)
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('아직 1등 기록이 없어요'), findsOneWidget);
    await shot(tester, '2_history', find.byType(BottomSheet));
    binding.reportData = {'focus': focus};
  });
}
