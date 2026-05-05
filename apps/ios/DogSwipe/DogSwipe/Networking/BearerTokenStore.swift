import Foundation
import Security

enum BearerTokenStoreError: Error, Equatable {
    case unexpectedStatus(OSStatus)
    case invalidTokenEncoding
}

protocol BearerTokenStoring: Sendable {
    func token() throws -> String?
    func save(_ token: String) throws
    func clear() throws
}

struct KeychainBearerTokenStore: BearerTokenStoring {
    private let service: String
    private let account: String

    init(
        service: String = "com.build000r.dogswipe.auth",
        account: String = "spaps-bearer-token"
    ) {
        self.service = service
        self.account = account
    }

    func token() throws -> String? {
        var query = baseQuery()
        query[kSecReturnData] = true
        query[kSecMatchLimit] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess else {
            throw BearerTokenStoreError.unexpectedStatus(status)
        }
        guard let data = item as? Data else {
            throw BearerTokenStoreError.invalidTokenEncoding
        }
        return String(data: data, encoding: .utf8)
    }

    func save(_ token: String) throws {
        guard let data = token.data(using: .utf8) else {
            throw BearerTokenStoreError.invalidTokenEncoding
        }
        let attributes: [CFString: Any] = [kSecValueData: data]
        let updateStatus = SecItemUpdate(baseQuery() as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess {
            return
        }
        guard updateStatus == errSecItemNotFound else {
            throw BearerTokenStoreError.unexpectedStatus(updateStatus)
        }

        var item = baseQuery()
        item[kSecValueData] = data
        item[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let addStatus = SecItemAdd(item as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw BearerTokenStoreError.unexpectedStatus(addStatus)
        }
    }

    func clear() throws {
        let status = SecItemDelete(baseQuery() as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw BearerTokenStoreError.unexpectedStatus(status)
        }
    }

    private func baseQuery() -> [CFString: Any] {
        [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]
    }
}
