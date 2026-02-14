import 'package:flutter_test/flutter_test.dart';

import 'package:adage_spark/app/adage_spark_app.dart';

void main() {
  testWidgets('AdageSparkApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AdageSparkApp());
    await tester.pumpAndSettle();

    // 앱이 정상적으로 렌더링되는지 확인
    expect(find.byType(AdageSparkApp), findsOneWidget);
  });
}
