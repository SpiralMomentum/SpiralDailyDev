import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:login_widget/login_widget.dart';

void main() {
  testWidgets('LoginWidget calls onLogin with input values', (WidgetTester tester) async {
    String? username;
    String? password;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LoginWidget(
            onLogin: (u, p) {
              username = u;
              password = p;
            },
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField).at(0), 'user');
    await tester.enterText(find.byType(TextField).at(1), 'pass');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(username, 'user');
    expect(password, 'pass');
  });
}
