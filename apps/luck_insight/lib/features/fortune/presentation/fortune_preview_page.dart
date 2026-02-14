import 'dart:math';

import 'package:flutter/material.dart';

import '../fortune_probability.dart';
import 'luck_theme.dart';

class FortunePreviewPage extends StatefulWidget {
  const FortunePreviewPage({super.key});

  @override
  State<FortunePreviewPage> createState() => _FortunePreviewPageState();
}

class _FortunePreviewPageState extends State<FortunePreviewPage> {
  String _fortuneMessage = '아래 물음표 중 하나를 선택해 오늘의 행운 소재를 확인해보세요.';
  bool _isButtonVisible = true;
  bool _showReset = false;
  final List<FortuneGrade> _historyRank1 = [];

  void _revealFortuneWithVariant(int variant) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final seededValue = now + (variant * 9973);
    final random = Random(seededValue);
    final selectedGrade = pickGrade(random);

    final topPercent = formattedTopPercent(selectedGrade);

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

  final List<FortuneGrade> entries;

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
