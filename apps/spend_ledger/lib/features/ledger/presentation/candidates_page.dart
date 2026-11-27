import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/routes.dart';
import '../../ingest/domain/ingest.dart';
import '../domain/transaction.dart';
import 'candidates_cubit.dart';
import 'tx_tile.dart';

class CandidatesPage extends StatelessWidget {
  const CandidatesPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => CandidatesCubit(context.read<IngestDeps>())..load(),
    child: const _CandidatesView(),
  );
}

class _CandidatesView extends StatelessWidget {
  const _CandidatesView();

  Future<void> _edit(BuildContext context, String id) async {
    final cubit = context.read<CandidatesCubit>();
    await Navigator.of(context).pushNamed(AppRoutes.edit, arguments: id);
    await cubit.load();
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<CandidatesCubit, CandidatesState>(
        builder: (context, state) {
          final cubit = context.read<CandidatesCubit>();
          return DefaultTabController(
            length: 3,
            child: Scaffold(
              appBar: AppBar(
                title: const Text('후보'),
                bottom: TabBar(
                  tabs: [
                    Tab(text: '확인 대기 ${state.waiting.length}'),
                    Tab(text: '확인 필요 ${state.needsReview.length}'),
                    Tab(text: '자동 제외 ${state.auto.length}'),
                  ],
                ),
              ),
              body: state.loading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      children: [
                        _TxList(
                          txs: state.waiting,
                          empty: '확인할 후보가 없어요',
                          onTap: (t) => _edit(context, t.id),
                          actions: (t) => Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                onPressed: () => cubit.include(t.id),
                                child: const Text('포함'),
                              ),
                              TextButton(
                                onPressed: () => cubit.exclude(t.id),
                                child: const Text('제외'),
                              ),
                            ],
                          ),
                        ),
                        _TxList(
                          txs: state.needsReview,
                          empty: '직접 고칠 문자가 없어요',
                          onTap: (t) => _edit(context, t.id),
                        ),
                        _TxList(
                          txs: state.auto,
                          empty: '최근 90일 동안 자동 제외된 거래가 없어요',
                          onTap: (t) => _edit(context, t.id),
                        ),
                      ],
                    ),
            ),
          );
        },
      );
}

class _TxList extends StatelessWidget {
  const _TxList({
    required this.txs,
    required this.empty,
    required this.onTap,
    this.actions,
  });

  final List<Transaction> txs;
  final String empty;
  final void Function(Transaction) onTap;
  final Widget Function(Transaction)? actions;

  @override
  Widget build(BuildContext context) {
    if (txs.isEmpty) return Center(child: Text(empty));
    return ListView.separated(
      itemCount: txs.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final t = txs[i];
        return TxTile(tx: t, onTap: () => onTap(t), trailing: actions?.call(t));
      },
    );
  }
}
