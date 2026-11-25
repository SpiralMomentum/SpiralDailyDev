import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/app_config.dart';
import '../domain/calendar_date.dart';
import '../../kairos/presentation/kairos_card.dart';
import '../../tone/domain/phrase_keys.dart';
import '../../tone/domain/tone_table.dart';
import 'passbook_cubit.dart';
import 'passbook_state.dart';

String _date(CalendarDate d) =>
    '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

/// 통장 형태의 메인 화면. [PassbookCubit]을 상위에서 제공해야 한다.
class PassbookPage extends StatelessWidget {
  const PassbookPage({
    super.key,
    required this.config,
    required this.tone,
    required this.onOpenSettings,
    this.opener = openExternal,
  });

  final AppConfig config;
  final ToneTable tone;
  final VoidCallback onOpenSettings;
  final UrlOpener opener;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PassbookCubit, PassbookState>(
      builder: (context, s) {
        final theme = Theme.of(context);
        final text = theme.textTheme;
        final accent = theme.colorScheme.primary;
        final withdrawal = s.phrases[PhraseKeys.mainWithdrawal];
        final bonus = s.phrases[PhraseKeys.mainBonusNotice];
        return Scaffold(
          appBar: AppBar(
            title: Text(s.phrases[PhraseKeys.mainTitle]!),
            backgroundColor: Colors.transparent,
            actions: [
              IconButton(
                tooltip: '설정',
                icon: const Icon(Icons.settings_outlined),
                onPressed: onOpenSettings,
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  s.phrases[PhraseKeys.mainBalanceLabel]!,
                  style: text.titleMedium,
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    s.display,
                    key: const Key('balance'),
                    // 강조색은 대비가 3.0 미만인 말투가 있어 숫자는 전경색으로 그린다.
                    style: text.displayLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (withdrawal != null) Text(withdrawal, style: text.bodyLarge),
                if (bonus != null) Text(bonus, style: text.bodyLarge),
                const SizedBox(height: 24),
                LinearProgressIndicator(
                  key: const Key('progress'),
                  value: s.usedRatio,
                  minHeight: 8,
                  color: accent,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
                const SizedBox(height: 8),
                // 큰 글꼴에서 두 날짜가 한 줄에 안 들어가면 다음 줄로 내린다.
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _DateColumn(
                      label: s.phrases[PhraseKeys.mainOpenedLabel]!,
                      value: _date(s.birth),
                    ),
                    _DateColumn(
                      label: s.phrases[PhraseKeys.mainMaturityLabel]!,
                      value: _date(s.maturity),
                      end: true,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Divider(color: accent),
                const SizedBox(height: 16),
                KairosCard(
                  config: config,
                  tone: tone,
                  today: s.today,
                  opener: opener,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DateColumn extends StatelessWidget {
  const _DateColumn({
    required this.label,
    required this.value,
    this.end = false,
  });

  final String label;
  final String value;
  final bool end;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: end
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(label, style: text.bodySmall),
        Text(value, style: text.bodyLarge),
      ],
    );
  }
}
