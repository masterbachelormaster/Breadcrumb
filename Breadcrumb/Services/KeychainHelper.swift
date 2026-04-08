import Foundation
import Security

enum KeychainHelper {

    private static let service = "com.roger.breadcrumb"

    /// Base attributes used by every query. `kSecUseDataProtectionKeychain`
    /// switches us from the legacy file-based keychain (which gates access
    /// by *code signature* and prompts the user every time the dev build is
    /// re-signed) to the data protection keychain (which gates access by
    /// *bundle identifier* and never prompts on rebuild).
    private static func baseQuery(account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecUseDataProtectionKeychain as String: true,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }

    @discardableResult
    static func save(key: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        let query = baseQuery(account: key)
        let attributes: [String: Any] = [
            kSecValueData as String: data,
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess { return true }

        var addQuery = query
        addQuery[kSecValueData as String] = data
        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        return addStatus == errSecSuccess
    }

    static func read(key: String) -> String? {
        var query = baseQuery(account: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    @discardableResult
    static func delete(key: String) -> Bool {
        return SecItemDelete(baseQuery(account: key) as CFDictionary) == errSecSuccess
    }
}
