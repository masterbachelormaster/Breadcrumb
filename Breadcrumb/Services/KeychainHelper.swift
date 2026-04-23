import Foundation
import os
import Security

enum KeychainBackend: String, Sendable {
    case dataProtection
    case fileBased

    var other: KeychainBackend {
        switch self {
        case .dataProtection:
            return .fileBased
        case .fileBased:
            return .dataProtection
        }
    }
}

struct KeychainOperationResult: Sendable {
    let succeeded: Bool
    let status: OSStatus
    let backend: KeychainBackend
}

enum KeychainHelper {

    private static let service = "com.roger.breadcrumb"
    private static let logger = Logger(subsystem: "com.roger.breadcrumb", category: "Keychain")

    private static let preferredBackends: [KeychainBackend] = [
        .dataProtection,
        .fileBased,
    ]

    private static func baseQuery(account: String, backend: KeychainBackend) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        if backend == .dataProtection {
            query[kSecUseDataProtectionKeychain as String] = true
        }
        return query
    }

    @discardableResult
    static func save(key: String, value: String) -> Bool {
        saveResult(key: key, value: value).succeeded
    }

    @discardableResult
    static func saveResult(key: String, value: String) -> KeychainOperationResult {
        guard let data = value.data(using: .utf8) else {
            return KeychainOperationResult(
                succeeded: false,
                status: errSecParam,
                backend: .dataProtection
            )
        }

        var lastResult = KeychainOperationResult(
            succeeded: false,
            status: errSecParam,
            backend: .dataProtection
        )

        for backend in preferredBackends {
            let result = save(key: key, data: data, backend: backend)
            if result.succeeded {
                cleanUpOtherBackend(key: key, keeping: backend)
                return result
            }
            logFailure(operation: "save", status: result.status, backend: backend)
            lastResult = result
        }

        return lastResult
    }

    static func read(key: String) -> String? {
        for backend in preferredBackends {
            let result = read(key: key, backend: backend)
            if result.status == errSecSuccess {
                return result.value
            }
            if result.status != errSecItemNotFound {
                logFailure(operation: "read", status: result.status, backend: backend)
            }
        }
        return nil
    }

    @discardableResult
    static func delete(key: String) -> Bool {
        preferredBackends
            .map { backend in
                let status = delete(key: key, backend: backend)
                if !isNonfatalDeleteStatus(status) {
                    logFailure(operation: "delete", status: status, backend: backend)
                }
                return isNonfatalDeleteStatus(status)
            }
            .allSatisfy { $0 }
    }

    private static func save(key: String, data: Data, backend: KeychainBackend) -> KeychainOperationResult {
        let query = baseQuery(account: key, backend: backend)
        let attributes: [String: Any] = [
            kSecValueData as String: data,
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess {
            return KeychainOperationResult(
                succeeded: true,
                status: updateStatus,
                backend: backend
            )
        }

        var addQuery = query
        addQuery[kSecValueData as String] = data
        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        return KeychainOperationResult(
            succeeded: addStatus == errSecSuccess,
            status: addStatus,
            backend: backend
        )
    }

    private static func read(key: String, backend: KeychainBackend) -> (value: String?, status: OSStatus) {
        var query = baseQuery(account: key, backend: backend)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            return (nil, status)
        }
        return (String(data: data, encoding: .utf8), status)
    }

    @discardableResult
    private static func delete(key: String, backend: KeychainBackend) -> OSStatus {
        SecItemDelete(baseQuery(account: key, backend: backend) as CFDictionary)
    }

    private static func cleanUpOtherBackend(key: String, keeping backend: KeychainBackend) {
        let other = backend.other
        let status = delete(key: key, backend: other)
        if !isNonfatalDeleteStatus(status) {
            logFailure(operation: "cleanup", status: status, backend: other)
        }
    }

    private static func isNonfatalDeleteStatus(_ status: OSStatus) -> Bool {
        status == errSecSuccess
            || status == errSecItemNotFound
            || status == errSecMissingEntitlement
    }

    private static func logFailure(operation: String, status: OSStatus, backend: KeychainBackend) {
        #if DEBUG
        logger.debug("Keychain \(operation, privacy: .public) failed in \(backend.rawValue, privacy: .public): \(status)")
        #endif
    }

    #if DEBUG
    @discardableResult
    static func saveForTesting(key: String, value: String, backend: KeychainBackend) -> KeychainOperationResult {
        guard let data = value.data(using: .utf8) else {
            return KeychainOperationResult(
                succeeded: false,
                status: errSecParam,
                backend: backend
            )
        }
        return save(key: key, data: data, backend: backend)
    }

    static func readForTesting(key: String, backend: KeychainBackend) -> String? {
        read(key: key, backend: backend).value
    }
    #endif
}
