import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../message_filter/domain/name_registry.dart';
import 'settings_cubit.dart';

/// 다듬은 이름이 두 글자보다 짧은지. 한 글자 이름은 엉뚱한 문자에 걸리므로 받지 않는다.
bool isNameTooShort(String input) => input.trim().length < 2;

/// 이름 입력을 다듬어 목록에 더한다. 두 글자 미만·중복은 무시한다.
List<String> addName(List<String> names, String input) {
  final name = input.trim();
  if (isNameTooShort(name) || names.contains(name)) return names;
  return [...names, name];
}

class NamesPage extends StatelessWidget {
  const NamesPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('이름 등록')),
    body: BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        final names = state.settings.names;
        final cubit = context.read<SettingsCubit>();
        NameRegistry with_({
          List<String>? self,
          List<String>? charge,
          List<String>? prepaid,
        }) => NameRegistry(
          selfNames: self ?? names.selfNames,
          chargeTargets: charge ?? names.chargeTargets,
          prepaidMoneys: prepaid ?? names.prepaidMoneys,
        );
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _NameSection(
              title: '내 이름',
              help: '본인 예금주명, 계좌 별칭, 카드사명 — 이 이름으로 보낸 이체는 지출에서 빠져요',
              names: names.selfNames,
              onChanged: (v) => cubit.saveNames(with_(self: v)),
            ),
            _NameSection(
              title: '충전처',
              help: '출금 상대가 이 이름이면 선불 충전으로 지출에 넣어요. 예: 쿠팡페이',
              names: names.chargeTargets,
              onChanged: (v) => cubit.saveNames(with_(charge: v)),
            ),
            _NameSection(
              title: '선불 머니',
              help: '결제 문자에 이 이름이 있으면 이미 충전 때 셌으므로 빼요. 예: 쿠페이머니',
              names: names.prepaidMoneys,
              onChanged: (v) => cubit.saveNames(with_(prepaid: v)),
            ),
          ],
        );
      },
    ),
  );
}

class _NameSection extends StatefulWidget {
  const _NameSection({
    required this.title,
    required this.help,
    required this.names,
    required this.onChanged,
  });

  final String title;
  final String help;
  final List<String> names;
  final void Function(List<String>) onChanged;

  @override
  State<_NameSection> createState() => _NameSectionState();
}

class _NameSectionState extends State<_NameSection> {
  final TextEditingController _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _add() {
    if (isNameTooShort(_c.text)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('두 글자 이상 입력해 주세요.')));
      return;
    }
    final next = addName(widget.names, _c.text);
    _c.clear();
    if (next != widget.names) widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: theme.textTheme.titleMedium),
          Text(widget.help, style: theme.textTheme.bodySmall),
          for (final n in widget.names)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(n),
              trailing: IconButton(
                tooltip: '삭제',
                icon: const Icon(Icons.close),
                onPressed: () => widget.onChanged([
                  for (final x in widget.names)
                    if (x != n) x,
                ]),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _c,
                  decoration: InputDecoration(hintText: '${widget.title} 추가'),
                  onSubmitted: (_) => _add(),
                ),
              ),
              IconButton(
                tooltip: '추가',
                icon: const Icon(Icons.add),
                onPressed: _add,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
