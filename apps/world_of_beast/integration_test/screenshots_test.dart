import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:world_of_beast/app/di/service_locator.dart';
import 'package:world_of_beast/app/world_of_beasts_app.dart';

// 마케팅 스크린샷 생성용 통합 테스트 (내장 몬스터 데이터 사용, 즐겨찾기는 비운 상태에서 시작).
//   cd apps/world_of_beast
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/screenshots_test.dart -d <simulator udid>
// 결과: tools/marketing/assets/shots/world_of_beast/ko/<n>_<name>.png

/// 화면 캡처가 가능한 플랫폼 (integration_test 의 captureScreenshot 은 iOS/Android 만 구현).
final canCapture = !kIsWeb && (Platform.isIOS || Platform.isAndroid);

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// focus: 이 화면의 핵심 위젯들(합집합). 위치를 모아 테스트 끝에 reportData 로 보내면 드라이버가 사이드카 JSON 으로 남긴다.
  final focus = <String, Object>{};
  Future<void> shot(WidgetTester tester, String name, List<Finder> targets) async {
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
    Rect? r;
    for (final f in targets) {
      for (var i = 0; i < f.evaluate().length; i++) {
        final x = tester.getRect(f.at(i));
        r = r == null ? x : r.expandToInclude(x);
      }
    }
    if (r != null) {
      focus[name] = {'rect': [r.left, r.top, r.right, r.bottom], 'dpr': tester.view.devicePixelRatio};
    }
    // 캡처는 iOS/Android 기기에서만 (flutter drive). 그 밖(CI 리눅스, flutter-tester)에서는 흐름과 expect 만 검증한다.
    if (canCapture) {
      if (Platform.isAndroid) await binding.convertFlutterSurfaceToImage();
      await binding.takeScreenshot(name);
    }
  }

  testWidgets('마케팅 스크린샷', (WidgetTester tester) async {
    WidgetsApp.debugAllowBannerOverride = false;
    SharedPreferences.setMockInitialValues({});
    await ServiceLocator.setup();
    await tester.pumpWidget(const WorldOfBeastsApp());
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.byType(InkWell), findsWidgets, reason: '몬스터 목록이 비어 있음');
    await shot(tester, '0_list', [find.byType(InkWell).first]);

    // 첫 카드 상세 + 즐겨찾기
    await tester.tap(find.byType(InkWell).first);
    await tester.pumpAndSettle();
    expect(find.text('Country'), findsOneWidget);
    expect(find.text('Description'), findsOneWidget);
    await shot(tester, '1_details', [find.text('Country'), find.text('Description'), find.textContaining('비슈누')]);
    await tester.tap(find.byIcon(Icons.star_border).first);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.star), findsOneWidget, reason: '즐겨찾기 후 별이 채워지지 않음');
    await shot(tester, '2_details_favorite', [find.byIcon(Icons.star), find.text('가루다')]);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // 지도
    await tester.tap(find.byKey(const ValueKey('viewToggleButton')));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.byKey(const ValueKey('monsterMapView')), findsOneWidget);
    await shot(tester, '3_map', [find.byKey(const ValueKey('monsterMapView'))]);
    binding.reportData = {'focus': focus};
  });
}
