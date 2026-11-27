import 'package:flutter_test/flutter_test.dart';
import 'package:spend_ledger/features/budget/domain/period.dart';

void main() {
  test('period start day 25', () {
    final p = periodFor(DateTime(2026, 11, 27), 25);
    expect(p.start, DateTime(2026, 11, 25));
    expect(p.endExclusive, DateTime(2026, 12, 25));
    expect(p.totalDays, 30);
    expect(p.key, '2026-11-25');
  });

  test('period before start day', () {
    final p = periodFor(DateTime(2026, 11, 10), 25);
    expect(p.start, DateTime(2026, 10, 25));
    expect(p.endExclusive, DateTime(2026, 11, 25));
  });

  test('start day 31 in february', () {
    final p = periodFor(DateTime(2027, 2, 15), 31);
    expect(p.start, DateTime(2027, 1, 31));
    expect(p.endExclusive, DateTime(2027, 2, 28));
    expect(p.totalDays, 28);
  });

  test('start day 31 clamps next period start too', () {
    final p = periodFor(DateTime(2027, 2, 28), 31);
    expect(p.start, DateTime(2027, 2, 28));
    expect(p.endExclusive, DateTime(2027, 3, 31));
  });

  test('year boundary', () {
    final p = periodFor(DateTime(2026, 12, 31), 1);
    expect(p.start, DateTime(2026, 12, 1));
    expect(p.endExclusive, DateTime(2027, 1, 1));
  });

  test('january before start day', () {
    final p = periodFor(DateTime(2027, 1, 10), 25);
    expect(p.start, DateTime(2026, 12, 25));
    expect(p.endExclusive, DateTime(2027, 1, 25));
    expect(p.totalDays, 31);
  });

  test('december after start day', () {
    final p = periodFor(DateTime(2026, 12, 28), 25);
    expect(p.start, DateTime(2026, 12, 25));
    expect(p.endExclusive, DateTime(2027, 1, 25));
  });
}
