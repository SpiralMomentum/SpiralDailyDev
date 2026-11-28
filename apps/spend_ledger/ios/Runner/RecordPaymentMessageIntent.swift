import AppIntents

/// 단축어 메시지 자동화에서 부르는 동작. 앱을 띄우지 않고 결제 문자를 저장한다.
struct RecordPaymentMessageIntent: AppIntent {
  static var title: LocalizedStringResource = "결제 문자 기록"
  static var openAppWhenRun = false

  @Parameter(title: "메시지")
  var text: String

  @Parameter(title: "보낸 사람")
  var sender: String?

  @MainActor
  func perform() async throws -> some IntentResult {
    await HeadlessIngest.shared.ingest(text: text, sender: sender)
    return .result()
  }
}

struct SpendLedgerShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: RecordPaymentMessageIntent(),
      phrases: ["\(.applicationName)에 결제 문자 기록"],
      shortTitle: "결제 문자 기록",
      systemImageName: "creditcard"
    )
  }
}
