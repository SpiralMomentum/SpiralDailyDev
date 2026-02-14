import 'package:flutter_test/flutter_test.dart';

import 'package:world_field_guide/app/world_field_guide_app.dart';

void main() {
  testWidgets('앱이 정상적으로 렌더링된다', (WidgetTester tester) async {
    await tester.pumpWidget(const WorldFieldGuideApp());

    // WorldMapWidget 내부에 caption 텍스트가 렌더링되는지 확인
    expect(find.text('전 세계 특산품을 한눈에 살펴보세요.'), findsOneWidget);
  });
}
