import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../ingest/domain/ingest.dart';
import '../../ledger/domain/decide.dart';
import '../../ledger/domain/money_format.dart';
import '../../ledger/presentation/tx_labels.dart';
import '../../message_filter/domain/filter.dart';
import '../../message_filter/domain/raw_message.dart';
import '../../settings/domain/app_settings.dart';
import '../../theme/presentation/app_theme.dart';
import '../domain/parsed_message.dart';
import '../domain/parser.dart';

/// 파싱 테스트 결과. 화면에 보이는 문구 그대로의 값이다.
class ParseTestResult {
  const ParseTestResult({
    required this.passed,
    required this.amount,
    required this.kind,
    required this.counterparty,
    required this.occurredAt,
    required this.category,
    required this.notify,
  });

  final bool passed;
  final String amount;
  final String kind;
  final String counterparty;
  final String occurredAt;
  final String category;
  final bool notify;
}

String kindLabel(MessageKind k) => switch (k) {
  MessageKind.approval => '승인',
  MessageKind.withdrawal => '출금',
  MessageKind.transfer => '송금',
  MessageKind.cancel => '취소',
  MessageKind.refund => '환불',
  MessageKind.unknown => '알 수 없음',
};

final DateFormat _full = DateFormat('yyyy.MM.dd HH:mm');

/// 저장 없이 문자를 필터·해석·분류한다. 필터에 걸리면 알림도 보내지 않는다.
ParseTestResult analyzeMessage(
  String text,
  AppSettings settings,
  DateTime now,
) {
  final raw = RawMessage(
    text: text,
    receivedAt: now,
    source: MessageSource.manual,
  );
  final parsed = parseMessage(text, receivedAt: now);
  final decision = decide(
    raw: raw,
    parsed: parsed,
    names: settings.names,
    recent: const [],
    newId: 'parse-test',
  );
  final passed = passesFilter(raw, settings.filters);
  return ParseTestResult(
    passed: passed,
    amount: parsed.amount == null ? '읽지 못함' : formatWon(parsed.amount!),
    kind: kindLabel(parsed.kind),
    counterparty: parsed.counterparty.isEmpty ? '-' : parsed.counterparty,
    occurredAt: _full.format(parsed.occurredAt),
    category: categoryLabel(decision.incoming.category),
    notify: passed && decision.notify,
  );
}

class ParseTestPage extends StatefulWidget {
  const ParseTestPage({super.key});

  @override
  State<ParseTestPage> createState() => _ParseTestPageState();
}

class _ParseTestPageState extends State<ParseTestPage> {
  final TextEditingController _text = TextEditingController();
  ParseTestResult? _result;
  bool _failed = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final deps = context.read<IngestDeps>();
    try {
      final settings = await deps.settings.load();
      if (!mounted) return;
      setState(() {
        _failed = false;
        _result = analyzeMessage(_text.text, settings, deps.now());
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _result;
    return Scaffold(
      appBar: AppBar(title: const Text('파싱 테스트')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _text,
            minLines: 4,
            maxLines: 8,
            keyboardType: TextInputType.multiline,
            decoration: const InputDecoration(
              hintText: '문자 내용을 붙여넣으세요. 저장되지 않아요',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: _run, child: const Text('분석')),
          if (_failed)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text('설정을 불러오지 못했어요'),
            ),
          if (r != null) ...[
            const SizedBox(height: 16),
            _Row('필터', r.passed ? '통과' : '제외'),
            _Row('금액', r.amount),
            _Row('종류', r.kind),
            _Row('상대', r.counterparty),
            _Row('일시', r.occurredAt),
            _Row('분류', r.category),
            _Row('알림', r.notify ? '보냄' : '안 보냄'),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    trailing: Text(value, style: tabularFigures),
  );
}
