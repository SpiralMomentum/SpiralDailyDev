import 'package:apps.news_reader/core/widgets/adaptive_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdaptiveLayout', () {
    testWidgets('shows compact body on narrow screen', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: AdaptiveLayout(
            compactBody: Text('Compact'),
            expandedBody: Text('Expanded'),
          ),
        ),
      );

      expect(find.text('Compact'), findsOneWidget);
      expect(find.text('Expanded'), findsNothing);
    });

    testWidgets('shows expanded body on wide screen', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: AdaptiveLayout(
            compactBody: Text('Compact'),
            expandedBody: Text('Expanded'),
          ),
        ),
      );

      expect(find.text('Expanded'), findsOneWidget);
      expect(find.text('Compact'), findsNothing);
    });

    testWidgets('shows compact when no expanded body provided', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: AdaptiveLayout(
            compactBody: Text('Compact'),
          ),
        ),
      );

      expect(find.text('Compact'), findsOneWidget);
    });
  });
}
