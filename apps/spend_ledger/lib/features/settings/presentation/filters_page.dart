import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../message_filter/domain/filter_rule.dart';
import 'settings_cubit.dart';

/// 쉼표로 구분한 입력을 키워드 목록으로. 공백은 다듬고 빈 항목은 버린다.
List<String> splitKeywords(String input) => [
  for (final k in input.split(','))
    if (k.trim().isNotEmpty) k.trim(),
];

class FiltersPage extends StatelessWidget {
  const FiltersPage({super.key});

  Future<void> _edit(
    BuildContext context,
    List<FilterRule> rules,
    int? index,
  ) async {
    final result = await showDialog<FilterRule>(
      context: context,
      builder: (_) => _RuleDialog(initial: index == null ? null : rules[index]),
    );
    if (result == null || !context.mounted) return;
    final next = [...rules];
    if (index == null) {
      next.add(result);
    } else {
      next[index] = result;
    }
    await context.read<SettingsCubit>().saveFilters(next);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('문자 필터'),
      actions: [
        TextButton(
          onPressed: () =>
              context.read<SettingsCubit>().saveFilters(defaultFilterRules),
          child: const Text('기본값으로 되돌리기'),
        ),
      ],
    ),
    floatingActionButton: BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) => FloatingActionButton.extended(
        onPressed: () => _edit(context, state.settings.filters, null),
        icon: const Icon(Icons.add),
        label: const Text('규칙 추가'),
      ),
    ),
    body: BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        final rules = state.settings.filters;
        if (rules.isEmpty) {
          return const Center(child: Text('규칙이 없어요. 모든 문자를 받아요'));
        }
        return ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            for (var i = 0; i < rules.length; i++)
              ListTile(
                onTap: () => _edit(context, rules, i),
                title: Text(
                  rules[i].senderPattern == null
                      ? '모든 발신자'
                      : '발신자 ${rules[i].senderPattern}',
                ),
                subtitle: Text(
                  '포함: ${rules[i].includeKeywords.join(', ')}\n'
                  '제외: ${rules[i].excludeKeywords.join(', ')}',
                ),
                isThreeLine: true,
                trailing: IconButton(
                  tooltip: '삭제',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => context.read<SettingsCubit>().saveFilters([
                    for (var j = 0; j < rules.length; j++)
                      if (j != i) rules[j],
                  ]),
                ),
              ),
          ],
        );
      },
    ),
  );
}

class _RuleDialog extends StatefulWidget {
  const _RuleDialog({this.initial});

  final FilterRule? initial;

  @override
  State<_RuleDialog> createState() => _RuleDialogState();
}

class _RuleDialogState extends State<_RuleDialog> {
  late final TextEditingController _sender = TextEditingController(
    text: widget.initial?.senderPattern ?? '',
  );
  late final TextEditingController _include = TextEditingController(
    text: widget.initial?.includeKeywords.join(', ') ?? '',
  );
  late final TextEditingController _exclude = TextEditingController(
    text: widget.initial?.excludeKeywords.join(', ') ?? '',
  );

  @override
  void dispose() {
    _sender.dispose();
    _include.dispose();
    _exclude.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('필터 규칙'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _sender,
            decoration: const InputDecoration(
              labelText: '발신자 (선택)',
              helperText: '비우면 모든 발신자',
            ),
          ),
          TextField(
            controller: _include,
            decoration: const InputDecoration(
              labelText: '포함 키워드',
              helperText: '쉼표로 구분',
            ),
          ),
          TextField(
            controller: _exclude,
            decoration: const InputDecoration(
              labelText: '제외 키워드',
              helperText: '쉼표로 구분',
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('취소'),
      ),
      FilledButton(
        onPressed: () {
          final sender = _sender.text.trim();
          Navigator.of(context).pop(
            FilterRule(
              senderPattern: sender.isEmpty ? null : sender,
              includeKeywords: splitKeywords(_include.text),
              excludeKeywords: splitKeywords(_exclude.text),
            ),
          );
        },
        child: const Text('저장'),
      ),
    ],
  );
}
