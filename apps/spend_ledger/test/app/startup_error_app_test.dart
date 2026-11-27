import 'package:flutter_test/flutter_test.dart';
import 'package:spend_ledger/app/startup_error_app.dart';
import 'package:spend_ledger/features/ledger/data/db_key.dart';

void main() {
  testWidgets('shows retry message and error type only', (tester) async {
    await tester.pumpWidget(
      const StartupErrorApp(error: DbKeyMissingException()),
    );

    expect(find.text('데이터를 열지 못했어요. 앱을 다시 실행해 주세요.'), findsOneWidget);
    expect(find.text('DbKeyMissingException'), findsOneWidget);
  });

  testWidgets('does not show the error message', (tester) async {
    await tester.pumpWidget(StartupErrorApp(error: StateError('secret 1234')));

    expect(find.text('StateError'), findsOneWidget);
    expect(find.textContaining('secret'), findsNothing);
  });
}
