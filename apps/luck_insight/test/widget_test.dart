// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:luck_insight/main.dart';

void main() {
  testWidgets('shows fortune selection prompt', (WidgetTester tester) async {
    await tester.pumpWidget(const LuckInsightApp());

    expect(find.text('아래 물음표 중 하나를 선택해 오늘의 행운 소재를 확인해보세요.'), findsOneWidget);
    expect(find.text('오늘의 운세'), findsOneWidget);
  });
}
