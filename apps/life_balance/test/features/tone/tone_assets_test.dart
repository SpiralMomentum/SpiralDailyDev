import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_balance/features/tone/data/asset_tone_repository.dart';
import 'package:life_balance/features/tone/domain/phrase_keys.dart';
import 'package:life_balance/features/tone/domain/tone.dart';
import 'package:life_balance/features/tone/domain/tone_table.dart';

// 분석기는 unicode 속성 이스케이프를 모른다. 실제 동작은 아래 첫 테스트로 검증.
// ignore: valid_regexps
final _emoji = RegExp(r'\p{Extended_Pictographic}', unicode: true);

ToneTable _load(ToneId id) {
  final json = File('assets/tones/${id.name}.json').readAsStringSync();
  return parseToneTable(id, json).dataOrNull!;
}

void main() {
  test('이모지 정규식이 실제로 이모지를 잡는다', () {
    expect(_emoji.hasMatch('잔고 \u{1F480}'), isTrue);
    expect(_emoji.hasMatch('인생잔고 12,345일 · 오늘 -1일'), isFalse);
  });

  test('문구 교정: 커뮤니티 중형 라벨은 현황, 스토아 카이로스는 결정적 순간', () {
    final community = _load(ToneId.community);
    expect(community.phrases['widget.medium_label'],
        isNot(contains('인생 잔고 실황')));
    expect(community.phrases['widget.medium_label'], contains('인생 잔고 현황'));
    final stoic = _load(ToneId.stoic).phrases['kairos.intro']!.join();
    // 카이로스는 "붙잡는 시간"이 아니라 행동하기에 꼭 맞는 결정적 순간을 뜻한다.
    expect(stoic, isNot(contains('붙잡는 시간')));
    expect(stoic, contains('결정적 순간'));
  });

  for (final id in ToneId.values) {
    group('${id.name}.json', () {
      late ToneTable t;
      setUpAll(() => t = _load(id));

      test('PhraseKeys.all 키를 모두 보유하고 모르는 키가 없다', () {
        expect(t.phrases.keys.toSet(), PhraseKeys.all.toSet());
      });

      test('키마다 변형 1~5개, 빈 문자열 없음', () {
        for (final e in t.phrases.entries) {
          expect(e.value.length, inInclusiveRange(1, 5), reason: e.key);
          for (final s in e.value) {
            expect(s.trim(), isNotEmpty, reason: e.key);
          }
        }
      });

      test('이모지 없음', () {
        for (final e in t.phrases.entries) {
          for (final s in e.value) {
            expect(_emoji.hasMatch(s), isFalse, reason: '${e.key}: $s');
          }
        }
      });

      test('notification.body는 모두 {balance} 포함', () {
        for (final s in t.phrases[PhraseKeys.notificationBody]!) {
          expect(s, contains('{balance}'));
        }
      });

      test('보너스 문구는 모두 {bonus} 포함', () {
        for (final s in t.phrases[PhraseKeys.notificationBonusBody]!) {
          expect(s, contains('{bonus}'));
        }
      });

      test('알 수 없는 플레이스홀더 없음', () {
        final ph = RegExp(r'\{(\w+)\}');
        for (final e in t.phrases.entries) {
          for (final s in e.value) {
            for (final m in ph.allMatches(s)) {
              expect(
                ['balance', 'bonus'],
                contains(m.group(1)),
                reason: '${e.key}: $s',
              );
            }
          }
        }
      });

      test('위젯 소형 라벨 8자 이하, 중형 라벨 12자 이하', () {
        for (final s in t.phrases[PhraseKeys.widgetSmallLabel]!) {
          expect(s.runes.length, lessThanOrEqualTo(8), reason: s);
        }
        for (final s in t.phrases[PhraseKeys.widgetMediumLabel]!) {
          expect(s.runes.length, lessThanOrEqualTo(12), reason: s);
        }
        for (final s in t.phrases[PhraseKeys.widgetBonusLabel]!) {
          expect(s.runes.length, lessThanOrEqualTo(8), reason: s);
        }
      });
    });
  }

  group('AssetToneRepository', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    test('rootBundle에서 3종 모두 로드', () async {
      final repo = AssetToneRepository();
      for (final id in ToneId.values) {
        final r = await repo.load(id);
        expect(r.isSuccess, isTrue, reason: id.name);
        expect(r.dataOrNull!.id, id);
      }
    });
  });
}
