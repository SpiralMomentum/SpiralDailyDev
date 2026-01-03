import 'dart:math';

import 'package:flutter/material.dart';

import 'luck_theme.dart';

class FortunePreviewPage extends StatefulWidget {
  const FortunePreviewPage({super.key});

  @override
  State<FortunePreviewPage> createState() => _FortunePreviewPageState();
}

class _FortunePreviewPageState extends State<FortunePreviewPage> {
  static const List<_FortuneGrade> _fortuneGrades = [
    _FortuneGrade(
      rank: 1,
      name: '다이아몬드',
      category: '보석',
      probability: 0.2,
      message: '기다리던 기회가 찾아옵니다. 놓치지 말고 바로 잡으세요.',
    ),
    _FortuneGrade(
      rank: 2,
      name: '플래티넘',
      category: '금속',
      probability: 0.6,
      message: '주변의 도움을 받아 일이 술술 풀리는 하루입니다.',
    ),
    _FortuneGrade(
      rank: 3,
      name: '골드',
      category: '금속',
      probability: 1.0,
      message: '긍정적인 마음가짐이 좋은 결과를 끌어옵니다.',
    ),
    _FortuneGrade(
      rank: 4,
      name: '에메랄드',
      category: '보석',
      probability: 1.4,
      message: '작은 손실이 있을 수 있으니 꼼꼼하게 확인해보세요.',
    ),
    _FortuneGrade(
      rank: 5,
      name: '루비',
      category: '보석',
      probability: 2.4,
      message: '기분 좋은 소식이 전해지며 하루가 가볍게 느껴집니다.',
    ),
    _FortuneGrade(
      rank: 6,
      name: '블루 사파이어',
      category: '보석',
      probability: 4.2,
      message: '새로운 사람과의 만남이 행운을 가져옵니다.',
    ),
    _FortuneGrade(
      rank: 7,
      name: '진주',
      category: '유기물',
      probability: 6.6,
      message: '도전하기 좋은 날이니 미뤄둔 일을 시작해보세요.',
    ),
    _FortuneGrade(
      rank: 8,
      name: '아쿠아마린',
      category: '보석',
      probability: 9.0,
      message: '집중력이 흐트러지기 쉬우니 우선순위를 정해 움직이세요.',
    ),
    _FortuneGrade(
      rank: 9,
      name: '블루 토파즈',
      category: '보석',
      probability: 11.4,
      message: '평소보다 휴식이 필요한 날입니다. 몸과 마음을 챙기세요.',
    ),
    _FortuneGrade(
      rank: 10,
      name: '오팔',
      category: '보석',
      probability: 13.2,
      message: '작은 갈등이 생길 수 있으니 말을 아끼는 것이 좋겠습니다.',
    ),
    _FortuneGrade(
      rank: 11,
      name: '자수정',
      category: '보석',
      probability: 13.2,
      message: '기대하던 결과가 이루어지려면 인내심이 필요합니다.',
    ),
    _FortuneGrade(
      rank: 12,
      name: '오닉스',
      category: '보석',
      probability: 11.4,
      message: '과거의 약속을 지킬 기회가 오니 적극적으로 움직이세요.',
    ),
    _FortuneGrade(
      rank: 13,
      name: '자개',
      category: '유기물',
      probability: 9.0,
      message: '재정 관리에 신경 쓰면 나중에 큰 도움이 됩니다.',
    ),
    _FortuneGrade(
      rank: 14,
      name: '실버',
      category: '금속',
      probability: 6.6,
      message: '감정 기복이 심해질 수 있으니 마음을 다스리세요.',
    ),
    _FortuneGrade(
      rank: 15,
      name: '티타늄',
      category: '금속',
      probability: 4.2,
      message: '주변의 의견을 잘 듣고 결정하면 좋은 선택이 됩니다.',
    ),
    _FortuneGrade(
      rank: 16,
      name: '텅스텐 카바이드',
      category: '금속/세라믹',
      probability: 2.4,
      message: '작은 실수도 크게 번질 수 있으니 서두르지 마세요.',
    ),
    _FortuneGrade(
      rank: 17,
      name: '지르코니아 세라믹',
      category: '세라믹',
      probability: 1.4,
      message: '체력이 떨어지기 쉬우니 충분한 수면이 필요합니다.',
    ),
    _FortuneGrade(
      rank: 18,
      name: '스테인리스 스틸',
      category: '금속',
      probability: 1.0,
      message: '감정적인 대화는 피하고 차분하게 상황을 정리하세요.',
    ),
    _FortuneGrade(
      rank: 19,
      name: '구리',
      category: '금속',
      probability: 0.6,
      message: '중요한 결정은 내일로 미루는 편이 더 현명합니다.',
    ),
    _FortuneGrade(
      rank: 20,
      name: '돌',
      category: '자연물',
      probability: 0.2,
      message: '계획한 대로 흘러가지 않을 수 있으니 유연하게 대처하세요.',
    ),
  ];

