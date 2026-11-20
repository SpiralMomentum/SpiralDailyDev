import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/settings.dart';

typedef HistoryCounts = ({int attempts, int manifestations});

/// 언어 선택과 누적 기록 관리. 누적 기록 기능은 앱 조립 영역이 함수로 넘겨준다.
class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.language,
    required this.onLanguageChanged,
    required this.loadHistory,
    required this.clearHistory,
  });

  /// null 이면 기기 설정을 따른다.
  final String? language;
  final ValueChanged<String?> onLanguageChanged;
  final Future<HistoryCounts?> Function() loadHistory;
  final Future<bool> Function() clearHistory;

  static const languageNames = {
    'ko': '한국어',
  };

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late String? _language = widget.language;
  late Future<HistoryCounts?> _history = widget.loadHistory();

  Future<void> _confirmClear() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsDeleteConfirmTitle),
        content: Text(l10n.settingsDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            key: const Key('confirm_delete'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final cleared = await widget.clearHistory();
    if (!mounted) return;
    final reloaded = widget.loadHistory();
    setState(() {
      _history = reloaded;
    });
    messenger.showSnackBar(
      SnackBar(content: Text(cleared ? l10n.settingsDeleted : l10n.commonError)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          ListTile(title: Text(l10n.settingsLanguage, style: Theme.of(context).textTheme.titleSmall)),
          RadioGroup<String?>(
            groupValue: _language,
            onChanged: (value) {
              setState(() => _language = value);
              widget.onLanguageChanged(value);
            },
            child: Column(
              children: [
                RadioListTile<String?>(
                  key: const Key('language_system'),
                  value: null,
                  title: Text(l10n.settingsLanguageSystem),
                ),
                for (final code in SupportedLanguages.codes)
                  RadioListTile<String?>(
                    key: Key('language_$code'),
                    value: code,
                    title: Text(SettingsPage.languageNames[code]!),
                  ),
              ],
            ),
          ),
          const Divider(),
          ListTile(title: Text(l10n.settingsHistory, style: Theme.of(context).textTheme.titleSmall)),
          FutureBuilder<HistoryCounts?>(
            future: _history,
            builder: (context, snapshot) {
              final counts = snapshot.data;
              return ListTile(
                key: const Key('history_count'),
                title: Text(
                  counts == null
                      ? '-'
                      : l10n.settingsHistoryCount(counts.attempts, counts.manifestations),
                ),
              );
            },
          ),
          ListTile(
            key: const Key('delete_all'),
            leading: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
            title: Text(
              l10n.settingsDeleteAll,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: _confirmClear,
          ),
        ],
      ),
    );
  }
}
