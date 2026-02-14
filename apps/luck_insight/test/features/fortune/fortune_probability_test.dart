import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:luck_insight/features/fortune/fortune_probability.dart';

void main() {
  group('FortuneGrade 확률 데이터 검증', () {
    test('20개 등급이 정의되어 있다', () {
      expect(fortuneGrades.length, 20);
    });

    test('등급 확률 합계가 정확히 100이다', () {
      final sum = fortuneGrades.fold<double>(
        0,
        (acc, grade) => acc + grade.probability,
      );
      expect(sum, closeTo(100.0, 1e-10));
    });

    test('totalProbability가 등급 확률 합계와 일치한다', () {
      final manualSum = fortuneGrades.fold<double>(
        0,
        (acc, grade) => acc + grade.probability,
      );
      expect(totalProbability, closeTo(manualSum, 1e-10));
    });

    test('모든 등급의 확률이 0보다 크다 (전체 등급 도달 가능)', () {
      for (final grade in fortuneGrades) {
        expect(
          grade.probability,
          greaterThan(0),
          reason: '${grade.rank}등 ${grade.name}의 확률이 0 이하',
        );
      }
    });

    test('등급 rank가 1부터 20까지 연속이다', () {
      for (int i = 0; i < fortuneGrades.length; i++) {
        expect(fortuneGrades[i].rank, i + 1);
      }
    });
  });

  group('pickGrade 결정성 검증', () {
    test('동일 시드에서 동일 결과가 나온다', () {
      const seed = 42;
      final result1 = pickGrade(Random(seed));
      final result2 = pickGrade(Random(seed));

      expect(result1.rank, result2.rank);
      expect(result1.name, result2.name);
    });

    test('동일 시드로 여러 번 호출해도 매번 같은 결과이다', () {
      const seed = 12345;
      final results = List.generate(
        100,
        (_) => pickGrade(Random(seed)),
      );

      final firstRank = results.first.rank;
      for (final result in results) {
        expect(result.rank, firstRank);
      }
    });

    test('다른 시드에서 다른 결과가 나올 수 있다', () {
      final ranks = <int>{};
      for (int seed = 0; seed < 1000; seed++) {
        ranks.add(pickGrade(Random(seed)).rank);
        if (ranks.length > 1) break;
      }
      expect(ranks.length, greaterThan(1));
    });
  });

  group('pickGrade 경계값 테스트', () {
    test('roll 값이 0이면 첫 번째 등급(다이아몬드)이 선택된다', () {
      // nextDouble() = 0.0 -> roll = 0.0
      // cumulative = 0.2 (첫 등급), 0.0 <= 0.2 이므로 1등급
      final mockRandom = _FixedRandom(0.0);
      final result = pickGrade(mockRandom);
      expect(result.rank, 1);
      expect(result.name, '다이아몬드');
    });

    test('roll 값이 최대에 가까우면 마지막 등급(돌)이 선택된다', () {
      // nextDouble()이 1.0 미만의 최대값일 때 마지막 등급 구간
      final nearMax = 1.0 - 1e-15;
      final mockRandom = _FixedRandom(nearMax);
      final result = pickGrade(mockRandom);
      expect(result.rank, 20);
      expect(result.name, '돌');
    });

    test('각 등급의 누적 확률 중간점에서 해당 등급이 선택된다', () {
      // 부동소수점 경계 오차를 피하기 위해 각 등급 구간의 중간점을 사용
      double cumulative = 0;
      for (final grade in fortuneGrades) {
        final midPoint = cumulative + grade.probability / 2;
        final ratio = midPoint / totalProbability;
        final mockRandom = _FixedRandom(ratio);
        final result = pickGrade(mockRandom);
        expect(
          result.rank,
          grade.rank,
          reason: '구간 중간점 $midPoint에서 ${grade.rank}등 ${grade.name}이 선택되어야 한다',
        );
        cumulative += grade.probability;
      }
    });

    test('구간 시작 직후 값에서 올바른 등급이 선택된다', () {
      // 이전 등급 누적합보다 충분히 큰 값을 사용하여
      // 해당 등급 구간에 확실히 진입하는지 확인
      double cumulative = 0;
      for (int i = 0; i < fortuneGrades.length; i++) {
        if (i == 0) {
          // 첫 등급은 roll = 0에서 이미 검증
          cumulative += fortuneGrades[i].probability;
          continue;
        }
        // 이전 등급 누적합 + 현재 등급 확률의 10%
        final intoGrade = cumulative + fortuneGrades[i].probability * 0.1;
        final ratio = intoGrade / totalProbability;
        final mockRandom = _FixedRandom(ratio);
        final result = pickGrade(mockRandom);
        expect(
          result.rank,
          fortuneGrades[i].rank,
          reason: '값 $intoGrade에서 ${fortuneGrades[i].rank}등이 선택되어야 한다',
        );
        cumulative += fortuneGrades[i].probability;
      }
    });
  });

  group('pickGrade 전체 등급 도달 가능성', () {
    test('구간 중간점 시행으로 모든 20개 등급이 선택된다', () {
      final reachedRanks = <int>{};

      double cumulative = 0;
      for (final grade in fortuneGrades) {
        final midPoint = cumulative + grade.probability / 2;
        final ratio = midPoint / totalProbability;
        final mockRandom = _FixedRandom(ratio);
        final result = pickGrade(mockRandom);
        reachedRanks.add(result.rank);
        cumulative += grade.probability;
      }

      expect(reachedRanks.length, 20,
          reason: '모든 20개 등급이 이론적으로 선택 가능해야 한다');
    });

    test('랜덤 시드 10000회 시행으로 모든 등급이 나온다', () {
      final reachedRanks = <int>{};
      for (int seed = 0; seed < 10000; seed++) {
        final result = pickGrade(Random(seed));
        reachedRanks.add(result.rank);
      }

      expect(reachedRanks.length, 20,
          reason: '10000회 시행에서 모든 등급이 한 번은 나와야 한다');
    });
  });

  group('formattedTopPercent 검증', () {
    test('1등급(다이아몬드)의 상위 퍼센트는 0.2%이다', () {
      final result = formattedTopPercent(fortuneGrades[0]);
      expect(result, '0.2%');
    });

    test('3등급(골드)까지의 누적 확률이 올바르게 표시된다', () {
      // 0.2 + 0.6 + 1.0 = 1.8
      final result = formattedTopPercent(fortuneGrades[2]);
      expect(result, '1.8%');
    });

    test('20등급(돌)의 상위 퍼센트는 100%이다', () {
      final result = formattedTopPercent(fortuneGrades[19]);
      // 부동소수점 합산이므로 '100%' 또는 '100.0%'
      expect(result, anyOf('100%', '100.0%'));
    });

    test('모든 등급의 상위 퍼센트가 % 기호로 끝난다', () {
      for (final grade in fortuneGrades) {
        final result = formattedTopPercent(grade);
        expect(result, endsWith('%'),
            reason: '${grade.rank}등 ${grade.name}의 결과가 %로 끝나야 한다');
      }
    });
  });
}

/// nextDouble()이 항상 고정 값을 반환하는 테스트용 Random 구현.
class _FixedRandom implements Random {
  _FixedRandom(this._fixedValue);

  final double _fixedValue;

  @override
  double nextDouble() => _fixedValue;

  @override
  int nextInt(int max) => (_fixedValue * max).floor();

  @override
  bool nextBool() => _fixedValue >= 0.5;
}
