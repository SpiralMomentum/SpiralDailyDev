import 'package:flutter_test/flutter_test.dart';
import 'package:life_balance/features/balance/domain/calendar_date.dart';
import 'package:life_balance/features/tone/domain/phrase_keys.dart';
import 'package:life_balance/features/tone/domain/tone.dart';
import 'package:life_balance/features/tone/domain/tone_table.dart';
import 'package:utils/utils.dart';

void main() {
  const table = ToneTable(
    id: ToneId.stoic,
    phrases: {
      'k': ['a', 'b', 'c'],
      'one': ['only'],
    },
  );

  group('pickPhrase', () {
    test('같은 날은 같은 문장', () {
      final d = const CalendarDate(2026, 11, 25);
      expect(pickPhrase(table, 'k', d), pickPhrase(table, 'k', d));
    });

    test('다음 날은 다음 변형', () {
      final d = const CalendarDate(2026, 11, 25);
      final i = d.epochDay % 3;
      expect(pickPhrase(table, 'k', d), ['a', 'b', 'c'][i]);
      expect(
        pickPhrase(table, 'k', d.addDays(1)),
        ['a', 'b', 'c'][(i + 1) % 3],
      );
    });

    test('변형 1개면 항상 그 문장', () {
      expect(pickPhrase(table, 'one', const CalendarDate(2000, 1, 1)), 'only');
      expect(pickPhrase(table, 'one', const CalendarDate(2031, 7, 9)), 'only');
    });

    test('1970년 이전 날짜(음수 epochDay)도 범위 안', () {
      final v = pickPhrase(table, 'k', const CalendarDate(1950, 3, 2));
      expect(['a', 'b', 'c'], contains(v));
    });

    test('없는 키는 키 자체를 돌려준다', () {
      expect(
        pickPhrase(table, 'missing', const CalendarDate(2026, 1, 1)),
        'missing',
      );
    });
  });

  group('fillPlaceholders', () {
    test('balance 치환', () {
      expect(
        fillPlaceholders('인생잔고 {balance} · 오늘 -1일', {'balance': '12,345일'}),
        '인생잔고 12,345일 · 오늘 -1일',
      );
    });

    test('bonus 치환, 없는 변수는 그대로', () {
      expect(
        fillPlaceholders('{bonus} / {balance} / {unknown}', {'bonus': '+400일'}),
        '+400일 / {balance} / {unknown}',
      );
    });
  });

  group('parseToneTable', () {
    test('정상 JSON', () {
      final r = parseToneTable(ToneId.wit, '{"a": ["x", "y"], "b": ["z"]}');
      expect(r.isSuccess, isTrue);
      expect(
        r.dataOrNull,
        const ToneTable(
          id: ToneId.wit,
          phrases: {
            'a': ['x', 'y'],
            'b': ['z'],
          },
        ),
      );
    });

    test('깨진 JSON은 ParsingFailure', () {
      final r = parseToneTable(ToneId.wit, '{not json');
      expect(r.failureOrNull, isA<ParsingFailure>());
    });

    test('최상위가 객체가 아니면 ParsingFailure', () {
      expect(
        parseToneTable(ToneId.wit, '["a"]').failureOrNull,
        isA<ParsingFailure>(),
      );
    });

    test('값이 문자열 배열이 아니면 ParsingFailure', () {
      expect(
        parseToneTable(ToneId.wit, '{"a": "x"}').failureOrNull,
        isA<ParsingFailure>(),
      );
      expect(
        parseToneTable(ToneId.wit, '{"a": [1]}').failureOrNull,
        isA<ParsingFailure>(),
      );
    });

    test('빈 배열은 ParsingFailure', () {
      expect(
        parseToneTable(ToneId.wit, '{"a": []}').failureOrNull,
        isA<ParsingFailure>(),
      );
    });
  });

  test('PhraseKeys.all은 16개 키, 중복 없음', () {
    expect(PhraseKeys.all.length, 16);
    expect(PhraseKeys.all.toSet().length, 16);
    expect(PhraseKeys.notificationBody, 'notification.body');
  });
}
