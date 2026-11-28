import 'dart:convert';

const int _fnvOffset = 0x811c9dc5;
const int _fnvPrime = 0x01000193;
const int _mask32 = 0xffffffff;

/// 키의 UTF-8 바이트에 대한 FNV-1a 32비트 해시를 양의 int32로 줄인 값.
/// isolate·실행·SDK가 달라도 같은 키는 같은 알림 id가 된다.
int notificationIdFor(String key) {
  var hash = _fnvOffset;
  for (final byte in utf8.encode(key)) {
    hash = ((hash ^ byte) * _fnvPrime) & _mask32;
  }
  return hash & 0x7fffffff;
}

/// 예산 알림 id. 종류마다 하나로 고정해 같은 종류는 덮어쓴다.
String budgetNotificationKey(String alertName) => 'budget:$alertName';
