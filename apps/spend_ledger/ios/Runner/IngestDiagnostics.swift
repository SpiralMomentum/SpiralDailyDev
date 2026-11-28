import Flutter
import Foundation

/// 단축어 수집 한 건의 단계별 소요 시간.
struct IngestRecord: Codable {
  /// 시작 시각(epoch ms).
  let at: Int64
  /// "headless" 또는 "fallback".
  let path: String
  let engineMs: Int
  /// Dart가 응답하지 않았으면 nil.
  let dartMs: Int?
  let totalMs: Int
  let result: String
}

/// 진단 기록. 대체 경로 수신함(`InboxStore`)과 함께 앱 엔진에서 `spend_ledger/diagnostics` 채널로 읽는다.
enum IngestDiagnostics {
  static let channelName = "spend_ledger/diagnostics"
  private static let recordsKey = "ingest_diagnostics"
  private static let maxRecords = 20
  private static let lock = NSLock()

  private static var defaults: UserDefaults { .standard }

  /// 기록에 남길 결과 문자열. 원문이나 예외 메시지는 넣지 않는다.
  static func errorResult(_ type: String) -> String { "error:\(type)" }

  /// 최근 20건만 남기고 최신 기록을 앞에 둔다.
  static func record(_ r: IngestRecord) {
    lock.lock()
    defer { lock.unlock() }
    let records = Array(([r] + loadRecords()).prefix(maxRecords))
    if let data = try? JSONEncoder().encode(records) {
      defaults.set(String(decoding: data, as: UTF8.self), forKey: recordsKey)
    }
  }

  /// 저장된 기록의 JSON 배열 문자열.
  static func listJSON() -> String {
    lock.lock()
    defer { lock.unlock() }
    return defaults.string(forKey: recordsKey) ?? "[]"
  }

  /// 앱 엔진에 `list`, `drainInbox`, `ackInbox` 채널을 등록한다.
  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "list": result(listJSON())
      case "drainInbox": result(InboxStore.pending().map { $0.asMap })
      case "ackInbox":
        let ids = (call.arguments as? [String: Any])?["ids"] as? [String] ?? []
        InboxStore.remove(ids: Set(ids))
        result(nil)
      default: result(FlutterMethodNotImplemented)
      }
    }
  }

  private static func loadRecords() -> [IngestRecord] {
    guard let json = defaults.string(forKey: recordsKey),
      let records = try? JSONDecoder().decode([IngestRecord].self, from: Data(json.utf8))
    else { return [] }
    return records
  }
}
