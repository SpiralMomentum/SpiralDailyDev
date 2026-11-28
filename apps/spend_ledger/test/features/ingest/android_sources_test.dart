import 'package:flutter_test/flutter_test.dart';
import 'package:spend_ledger/features/ingest/domain/android_sources.dart';
import 'package:spend_ledger/features/message_filter/domain/raw_message.dart';

void main() {
  group('sourceForPackage', () {
    test('null is iOS shortcut', () {
      expect(sourceForPackage(null), MessageSource.iosShortcut);
    });
    test('sms apps are androidSms', () {
      expect(
        sourceForPackage('com.samsung.android.messaging'),
        MessageSource.androidSms,
      );
      expect(
        sourceForPackage('com.google.android.apps.messaging'),
        MessageSource.androidSms,
      );
    });
    test('other apps are androidApp', () {
      expect(
        sourceForPackage('com.kbcard.cxh.appcard'),
        MessageSource.androidApp,
      );
    });
    test('defaults match sms set', () {
      expect(defaultNotificationPackages.toSet(), smsPackages);
    });
  });

  group('notificationFingerprint', () {
    test('same input same value, 16 hex chars', () {
      final a = notificationFingerprint('p', 'text');
      expect(a, notificationFingerprint('p', 'text'));
      expect(a, matches(RegExp(r'^[0-9a-f]{16}$')));
    });
    test('package or text change differs', () {
      expect(
        notificationFingerprint('p1', 'text'),
        isNot(notificationFingerprint('p2', 'text')),
      );
      expect(
        notificationFingerprint('p', 'a'),
        isNot(notificationFingerprint('p', 'b')),
      );
    });
    test('known FNV-1a 64 vectors', () {
      expect(notificationFingerprint('', ''), 'af63c74c8601c8dd');
      expect(notificationFingerprint('p', '한'), '7dfe6a7c6787011f');
    });
  });
}
