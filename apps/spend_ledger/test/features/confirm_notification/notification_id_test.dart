import 'package:flutter_test/flutter_test.dart';
import 'package:spend_ledger/features/confirm_notification/domain/notification_id.dart';

void main() {
  test('FNV-1a 32-bit ids are pinned', () {
    expect(notificationIdFor(''), 18652613);
    expect(notificationIdFor('a'), 1678518572);
    expect(notificationIdFor('tx1'), 1614153424);
    expect(notificationIdFor('스타벅스'), 727488697);
  });

  test('budget ids are fixed per alert', () {
    expect(budgetNotificationKey('actualOver'), 'budget:actualOver');
    expect(notificationIdFor('budget:actualOver'), 1170549754);
    expect(notificationIdFor('budget:projectedOver'), 31028444);
  });

  test('ids are non-negative int32', () {
    for (final key in ['x', 'tx-123', '2026-11-27T20:00:00.000']) {
      final id = notificationIdFor(key);
      expect(id, inInclusiveRange(0, 0x7fffffff));
    }
  });
}
