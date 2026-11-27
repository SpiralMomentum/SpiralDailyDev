import Flutter
import Foundation
import UserNotifications

/// 앱을 열지 않고 헤드리스 FlutterEngine에서 Dart 수집 파이프라인을 실행한다.
/// 엔진은 프로세스마다 하나만 만들어 재사용한다. 준비·응답이 늦거나 실패하면
/// 원문을 수신함에 넣고 금액만 담은 알림을 보낸다(대체 경로).
@MainActor
final class HeadlessIngest {
  static let shared = HeadlessIngest()

  private static let channelName = "spend_ledger/ingest"
  private static let entrypoint = "iosIngestMain"
  private static let readyTimeout: TimeInterval = 10
  private static let ingestTimeout: TimeInterval = 15
  private static let amountPattern = #"(\d{1,3}(,\d{3})+|\d+)\s*원"#

  private var engine: FlutterEngine?
  private var channel: FlutterMethodChannel?
  private var isReady = false
  private var readyWaiters: [(Bool) -> Void] = []

  private init() {}

  /// Dart 응답.
  private enum Reply {
    case value([String: Any])
    case failure(String)
    case timeout
  }

  func ingest(text: String, sender: String?) async {
    let start = Date()
    let ready = await waitUntilReady()
    let engineMs = Self.ms(since: start)
    guard ready, let channel else {
      await fallback(text: text, start: start, engineMs: engineMs, result: "ready-timeout")
      return
    }
    let reply = await call(channel, text: text, sender: sender)
    switch reply {
    case .value(let map):
      let result = map["result"] as? String ?? "unknown"
      let dartMs = (map["dartMs"] as? NSNumber)?.intValue
      if result == "error" {
        let message = map["error"] as? String ?? ""
        await fallback(
          text: text, start: start, engineMs: engineMs, dartMs: dartMs,
          result: "error: \(message)")
        return
      }
      IngestDiagnostics.record(
        IngestRecord(
          at: Self.epochMs(start), path: "headless", engineMs: engineMs,
          dartMs: dartMs, totalMs: Self.ms(since: start), result: result))
    case .failure(let message):
      await fallback(text: text, start: start, engineMs: engineMs, result: "error: \(message)")
    case .timeout:
      await fallback(text: text, start: start, engineMs: engineMs, result: "ingest-timeout")
    }
  }

  // MARK: - 엔진

  private func waitUntilReady() async -> Bool {
    if isReady { return true }
    startEngineIfNeeded()
    guard engine != nil else { return false }
    return await Self.awaitCallback(timeout: Self.readyTimeout, timeoutValue: false) { finish in
      readyWaiters.append(finish)
    }
  }

  private func startEngineIfNeeded() {
    guard engine == nil else { return }
    let engine = FlutterEngine(name: "ingest", project: nil, allowHeadlessExecution: true)
    let channel = FlutterMethodChannel(
      name: Self.channelName, binaryMessenger: engine.binaryMessenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "ready" else {
        result(FlutterMethodNotImplemented)
        return
      }
      MainActor.assumeIsolated { self?.markReady() }
      result(nil)
    }
    guard engine.run(withEntrypoint: Self.entrypoint) else { return }
    GeneratedPluginRegistrant.register(with: engine)
    self.engine = engine
    self.channel = channel
  }

  private func markReady() {
    isReady = true
    let waiters = readyWaiters
    readyWaiters = []
    waiters.forEach { $0(true) }
  }

  private func call(_ channel: FlutterMethodChannel, text: String, sender: String?) async -> Reply {
    let args: [String: Any] = ["text": text, "sender": sender ?? NSNull()]
    return await Self.awaitCallback(timeout: Self.ingestTimeout, timeoutValue: .timeout) { finish in
      channel.invokeMethod("ingest", arguments: args) { response in
        if let error = response as? FlutterError {
          finish(.failure(error.message ?? error.code))
        } else if let map = response as? [String: Any] {
          finish(.value(map))
        } else {
          finish(.failure("unexpected reply"))
        }
      }
    }
  }

  // MARK: - 대체 경로

  private func fallback(
    text: String, start: Date, engineMs: Int, dartMs: Int? = nil, result: String
  ) async {
    IngestDiagnostics.appendInbox(text)
    let content = UNMutableNotificationContent()
    content.body = Self.fallbackBody(text)
    let request = UNNotificationRequest(
      identifier: UUID().uuidString, content: content, trigger: nil)
    try? await UNUserNotificationCenter.current().add(request)
    IngestDiagnostics.record(
      IngestRecord(
        at: Self.epochMs(start), path: "fallback", engineMs: engineMs,
        dartMs: dartMs, totalMs: Self.ms(since: start), result: result))
  }

  static func fallbackBody(_ text: String) -> String {
    guard let amount = amount(in: text) else {
      return "결제 문자가 왔어요. 앱에서 확인해 주세요."
    }
    return "\(amount)원 결제 문자가 왔어요. 앱에서 확인해 주세요."
  }

  /// 원문에서 처음 나오는 `N원`의 숫자 부분.
  static func amount(in text: String) -> String? {
    guard let regex = try? NSRegularExpression(pattern: amountPattern),
      let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
      let range = Range(match.range(at: 1), in: text)
    else { return nil }
    return String(text[range])
  }

  // MARK: - 보조

  /// 콜백 기반 호출을 기다린다. 제한 시간이 지나면 [timeoutValue]로 끝낸다.
  /// 먼저 도착한 값만 쓰고 나머지는 버린다. 모든 콜백은 메인 스레드에서 불린다.
  private static func awaitCallback<T>(
    timeout: TimeInterval, timeoutValue: T, start: (@escaping (T) -> Void) -> Void
  ) async -> T {
    await withCheckedContinuation { (continuation: CheckedContinuation<T, Never>) in
      var done = false
      let finish: (T) -> Void = { value in
        guard !done else { return }
        done = true
        continuation.resume(returning: value)
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + timeout) { finish(timeoutValue) }
      start(finish)
    }
  }

  private static func ms(since start: Date) -> Int {
    Int((Date().timeIntervalSince(start) * 1000).rounded())
  }

  private static func epochMs(_ date: Date) -> Int64 {
    Int64((date.timeIntervalSince1970 * 1000).rounded())
  }
}
