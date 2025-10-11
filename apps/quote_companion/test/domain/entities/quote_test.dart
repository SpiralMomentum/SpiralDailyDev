import 'package:flutter_test/flutter_test.dart';
import 'package:quote_companion/src/domain/entities/quote.dart';

void main() {
  test('toMap and fromMap round trip', () {
    final quote = Quote(
      id: '1',
      text: 'Test quote',
      author: 'Tester',
      source: QuoteSourceType.custom,
      createdAt: DateTime.utc(2023, 1, 1),
    );

    final map = quote.toMap();
    final restored = Quote.fromMap(map);

    expect(restored.id, quote.id);
    expect(restored.text, quote.text);
    expect(restored.author, quote.author);
    expect(restored.source, quote.source);
  });
}