  static final double _totalProbability = _fortuneGrades.fold<double>(
    0,
    (sum, grade) => sum + grade.probability,
  );

  String _fortuneMessage = '아래 물음표 중 하나를 선택해 오늘의 행운 소재를 확인해보세요.';
  bool _isButtonVisible = true;
  bool _showReset = false;
  final List<_FortuneGrade> _historyRank1 = [];

  void _revealFortuneWithVariant(int variant) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final seededValue = now + (variant * 9973);
    final random = Random(seededValue);
    final selectedGrade = _pickGrade(random);

    final topPercent = _formattedTopPercent(selectedGrade);

    setState(() {
      _fortuneMessage =
          '${selectedGrade.rank}등 ${selectedGrade.name}\n'
          '상위 $topPercent\n'
          '${selectedGrade.message}';
      _isButtonVisible = false;
      _showReset = true;
      if (selectedGrade.rank == 1) {
        _historyRank1.add(selectedGrade);
      }
    });
  }

  void _resetFortune() {
    setState(() {
      _fortuneMessage = '아래 물음표 중 하나를 선택해 오늘의 행운 소재를 확인해보세요.';
      _isButtonVisible = true;
      _showReset = false;
    });
  }

  _FortuneGrade _pickGrade(Random random) {
    final roll = random.nextDouble() * _totalProbability;
    double cumulative = 0;

    for (final grade in _fortuneGrades) {
      cumulative += grade.probability;
      if (roll <= cumulative) {
        return grade;
      }
    }

    return _fortuneGrades.last;
  }

  String _formattedTopPercent(_FortuneGrade grade) {
    double cumulative = 0;
    for (final item in _fortuneGrades) {
      cumulative += item.probability;
      if (identical(item, grade)) {
        break;
      }
    }

    final percent = cumulative;
    if (percent == percent.truncateToDouble()) {
      return '${percent.toStringAsFixed(0)}%';
    }
    return '${percent.toStringAsFixed(1)}%';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 320),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
            decoration: BoxDecoration(
              color: LuckColors.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: LuckColors.accentBorder),
              boxShadow: [
                BoxShadow(
                  color: LuckColors.softShadow,
                  offset: const Offset(0, 18),
                  blurRadius: 36,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '오늘의 운세',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: LuckColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: LuckColors.accent, width: 2),
                  ),
                  child: const Icon(
                    Icons.card_giftcard_outlined,
                    size: 48,
                    color: LuckColors.accent,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  _fortuneMessage,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: LuckColors.textPrimary,
                    height: 1.4,
                  ),
                ),
                if (_isButtonVisible) ...[
                  const SizedBox(height: 36),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 20,
                    runSpacing: 12,
                    children: List.generate(
                      4,
                      (index) => _QuestionMarkButton(
                        label: '선택 ${index + 1}',
                        onTap: () => _revealFortuneWithVariant(index + 1),
                      ),
                    ),
                  ),
                ],
                if (_showReset) ...[
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: _resetFortune,
                    style: TextButton.styleFrom(
                      foregroundColor: LuckColors.accent,
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    child: const Text('다시하기'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showHistory,
        backgroundColor: LuckColors.accent,
        foregroundColor: Colors.white,
        child: const Icon(Icons.emoji_events_outlined),
      ),
    );
  }

  void _showHistory() {
    if (_historyRank1.isEmpty) {
      showModalBottomSheet<void>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        backgroundColor: LuckColors.card,
        builder: (context) => const _HistorySheet(entries: []),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: LuckColors.card,
      builder: (context) => _HistorySheet(
        entries: _historyRank1.reversed.toList(growable: false),
      ),
    );
  }
}

class _FortuneGrade {
  const _FortuneGrade({
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

class _QuestionMarkButton extends StatelessWidget {
  const _QuestionMarkButton({required this.onTap, required this.label});

  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: LuckColors.accent, width: 2),
                color: LuckColors.accentFill,
              ),
              alignment: Alignment.center,
              child: const Text(
                '?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: LuckColors.accent,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: LuckColors.textSecondary),
        ),
      ],
    );
  }
}

class _HistorySheet extends StatelessWidget {
  const _HistorySheet({required this.entries});

  final List<_FortuneGrade> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '아직 1등 기록이 없어요',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: LuckColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              '행운의 첫 번째 주인공이 되어보세요!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: LuckColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 36),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '1등 기록',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: LuckColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  '${entries.length}회',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: LuckColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemBuilder: (context, index) {
                final entry = entries[index];
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: LuckColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: LuckColors.accentBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.emoji_events_outlined,
                            color: LuckColors.accent,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            entry.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: LuckColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        entry.message,
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: LuckColors.textSecondary,
                                  height: 1.4,
                                ),
                      ),
                    ],
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: entries.length,
            ),
          ),
        ],
      ),
    );
  }
}
