import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../ingest/domain/ingest.dart';
import '../domain/transaction.dart';
import 'edit_cubit.dart';
import 'tx_labels.dart';
import 'tx_tile.dart';

/// 거래 수정 화면. 거래를 id로 읽은 뒤 수정 폼을 연다.
class EditPage extends StatefulWidget {
  const EditPage({super.key, required this.id});

  final String id;

  @override
  State<EditPage> createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  late final Future<Transaction?> _tx = context.read<IngestDeps>().ledger.byId(
    widget.id,
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('거래 수정')),
    body: FutureBuilder<Transaction?>(
      future: _tx,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final tx = snap.data;
        if (tx == null) {
          return const Center(child: Text('거래를 찾을 수 없어요'));
        }
        return BlocProvider(
          create: (context) => EditCubit(context.read<IngestDeps>(), tx),
          child: _EditForm(tx: tx),
        );
      },
    ),
  );
}

class _EditForm extends StatefulWidget {
  const _EditForm({required this.tx});

  final Transaction tx;

  @override
  State<_EditForm> createState() => _EditFormState();
}

class _EditFormState extends State<_EditForm> {
  late final TextEditingController _amount = TextEditingController(
    text: widget.tx.amount == 0 ? '' : '${widget.tx.amount.abs()}',
  );
  late final TextEditingController _counterparty = TextEditingController(
    text: widget.tx.counterparty,
  );
  late DateTime _occurredAt = widget.tx.occurredAt;
  late SpendCategory _category = widget.tx.category;
  late bool _include = widget.tx.status != TxStatus.excluded;

  @override
  void dispose() {
    _amount.dispose();
    _counterparty.dispose();
    super.dispose();
  }

  Future<void> _pickWhen() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_occurredAt),
    );
    if (!mounted) return;
    final t = time ?? TimeOfDay.fromDateTime(_occurredAt);
    setState(
      () => _occurredAt = DateTime(
        date.year,
        date.month,
        date.day,
        t.hour,
        t.minute,
      ),
    );
  }

  void _save() {
    final abs = int.tryParse(_amount.text) ?? 0;
    context.read<EditCubit>().save(
      amount: signedAmount(abs, _category, original: widget.tx.amount),
      counterparty: _counterparty.text.trim(),
      occurredAt: _occurredAt,
      category: _category,
      include: _include,
    );
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<EditCubit, EditState>(
    listenWhen: (a, b) => (!a.saved && b.saved) || (!a.failed && b.failed),
    listener: (context, state) {
      if (state.saved) {
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('저장하지 못했어요. 다시 시도해 주세요.')));
      }
    },
    builder: (context, state) {
      final enabled = state.editable && !state.saving;
      final raw = widget.tx.rawText;
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!state.editable)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                '${statusLabel(widget.tx.status)} 거래는 고칠 수 없어요',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          TextField(
            controller: _amount,
            enabled: enabled,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: tabularFigures,
            decoration: InputDecoration(
              labelText: _category == SpendCategory.refund ? '환불 금액' : '금액',
              suffixText: '원',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _counterparty,
            enabled: enabled,
            decoration: const InputDecoration(labelText: '사용처'),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            enabled: enabled,
            title: const Text('일시'),
            subtitle: Text(formatWhen(_occurredAt), style: tabularFigures),
            trailing: const Icon(Icons.edit_calendar_outlined),
            onTap: _pickWhen,
          ),
          DropdownButtonFormField<SpendCategory>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: '분류'),
            items: [
              for (final c in SpendCategory.values)
                DropdownMenuItem(value: c, child: Text(categoryLabel(c))),
            ],
            onChanged: enabled
                ? (c) => setState(() => _category = c ?? _category)
                : null,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('지출에 포함'),
            subtitle: const Text('금액이 있어야 포함돼요'),
            value: _include,
            onChanged: enabled ? (v) => setState(() => _include = v) : null,
          ),
          if (raw != null) ...[
            const SizedBox(height: 12),
            Text('원문', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            SelectableText(raw),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: enabled ? _save : null,
            child: const Text('저장'),
          ),
        ],
      );
    },
  );
}
