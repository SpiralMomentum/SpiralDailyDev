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

  static func append(_ entry: InboxEntry) {
    lock.lock()
    defer { lock.unlock() }
    write(read() + [entry])
  }

  static func pending() -> [InboxEntry] {
    lock.lock()
    defer { lock.unlock() }
    return read()
  }

  static func remove(ids: Set<String>) {
    guard !ids.isEmpty else { return }
    lock.lock()
    defer { lock.unlock() }
    write(read().filter { !ids.contains($0.id) })
  }

  private static var baseQuery: [String: Any] {
    [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
    ]
  }

  private static func read() -> [InboxEntry] {
    var query = baseQuery
    query[kSecReturnData as String] = true
    query[kSecMatchLimit as String] = kSecMatchLimitOne
    var item: CFTypeRef?
    guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
      let data = item as? Data,
      let entries = try? JSONDecoder().decode([InboxEntry].self, from: data)
    else { return [] }
    return entries
  }

  private static func write(_ entries: [InboxEntry]) {
    guard !entries.isEmpty else {
      SecItemDelete(baseQuery as CFDictionary)
      return
    }
    guard let data = try? JSONEncoder().encode(entries) else { return }
    let attributes: [String: Any] = [
      kSecValueData as String: data,
      kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
    ]
    let status = SecItemUpdate(baseQuery as CFDictionary, attributes as CFDictionary)
    if status == errSecItemNotFound {
      SecItemAdd(baseQuery.merging(attributes) { $1 } as CFDictionary, nil)
    }
  }
}
