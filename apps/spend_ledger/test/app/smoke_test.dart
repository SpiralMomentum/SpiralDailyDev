import 'package:flutter_test/flutter_test.dart';
import 'package:spend_ledger/app/spend_ledger_app.dart';

void main() {
  testWidgets('renders app title', (tester) async {
    await tester.pumpWidget(const SpendLedgerApp());
    expect(find.text('지출 위젯'), findsOneWidget);
  });
}
