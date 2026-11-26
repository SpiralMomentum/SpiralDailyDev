import 'package:flutter_test/flutter_test.dart';
import 'package:life_balance/features/ongoing_notification/domain/midnight.dart';

void main() {
  test('23:59:30 -> 다음 자정 + 1분까지 1분 30초', () {
    expect(
      delayUntilNextRefresh(DateTime(2026, 11, 25, 23, 59, 30)),
      const Duration(minutes: 1, seconds: 30),
    );
  });

  test('정각 자정 -> 다음 날 자정 + 1분까지 24시간 1분', () {
    expect(
      delayUntilNextRefresh(DateTime(2026, 11, 25, 0, 0, 0)),
      const Duration(hours: 24, minutes: 1),
    );
  });

  test('00:00:30 -> 오늘 00:01이 아니라 다음 날 00:01', () {
    expect(
      delayUntilNextRefresh(DateTime(2026, 11, 25, 0, 0, 30)),
      const Duration(hours: 24, seconds: 30),
    );
  });

  test('월말/연말을 넘긴다', () {
    expect(
      delayUntilNextRefresh(DateTime(2026, 12, 31, 12)),
      const Duration(hours: 12, minutes: 1),
    );
  });

  test('항상 양수', () {
    for (var h = 0; h < 24; h++) {
      expect(delayUntilNextRefresh(DateTime(2026, 3, 8, h)) > Duration.zero,
          isTrue);
    }
  });
}
