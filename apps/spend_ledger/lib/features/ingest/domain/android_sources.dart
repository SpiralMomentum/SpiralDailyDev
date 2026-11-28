import 'dart:convert';

import '../../message_filter/domain/raw_message.dart';

/// 처음 허용하는 알림 앱. 문자 앱 두 개.
const List<String> defaultNotificationPackages = [
  'com.samsung.android.messaging',
  'com.google.android.apps.messaging',
];

/// 문자 앱 패키지. 나머지 허용 앱은 카드·은행 앱으로 본다.
const Set<String> smsPackages = {
  'com.samsung.android.messaging',
  'com.google.android.apps.messaging',
};

/// 알림을 올린 패키지로 수집 경로를 정한다. 패키지가 없으면 iOS 단축어다.
MessageSource sourceForPackage(String? package) {
  if (package == null) return MessageSource.iosShortcut;
  return smsPackages.contains(package)
      ? MessageSource.androidSms
      : MessageSource.androidApp;
}

const int _fnvOffset64 = 0xcbf29ce484222325;
const int _fnvPrime64 = 0x100000001b3;

/// `'$package\n$text'`의 UTF-8 바이트에 대한 FNV-1a 64비트 해시를 16자리 16진수로.
/// Dart VM의 int는 64비트 부호 있는 값이라 곱셈은 감기고, `toUnsigned(64)`도 값을
/// 바꾸지 않아 음수로 찍힌다. 그래서 상·하위 32비트를 따로 16진수로 낸다.
String notificationFingerprint(String package, String text) {
  var hash = _fnvOffset64;
  for (final byte in utf8.encode('$package\n$text')) {
    hash = (hash ^ byte) * _fnvPrime64;
  }
  String half(int v) => (v & 0xffffffff).toRadixString(16).padLeft(8, '0');
  return half(hash >> 32) + half(hash);
}
