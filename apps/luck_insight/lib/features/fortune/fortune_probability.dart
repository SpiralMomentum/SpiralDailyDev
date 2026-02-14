import 'dart:math';

/// 운세 등급 모델.
class FortuneGrade {
  const FortuneGrade({
    required this.rank,
    required this.name,
    required this.category,
    required this.probability,
    required this.message,
  });

  final int rank;
  final String name;
  final String category;
  final double probability;
  final String message;
}

/// 20개 운세 등급 정의 (1등 다이아몬드 ~ 20등 돌).
const List<FortuneGrade> fortuneGrades = [
  FortuneGrade(
    rank: 1,
    name: '다이아몬드',
    category: '보석',
    probability: 0.2,
    message: '기다리던 기회가 찾아옵니다. 놓치지 말고 바로 잡으세요.',
  ),
  FortuneGrade(
    rank: 2,
    name: '플래티넘',
    category: '금속',
    probability: 0.6,
    message: '주변의 도움을 받아 일이 술술 풀리는 하루입니다.',
  ),
  FortuneGrade(
    rank: 3,
    name: '골드',
    category: '금속',
    probability: 1.0,
    message: '긍정적인 마음가짐이 좋은 결과를 끌어옵니다.',
  ),
  FortuneGrade(
    rank: 4,
    name: '에메랄드',
    category: '보석',
    probability: 1.4,
    message: '작은 손실이 있을 수 있으니 꼼꼼하게 확인해보세요.',
  ),
  FortuneGrade(
    rank: 5,
    name: '루비',
    category: '보석',
    probability: 2.4,
    message: '기분 좋은 소식이 전해지며 하루가 가볍게 느껴집니다.',
  ),
  FortuneGrade(
    rank: 6,
    name: '블루 사파이어',
    category: '보석',
    probability: 4.2,
    message: '새로운 사람과의 만남이 행운을 가져옵니다.',
  ),
  FortuneGrade(
    rank: 7,
    name: '진주',
    category: '유기물',
    probability: 6.6,
    message: '도전하기 좋은 날이니 미뤄둔 일을 시작해보세요.',
  ),
  FortuneGrade(
    rank: 8,
    name: '아쿠아마린',
    category: '보석',
    probability: 9.0,
    message: '집중력이 흐트러지기 쉬우니 우선순위를 정해 움직이세요.',
  ),
  FortuneGrade(
    rank: 9,
    name: '블루 토파즈',
    category: '보석',
    probability: 11.4,
    message: '평소보다 휴식이 필요한 날입니다. 몸과 마음을 챙기세요.',
  ),
  FortuneGrade(
    rank: 10,
    name: '오팔',
    category: '보석',
    probability: 13.2,
    message: '작은 갈등이 생길 수 있으니 말을 아끼는 것이 좋겠습니다.',
  ),
  FortuneGrade(
    rank: 11,
    name: '자수정',
    category: '보석',
    probability: 13.2,
    message: '기대하던 결과가 이루어지려면 인내심이 필요합니다.',
  ),
  FortuneGrade(
    rank: 12,
    name: '오닉스',
    category: '보석',
    probability: 11.4,
    message: '과거의 약속을 지킬 기회가 오니 적극적으로 움직이세요.',
  ),
  FortuneGrade(
    rank: 13,
    name: '자개',
    category: '유기물',
    probability: 9.0,
    message: '재정 관리에 신경 쓰면 나중에 큰 도움이 됩니다.',
  ),
  FortuneGrade(
    rank: 14,
    name: '실버',
    category: '금속',
    probability: 6.6,
    message: '감정 기복이 심해질 수 있으니 마음을 다스리세요.',
  ),
  FortuneGrade(
    rank: 15,
    name: '티타늄',
    category: '금속',
    probability: 4.2,
    message: '주변의 의견을 잘 듣고 결정하면 좋은 선택이 됩니다.',
  ),
  FortuneGrade(
    rank: 16,
    name: '텅스텐 카바이드',
    category: '금속/세라믹',
    probability: 2.4,
    message: '작은 실수도 크게 번질 수 있으니 서두르지 마세요.',
  ),
  FortuneGrade(
    rank: 17,
    name: '지르코니아 세라믹',
    category: '세라믹',
    probability: 1.4,
    message: '체력이 떨어지기 쉬우니 충분한 수면이 필요합니다.',
  ),
  FortuneGrade(
    rank: 18,
    name: '스테인리스 스틸',
    category: '금속',
    probability: 1.0,
    message: '감정적인 대화는 피하고 차분하게 상황을 정리하세요.',
  ),
  FortuneGrade(
    rank: 19,
    name: '구리',
    category: '금속',
    probability: 0.6,
    message: '중요한 결정은 내일로 미루는 편이 더 현명합니다.',
  ),
  FortuneGrade(
    rank: 20,
    name: '돌',
    category: '자연물',
    probability: 0.2,
    message: '계획한 대로 흘러가지 않을 수 있으니 유연하게 대처하세요.',
  ),
];

/// 전체 등급 확률 합계.
final double totalProbability = fortuneGrades.fold<double>(
  0,
  (sum, grade) => sum + grade.probability,
);

/// 가중치 기반 누적합 방식으로 등급을 선택한다.
///
/// [random]이 생성한 값(0 ~ totalProbability)을 누적합과 비교하여
/// 해당 구간의 등급을 반환한다.
FortuneGrade pickGrade(Random random) {
  final roll = random.nextDouble() * totalProbability;
  double cumulative = 0;

  for (final grade in fortuneGrades) {
    cumulative += grade.probability;
    if (roll <= cumulative) {
      return grade;
    }
  }

  return fortuneGrades.last;
}

/// 해당 등급까지의 누적 확률(상위 %)을 포맷팅한 문자열로 반환한다.
String formattedTopPercent(FortuneGrade grade) {
  double cumulative = 0;
  for (final item in fortuneGrades) {
    cumulative += item.probability;
    if (item.rank == grade.rank) {
      break;
    }
  }

  final percent = cumulative;
  if (percent == percent.truncateToDouble()) {
    return '${percent.toStringAsFixed(0)}%';
  }
  return '${percent.toStringAsFixed(1)}%';
}
