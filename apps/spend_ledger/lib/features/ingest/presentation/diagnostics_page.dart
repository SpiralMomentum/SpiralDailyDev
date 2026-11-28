import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/ios_bridge.dart';

final DateFormat _time = DateFormat('MM/dd HH:mm:ss');

/// 문자·알림 수집 기록(iOS 단축어, Android 알림 리스너). 최신 기록부터 단계별 소요 시간을 보여 준다.
class DiagnosticsPage extends StatefulWidget {
  const DiagnosticsPage({super.key, this.load = loadDiagnostics});

  final Future<List<IngestDiagnostic>> Function() load;

  @override
  State<DiagnosticsPage> createState() => _DiagnosticsPageState();
}

class _DiagnosticsPageState extends State<DiagnosticsPage> {
  late final Future<List<IngestDiagnostic>> _records = widget.load();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('수집 진단')),
    body: FutureBuilder<List<IngestDiagnostic>>(
      future: _records,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('기록을 불러오지 못했어요'));
        }
        final records = snapshot.data;
        if (records == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (records.isEmpty) {
          return const Center(child: Text('기록이 없어요'));
        }
        return ListView.separated(
          itemCount: records.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (_, i) => _RecordTile(records[i]),
        );
      },
    ),
  );
}

class _RecordTile extends StatelessWidget {
  const _RecordTile(this.r);

  final IngestDiagnostic r;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text('${_time.format(r.at)} · 경로 ${r.path} · ${r.result}'),
    subtitle: Text(
      'engineMs ${r.engineMs} · dartMs ${r.dartMs ?? '-'} · '
      'totalMs ${r.totalMs}',
    ),
  );
}
