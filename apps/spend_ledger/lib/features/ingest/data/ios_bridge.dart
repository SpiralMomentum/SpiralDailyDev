import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';

import '../../message_filter/domain/raw_message.dart';

/// iOS 앱 엔진에 등록된 진단·수신함 채널. Android에는 없다.
const MethodChannel iosDiagnosticsChannel = MethodChannel(
  'spend_ledger/diagnostics',
);

/// iOS 대체 경로 수신함의 한 항목. Swift가 키체인에 보관한다.
class InboxItem extends Equatable {
  const InboxItem({
    required this.id,
    required this.text,
    required this.sender,
    required this.receivedAt,
  });

  /// `{id, text, sender?, receivedAtMs}`
  factory InboxItem.fromMap(Map<Object?, Object?> m) => InboxItem(
    id: m['id']! as String,
    text: m['text']! as String,
    sender: m['sender'] as String?,
    receivedAt: DateTime.fromMillisecondsSinceEpoch(
      (m['receivedAtMs']! as num).toInt(),
    ),
  );

  final String id;
  final String text;
  final String? sender;
  final DateTime receivedAt;

  /// 받은 시각·보낸 사람을 그대로 둔 단축어 문자.
  RawMessage toRawMessage() => RawMessage(
    text: text,
    sender: sender,
    receivedAt: receivedAt,
    source: MessageSource.iosShortcut,
  );

  @override
  List<Object?> get props => [id, text, sender, receivedAt];
}

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
