import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_components/ui_components.dart';

void main() {
  testWidgets('MapProviderPreview invokes callback when tapped', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapProviderPreview(
            title: 'Google Maps',
            description: 'Preview widget',
            accentColor: Colors.blue,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(MapProviderPreview));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });
}
