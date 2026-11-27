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

/// 진단 기록과 대체 경로 수신함. 앱 엔진에서 `spend_ledger/diagnostics` 채널로 읽는다.
enum IngestDiagnostics {
  static let channelName = "spend_ledger/diagnostics"
  private static let recordsKey = "ingest_diagnostics"
  private static let inboxKey = "pending_inbox"
  private static let maxRecords = 20
  private static let lock = NSLock()

  private static var defaults: UserDefaults { .standard }

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

  /// 헤드리스 처리에 실패한 원문을 쌓아 둔다. 앱을 열 때 Dart가 꺼내 저장한다.
  static func appendInbox(_ text: String) {
    lock.lock()
    defer { lock.unlock() }
    let inbox = defaults.stringArray(forKey: inboxKey) ?? []
    defaults.set(inbox + [text], forKey: inboxKey)
  }

  /// 쌓인 원문을 모두 꺼내고 비운다.
  static func drainInbox() -> [String] {
    lock.lock()
    defer { lock.unlock() }
    let inbox = defaults.stringArray(forKey: inboxKey) ?? []
    defaults.removeObject(forKey: inboxKey)
    return inbox
  }

  /// 앱 엔진에 `list`, `drainInbox` 채널을 등록한다.
  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "list": result(listJSON())
      case "drainInbox": result(drainInbox())
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
