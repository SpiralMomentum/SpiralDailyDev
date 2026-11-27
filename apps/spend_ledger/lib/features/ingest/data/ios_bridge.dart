import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';

/// iOS 앱 엔진에 등록된 진단·수신함 채널. Android에는 없다.
const MethodChannel iosDiagnosticsChannel = MethodChannel(
  'spend_ledger/diagnostics',
);

/// 단축어 수집 한 건의 단계별 소요 시간. Swift `IngestDiagnostics`가 기록한다.
class IngestDiagnostic extends Equatable {
  const IngestDiagnostic({
    required this.at,
    required this.path,
    required this.engineMs,
    required this.dartMs,
    required this.totalMs,
    required this.result,
  });

  factory IngestDiagnostic.fromJson(Map<String, Object?> j) => IngestDiagnostic(
    at: DateTime.fromMillisecondsSinceEpoch((j['at']! as num).toInt()),
    path: j['path']! as String,
    engineMs: (j['engineMs']! as num).toInt(),
    dartMs: (j['dartMs'] as num?)?.toInt(),
    totalMs: (j['totalMs']! as num).toInt(),
    result: j['result']! as String,
  );

  final DateTime at;

  /// `headless` 또는 `fallback`.
  final String path;
  final int engineMs;

  /// Dart가 응답하지 않았으면 null.
  final int? dartMs;
  final int totalMs;
  final String result;

  @override
  List<Object?> get props => [at, path, engineMs, dartMs, totalMs, result];
}

/// JSON 배열을 읽어 최신 기록부터 돌려준다.
List<IngestDiagnostic> parseDiagnostics(String json) =>
    (jsonDecode(json) as List<Object?>)
        .map((e) => IngestDiagnostic.fromJson(e! as Map<String, Object?>))
        .toList()
      ..sort((a, b) => b.at.compareTo(a.at));

/// 저장된 진단 기록. 채널이 없는 플랫폼에서는 빈 목록이다.
Future<List<IngestDiagnostic>> loadDiagnostics({
  MethodChannel channel = iosDiagnosticsChannel,
}) async {
  try {
    final json = await channel.invokeMethod<String>('list');
    return json == null ? const [] : parseDiagnostics(json);
  } on MissingPluginException {
    return const [];
  }
}
