import Foundation
import Security

/// 대체 경로 수신함의 한 항목. 받은 시각·보낸 사람을 함께 둔다.
struct InboxEntry: Codable {
  let id: String
  let text: String
  let sender: String?
  let receivedAtMs: Int64

  /// Dart `InboxItem.fromMap`이 읽는 형태.
  var asMap: [String: Any] {
    ["id": id, "text": text, "sender": sender ?? NSNull(), "receivedAtMs": receivedAtMs]
  }
}

/// 헤드리스 처리에 실패한 원문을 키체인에 보관한다(금융 원문은 평문 저장소에 두지 않는다).
/// 첫 잠금 해제 뒤에는 잠금 상태에서도 읽고 쓸 수 있고, 다른 기기로 옮겨지지 않는다.
/// 앱을 열 때 Dart가 꺼내 저장하고, 저장된 항목만 지운다.
enum InboxStore {
  private static let service = "spend_ledger.inbox"
  private static let account = "pending"
  private static let lock = NSLock()

  /// 기존 항목을 읽지 못하면(알 수 없는 키체인 상태·해석 실패) 덮어쓰지 않고 false.
  @discardableResult
  static func append(_ entry: InboxEntry) -> Bool {
    lock.lock()
    defer { lock.unlock() }
    guard let existing = read() else { return false }
    return write(existing + [entry])
  }

  /// 읽지 못하면 빈 목록. 항목은 그대로 두므로 다음 실행에서 다시 읽는다.
  static func pending() -> [InboxEntry] {
    lock.lock()
    defer { lock.unlock() }
    return read() ?? []
  }

  /// 읽지 못하면 아무것도 지우지 않는다.
  static func remove(ids: Set<String>) {
    guard !ids.isEmpty else { return }
    lock.lock()
    defer { lock.unlock() }
    guard let existing = read() else { return }
    let kept = existing.filter { !ids.contains($0.id) }
    if kept.count != existing.count { write(kept) }
  }

  private static var baseQuery: [String: Any] {
    [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
    ]
  }

  /// 항목이 없으면 빈 목록, 키체인 오류나 해석 실패면 nil.
  private static func read() -> [InboxEntry]? {
    var query = baseQuery
    query[kSecReturnData as String] = true
    query[kSecMatchLimit as String] = kSecMatchLimitOne
    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    if status == errSecItemNotFound { return [] }
    guard status == errSecSuccess, let data = item as? Data else { return nil }
    return try? JSONDecoder().decode([InboxEntry].self, from: data)
  }

  @discardableResult
  private static func write(_ entries: [InboxEntry]) -> Bool {
    guard !entries.isEmpty else {
      let status = SecItemDelete(baseQuery as CFDictionary)
      return status == errSecSuccess || status == errSecItemNotFound
    }
    guard let data = try? JSONEncoder().encode(entries) else { return false }
    let attributes: [String: Any] = [
      kSecValueData as String: data,
      kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
    ]
    let status = SecItemUpdate(baseQuery as CFDictionary, attributes as CFDictionary)
    if status == errSecItemNotFound {
      return SecItemAdd(baseQuery.merging(attributes) { $1 } as CFDictionary, nil) == errSecSuccess
    }
    return status == errSecSuccess
  }
}
