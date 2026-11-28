import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/routes.dart';
import '../../ingest/domain/ingest.dart';
import '../../ledger/domain/money_format.dart';
import '../../ledger/presentation/tx_tile.dart';
import '../domain/summary.dart';
import '../../theme/presentation/app_theme.dart';
import 'home_cubit.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => HomeCubit(context.read<IngestDeps>())..load(),
    child: const _HomeView(),
  );
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // 백그라운드에서 알림으로 확정된 거래를 돌아왔을 때 반영한다.
    _lifecycle = AppLifecycleListener(onResume: _reload);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _reload() => context.read<HomeCubit>().load();

  Future<void> _open(String route, [Object? arguments]) async {
    await Navigator.of(context).pushNamed(route, arguments: arguments);
    if (mounted) _reload();
  }

  Future<void> _paste() async {
    final text = await showDialog<String>(
      context: context,
      builder: (_) => const _PasteDialog(),
    );
    if (!mounted || text == null || text.trim().isEmpty) return;
    final result = await context.read<HomeCubit>().addManual(text.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(switch (result) {
          ManualResult.stored => '문자를 저장했어요',
          ManualResult.filtered => '지출 문자가 아니라서 건너뛰었어요',
          ManualResult.failed => '문자를 저장하지 못했어요.',
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('지출 위젯'),
      actions: [
        IconButton(
          tooltip: '설정',
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => _open(AppRoutes.settings),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _paste,
      icon: const Icon(Icons.content_paste),
      label: const Text('문자 붙여넣기'),
    ),
    body: BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        final s = state.summary;
        if (s == null) {
          return Center(
            child: state.loading
                ? const CircularProgressIndicator()
                : const Text('요약을 불러오지 못했어요'),
          );
        }
        return RefreshIndicator(
          onRefresh: () => context.read<HomeCubit>().load(),
          child: _SummaryList(
            summary: s,
            onCandidates: () => _open(AppRoutes.candidates),
            onEdit: (id) => _open(AppRoutes.edit, id),
          ),
        );
      },
    ),
  );
}

class _SummaryList extends StatelessWidget {
  const _SummaryList({
    required this.summary,
    required this.onCandidates,
    required this.onEdit,
  });

  final LedgerSummary summary;
  final VoidCallback onCandidates;
  final void Function(String id) onEdit;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final theme = Theme.of(context);
    final ratio = s.budgetRatio;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        Text('이번 달 지출', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          formatWon(s.periodTotal),
          style: theme.textTheme.displaySmall?.merge(tabularFigures),
        ),
        const SizedBox(height: 4),
        Text(
          s.budget == null
              ? '예산 미설정'
              : '예산 ${formatWon(s.budget!)} 중 '
                    '${ratio == null ? '-' : '${(ratio * 100).round()}%'}',
          style: tabularFigures,
        ),
        const SizedBox(height: 12),
        _ProgressBar(budgetRatio: ratio, elapsedRatio: s.elapsedRatio),
        const SizedBox(height: 4),
        Text(
          '기간 ${s.elapsedDays}/${s.period.totalDays}일 경과',
          style: theme.textTheme.bodySmall?.merge(tabularFigures),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _Stat(label: '오늘 지출', value: formatWon(s.todayTotal)),
            ),
            Expanded(
              child: _Stat(
                label: '하루 권장액',
                value: s.dailyAllowance == null
                    ? '-'
                    : formatWon(s.dailyAllowance!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            onTap: onCandidates,
            leading: Badge(
              isLabelVisible: s.pendingCount > 0,
              label: Text('${s.pendingCount}'),
              child: const Icon(Icons.inbox_outlined),
            ),
            title: Text('확인 대기 ${s.pendingCount}건'),
            trailing: const Icon(Icons.chevron_right),
          ),
        ),
        const SizedBox(height: 16),
        Text('최근 거래', style: theme.textTheme.titleMedium),
        if (s.recent.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('이번 달 포함된 거래가 없어요'),
          ),
        for (final t in s.recent) TxTile(tx: t, onTap: () => onEdit(t.id)),
      ],
    );
  }
}

/// 예산 사용 비율 막대 위에 기간 경과 위치를 세로선으로 표시한다.
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.budgetRatio, required this.elapsedRatio});

  final double? budgetRatio;
  final double elapsedRatio;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final used = (budgetRatio ?? 0).clamp(0.0, 1.0);
    final over = budgetRatio != null && budgetRatio! > elapsedRatio;
    return SizedBox(
      height: 12,
      child: LayoutBuilder(
        builder: (context, box) => Stack(
          children: [
            Positioned.fill(
              child: LinearProgressIndicator(
                value: used,
                minHeight: 12,
                borderRadius: BorderRadius.circular(6),
                color: over ? scheme.error : scheme.primary,
              ),
            ),
            Positioned(
              left: (box.maxWidth * elapsedRatio.clamp(0.0, 1.0)) - 1,
              top: 0,
              bottom: 0,
              child: Container(width: 2, color: scheme.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        Text(value, style: theme.textTheme.titleLarge?.merge(tabularFigures)),
      ],
    );
  }
}

class _PasteDialog extends StatefulWidget {
  const _PasteDialog();

  @override
  State<_PasteDialog> createState() => _PasteDialogState();
}

class _PasteDialogState extends State<_PasteDialog> {
  final TextEditingController _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('문자 붙여넣기'),
    content: TextField(
      controller: _text,
      autofocus: true,
      minLines: 4,
      maxLines: 8,
      keyboardType: TextInputType.multiline,
      decoration: const InputDecoration(
        hintText: '카드·은행 문자 내용을 붙여넣으세요',
        border: OutlineInputBorder(),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('취소'),
      ),
      FilledButton(
        onPressed: () => Navigator.of(context).pop(_text.text),
        child: const Text('추가'),
      ),
    ],
  );
}
