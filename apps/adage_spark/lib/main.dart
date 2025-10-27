import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(const AdageSparkApp());
}

class AdageSparkApp extends StatelessWidget {
  const AdageSparkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Adage Spark',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: _AdageColors.backgroundBottom,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _AdageColors.accentPrimary,
          brightness: Brightness.dark,
        ),
        textTheme: ThemeData(brightness: Brightness.dark).textTheme.apply(
          bodyColor: _AdageColors.textPrimary,
          displayColor: _AdageColors.textPrimary,
        ),
        useMaterial3: true,
      ),
      home: const AdageHomePage(),
    );
  }
}

class AdageHomePage extends StatefulWidget {
  const AdageHomePage({super.key});

  @override
  State<AdageHomePage> createState() => _AdageHomePageState();
}

class _AdageHomePageState extends State<AdageHomePage> {
  static const List<_AdageQuote> _quotes = [
    _AdageQuote(
      body: '끊임없는 연습은 평범한 재능을 비범하게 만든다.',
      reference:
          '“Practice isn\'t the thing you do once you\'re good.\nIt\'s the thing you do that makes you good.”\n- Malcolm Gladwell',
    ),
    _AdageQuote(
      body: '기회를 기다리기보다 작은 용기로 길을 만들어라.',
      reference:
          '“The most difficult thing is the decision to act, the rest is merely tenacity.”\n- Amelia Earhart',
    ),
    _AdageQuote(
      body: '생각에 머물지 말고 움직여라. 행동이 곧 너를 정의한다.',
      reference:
          '“You are what you do, not what you say you\'ll do.”\n- Carl Jung',
    ),
    _AdageQuote(
      body: '어제보다 나아지려는 한 걸음이 미래를 바꾼다.',
      reference:
          '“Do not wait to strike till the iron is hot; but make it hot by striking.”\n- William Butler Yeats',
    ),
    _AdageQuote(
      body: '실패는 반대가 아니라 성공으로 이어지는 구성 요소다.',
      reference:
          '“Failure is not the opposite of success; it\'s part of success.”\n- Arianna Huffington',
    ),
    _AdageQuote(
      body: '작은 성취를 찬찬히 쌓을 때 큰 꿈이 현실이 된다.',
      reference:
          '“Great things are done by a series of small things brought together.”\n- Vincent van Gogh',
    ),
  ];

  final Random _random = Random();
  late _AdageQuote _currentQuote;

  @override
  void initState() {
    super.initState();
    _currentQuote = _quotes.first;
  }

  void _showNextQuote() {
    if (_quotes.length == 1) {
      return;
    }

    _AdageQuote next;
    do {
      next = _quotes[_random.nextInt(_quotes.length)];
    } while (identical(next, _currentQuote));

    setState(() {
      _currentQuote = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_AdageColors.backgroundTop, _AdageColors.backgroundBottom],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  constraints: const BoxConstraints(maxWidth: 360),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 36,
                  ),
                  decoration: BoxDecoration(
                    color: _AdageColors.card,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: _AdageColors.accentPrimary.withOpacity(0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _AdageColors.accentPrimary.withOpacity(0.08),
                        offset: const Offset(0, 18),
                        blurRadius: 36,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 8),
                      _AdageCard(quote: _currentQuote),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _showNextQuote,
                          icon: const Icon(
                            Icons.auto_awesome_rounded,
                            size: 20,
                          ),
                          label: const Text('새로운 격언 불꽃 켜기'),
                          style: FilledButton.styleFrom(
                            backgroundColor: _AdageColors.accentPrimary,
                            foregroundColor: _AdageColors.backgroundTop,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdageCard extends StatelessWidget {
  const _AdageCard({required this.quote});

  final _AdageQuote quote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _AdageColors.quoteBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _AdageColors.accentPrimary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.format_quote_rounded,
                color: _AdageColors.accentSecondary,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                '오늘의 격언',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _AdageColors.accentSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            quote.body,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.6,
              fontSize: 18,
              color: _AdageColors.textPrimary,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            quote.reference,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.4,
              color: _AdageColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdageColors {
  static const backgroundTop = Color(0xFF1F2735);
  static const backgroundBottom = Color(0xFF131826);
  static const card = Color(0xFF1D2433);
  static const quoteBackground = Color(0x661C2231);
  static const accentPrimary = Color(0xFFF1AA00);
  static const accentSecondary = Color(0xFFF6C55A);
  static const textPrimary = Color(0xFFF8F4ED);
  static const textSecondary = Color(0xFFC9C6D0);
}

class _AdageQuote {
  const _AdageQuote({required this.body, required this.reference});

  final String body;
  final String reference;
}
