import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final banned = File('test/features/tone/banned_words.txt')
      .readAsLinesSync()
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty && !l.startsWith('#'))
      .toList();

  test('금지어 목록이 비어 있지 않다', () {
    expect(banned.length, greaterThanOrEqualTo(30));
  });

  for (final tone in ['community', 'wit', 'stoic']) {
    test('$tone.json에 금지어 없음', () {
      final text = File('assets/tones/$tone.json').readAsStringSync();
      final hits = banned.where(text.contains).toList();
      expect(hits, isEmpty);
    });
  }
}
