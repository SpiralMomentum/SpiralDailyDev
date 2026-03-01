import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:apps.news_reader/core/sdui/sdui_renderer.dart';

void main() {
  group('SduiRenderer', () {
    Widget _wrapInApp(Widget child) {
      return MaterialApp(home: Scaffold(body: child));
    }

    testWidgets('article_card - title, summary, image placeholder 렌더링',
        (tester) async {
      final spec = <String, dynamic>{'widget_type': 'article_card'};
      final data = <String, dynamic>{
        'title': 'Breaking News',
        'summary': 'This is a test summary for the article.',
      };

      await tester.pumpWidget(
        _wrapInApp(SingleChildScrollView(
          child: SduiRenderer.render(spec, data: data),
        )),
      );

      // title이 렌더링되었는지 확인
      expect(find.text('Breaking News'), findsOneWidget);
      // summary가 렌더링되었는지 확인
      expect(
        find.text('This is a test summary for the article.'),
        findsOneWidget,
      );
      // Card 위젯이 있는지 확인
      expect(find.byType(Card), findsOneWidget);
      // 이미지 placeholder 아이콘이 있는지 확인 (image_url 미제공)
      expect(find.byIcon(Icons.image), findsOneWidget);
    });

    testWidgets('banner_card - color, text 렌더링', (tester) async {
      final spec = <String, dynamic>{
        'widget_type': 'banner_card',
        'text': 'Special Offer',
        'color': '#FF5722',
        'height': 100,
      };

      await tester.pumpWidget(
        _wrapInApp(SduiRenderer.render(spec)),
      );

      expect(find.text('Special Offer'), findsOneWidget);

      // Container가 지정 높이로 렌더링되었는지 확인
      final container = tester.widget<Container>(find.byType(Container).last);
      final constraints = container.constraints;
      expect(container.constraints == null || constraints!.minHeight <= 100,
          isTrue);
    });

    testWidgets('category_header - label, style 렌더링', (tester) async {
      final spec = <String, dynamic>{
        'widget_type': 'category_header',
        'label': 'Technology',
        'font_size': 24,
        'color': '#1565C0',
      };

      await tester.pumpWidget(
        _wrapInApp(SduiRenderer.render(spec)),
      );

      expect(find.text('Technology'), findsOneWidget);

      final textWidget = tester.widget<Text>(find.text('Technology'));
      expect(textWidget.style?.fontSize, 24);
      expect(textWidget.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('spacer - 지정 높이의 SizedBox 렌더링', (tester) async {
      final spec = <String, dynamic>{
        'widget_type': 'spacer',
        'height': 32,
      };

      await tester.pumpWidget(
        _wrapInApp(SduiRenderer.render(spec)),
      );

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.height, 32);
    });

    testWidgets('unknown type - SizedBox.shrink 렌더링', (tester) async {
      final spec = <String, dynamic>{
        'widget_type': 'unknown_widget',
      };

      await tester.pumpWidget(
        _wrapInApp(SduiRenderer.render(spec)),
      );

      // SizedBox.shrink은 width=0, height=0
      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.width, 0);
      expect(sizedBox.height, 0);
    });
  });
}
