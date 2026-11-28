import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../ingest/presentation/diagnostics_page.dart';
import '../../ingest/presentation/notification_access_page.dart';
import '../../ingest/presentation/shortcut_guide_page.dart';
import '../../ledger/domain/money_format.dart';
import '../../parsing/presentation/parse_test_page.dart';
import 'filters_page.dart';
import 'names_page.dart';
import 'settings_cubit.dart';
import 'theme_page.dart';

/// 앱 최상단의 [SettingsCubit]을 읽어 쓴다.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) => const _SettingsView();
}

/// 설정 하위 화면을 같은 [SettingsCubit]으로 연다.
Future<void> _push(BuildContext context, Widget page) {
  final cubit = context.read<SettingsCubit>();
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => BlocProvider.value(value: cubit, child: page),
    ),
  );
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  Future<void> _editNumber(
    BuildContext context, {
    required String title,
    required String suffix,
    required int? initial,
    required bool allowEmpty,
    required void Function(int? value) onSave,
  }) async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) =>
          _NumberDialog(title: title, suffix: suffix, initial: initial),
    );
    if (result == null) return;
    final trimmed = result.trim();
    if (trimmed.isEmpty) {
      if (allowEmpty) onSave(null);
      return;
    }
    onSave(int.tryParse(trimmed));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('설정')),
    body: BlocConsumer<SettingsCubit, SettingsState>(
      listenWhen: (a, b) => b.error != null && a.error != b.error,
      listener: (context, state) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(state.error!))),
      builder: (context, state) {
        if (state.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        final s = state.settings;
        final cubit = context.read<SettingsCubit>();
        return ListView(
          children: [
            ListTile(
              title: const Text('기간 시작일'),
              subtitle: Text('매월 ${s.startDay}일'),
              onTap: () => _editNumber(
                context,
                title: '기간 시작일 (1~31)',
                suffix: '일',
                initial: s.startDay,
                allowEmpty: false,
                onSave: (v) {
                  if (v != null) cubit.setStartDay(v);
                },
              ),
            ),
            ListTile(
              title: const Text('월 예산'),
              subtitle: Text(
                s.budget == null ? '설정 안 함' : formatWon(s.budget!),
              ),
              onTap: () => _editNumber(
                context,
                title: '월 예산 (비우면 해제)',
                suffix: '원',
                initial: s.budget,
                allowEmpty: true,
                onSave: cubit.setBudget,
              ),
            ),
            SwitchListTile(
              title: const Text('확정된 문자 원문 지우기'),
              value: s.deleteRawText,
              onChanged: cubit.setDeleteRawText,
            ),
            SwitchListTile(
              title: const Text('위젯 금액 숨기기'),
              value: s.hideAmounts,
              onChanged: cubit.setHideAmounts,
            ),
            ListTile(
              title: const Text('테마'),
              subtitle: Text(
                '${s.themeId.label} · ${themeModeLabel(s.themeMode)}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _push(context, const ThemePage()),
            ),
            const Divider(),
            ListTile(
              title: const Text('문자 필터'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _push(context, const FiltersPage()),
            ),
            ListTile(
              title: const Text('이름 등록'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _push(context, const NamesPage()),
            ),
            ListTile(
              title: const Text('파싱 테스트'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ParseTestPage()),
              ),
            ),
            if (defaultTargetPlatform == TargetPlatform.android)
              ListTile(
                title: const Text('알림 수집 설정'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _push(context, const NotificationAccessPage()),
              )
            else
              ListTile(
                title: const Text('단축어 설정 안내'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ShortcutGuidePage(),
                  ),
                ),
              ),
            ListTile(
              title: const Text('수집 진단'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const DiagnosticsPage(),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _NumberDialog extends StatefulWidget {
  const _NumberDialog({
    required this.title,
    required this.suffix,
    required this.initial,
  });

  final String title;
  final String suffix;
  final int? initial;

  @override
  State<_NumberDialog> createState() => _NumberDialogState();
}

class _NumberDialogState extends State<_NumberDialog> {
  late final TextEditingController _c = TextEditingController(
    text: widget.initial?.toString() ?? '',
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: TextField(
      controller: _c,
      autofocus: true,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(suffixText: widget.suffix),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('취소'),
      ),
      FilledButton(
        onPressed: () => Navigator.of(context).pop(_c.text),
        child: const Text('저장'),
      ),
    ],
  );
}
