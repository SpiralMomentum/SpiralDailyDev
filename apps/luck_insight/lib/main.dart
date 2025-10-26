import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(const LuckInsightApp());
}

class LuckInsightApp extends StatelessWidget {
  const LuckInsightApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Luck Insight',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: _LuckColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _LuckColors.accent,
          brightness: Brightness.dark,
        ),
        textTheme: ThemeData(brightness: Brightness.dark).textTheme.apply(
          bodyColor: _LuckColors.accent,
          displayColor: _LuckColors.accent,
        ),
        useMaterial3: true,
      ),
      home: const FortunePreviewPage(),
    );
  }
}

class FortunePreviewPage extends StatefulWidget {
  const FortunePreviewPage({super.key});

  @override
  State<FortunePreviewPage> createState() => _FortunePreviewPageState();
}

class _FortunePreviewPageState extends State<FortunePreviewPage> {
  static const List<_FortuneGrade> _fortuneGrades = [
    _FortuneGrade(
      grade: 1,
      probability: 0.2,
      message: '기다리던 기회가 찾아옵니다. 놓치지 말고 바로 잡으세요.',
    ),
    _FortuneGrade(
      grade: 2,
      probability: 0.6,
      message: '주변의 도움을 받아 일이 술술 풀리는 하루입니다.',
    ),
    _FortuneGrade(
      grade: 3,
      probability: 1.0,
      message: '긍정적인 마음가짐이 좋은 결과를 끌어옵니다.',
    ),
    _FortuneGrade(
      grade: 4,
      probability: 1.4,
      message: '작은 손실이 있을 수 있으니 꼼꼼하게 확인해보세요.',
    ),
    _FortuneGrade(
      grade: 5,
      probability: 2.4,
      message: '기분 좋은 소식이 전해지며 하루가 가볍게 느껴집니다.',
    ),
    _FortuneGrade(
      grade: 6,
      probability: 4.2,
      message: '새로운 사람과의 만남이 행운을 가져옵니다.',
    ),
    _FortuneGrade(
      grade: 7,
      probability: 6.6,
      message: '도전하기 좋은 날이니 미뤄둔 일을 시작해보세요.',
    ),
    _FortuneGrade(
      grade: 8,
      probability: 9.0,
      message: '집중력이 흐트러지기 쉬우니 우선순위를 정해 움직이세요.',
    ),
    _FortuneGrade(
      grade: 9,
      probability: 11.4,
      message: '평소보다 휴식이 필요한 날입니다. 몸과 마음을 챙기세요.',
    ),
    _FortuneGrade(
      grade: 10,
      probability: 13.2,
      message: '작은 갈등이 생길 수 있으니 말을 아끼는 것이 좋겠습니다.',
    ),
    _FortuneGrade(
      grade: 11,
      probability: 13.2,
      message: '기대하던 결과가 이루어지려면 인내심이 필요합니다.',
    ),
    _FortuneGrade(
      grade: 12,
      probability: 11.4,
      message: '과거의 약속을 지킬 기회가 오니 적극적으로 움직이세요.',
    ),
    _FortuneGrade(
      grade: 13,
      probability: 9.0,
      message: '재정 관리에 신경 쓰면 나중에 큰 도움이 됩니다.',
    ),
    _FortuneGrade(
      grade: 14,
      probability: 6.6,
      message: '감정 기복이 심해질 수 있으니 마음을 다스리세요.',
    ),
    _FortuneGrade(
      grade: 15,
      probability: 4.2,
      message: '주변의 의견을 잘 듣고 결정하면 좋은 선택이 됩니다.',
    ),
    _FortuneGrade(
      grade: 16,
      probability: 2.4,
      message: '작은 실수도 크게 번질 수 있으니 서두르지 마세요.',
    ),
    _FortuneGrade(
      grade: 17,
      probability: 1.4,
      message: '체력이 떨어지기 쉬우니 충분한 수면이 필요합니다.',
    ),
    _FortuneGrade(
      grade: 18,
      probability: 1.0,
      message: '감정적인 대화는 피하고 차분하게 상황을 정리하세요.',
    ),
    _FortuneGrade(
      grade: 19,
      probability: 0.6,
      message: '중요한 결정은 내일로 미루는 편이 더 현명합니다.',
    ),
    _FortuneGrade(
      grade: 20,
      probability: 0.2,
      message: '계획한 대로 흘러가지 않을 수 있으니 유연하게 대처하세요.',
    ),
  ];

  static final double _totalProbability = _fortuneGrades.fold<double>(
    0,
    (sum, grade) => sum + grade.probability,
  );

  String _fortuneMessage = '친구의 예기치 않은 충고가\n도움이 되는 날입니다.';
  bool _isButtonVisible = true;
  bool _showReset = false;

  void _revealFortune() {
    final seed = DateTime.now().millisecondsSinceEpoch;
    final random = Random(seed);
    final selectedGrade = _pickGrade(random);

    setState(() {
      _fortuneMessage =
          '등급 ${selectedGrade.grade} (확률 ${selectedGrade.probability}%)\n${selectedGrade.message}';
      _isButtonVisible = false;
      _showReset = true;
    });
  }

  void _resetFortune() {
    setState(() {
      _fortuneMessage = '친구의 예기치 않은 충고가\n도움이 되는 날입니다.';
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
              color: _LuckColors.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _LuckColors.accent.withOpacity(0.2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '오늘의 운세',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: _LuckColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _LuckColors.accent, width: 2),
                  ),
                  child: const Icon(
                    Icons.emoji_emotions_outlined,
                    size: 48,
                    color: _LuckColors.accent,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  _fortuneMessage,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: _LuckColors.accent,
                    height: 1.4,
                  ),
                ),
                if (_isButtonVisible) ...[
                  const SizedBox(height: 36),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _revealFortune,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _LuckColors.accent,
                        foregroundColor: _LuckColors.background,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('운세 확인하기'),
                    ),
                  ),
                ],
                if (_showReset) ...[
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: _resetFortune,
                    style: TextButton.styleFrom(
                      foregroundColor: _LuckColors.accent,
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
    );
  }
}

class _LuckColors {
  static const background = Color(0xFF06152A);
  static const card = Color(0xFF0B1E33);
  static const accent = Color(0xFFF6C56C);
}

class _FortuneGrade {
  const _FortuneGrade({
    required this.grade,
    required this.probability,
    required this.message,
  });

  final int grade;
  final double probability;
  final String message;
}
