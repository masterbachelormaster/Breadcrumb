import Testing
import Security
@testable import Breadcrumb

@Suite("KeychainHelper Tests", .serialized)
struct KeychainHelperTests {

    private let testKey = "com.roger.breadcrumb.test.keychainHelper"
    private let crossBackendKey = "com.roger.breadcrumb.test.crossBackendCleanup"

    @Test("Save and read a value")
    func saveAndRead() {
        KeychainHelper.delete(key: testKey)

        let saved = KeychainHelper.save(key: testKey, value: "test-api-key-123")
        #expect(saved)

        let retrieved = KeychainHelper.read(key: testKey)
        #expect(retrieved == "test-api-key-123")

        KeychainHelper.delete(key: testKey)
    }

    @Test("saveResult reports successful backend")
    func saveResultReportsSuccess() {
        KeychainHelper.delete(key: testKey)

        let result = KeychainHelper.saveResult(key: testKey, value: "test-api-key-123")

        #expect(result.succeeded)
        #expect(result.status == errSecSuccess)
        #expect(KeychainHelper.read(key: testKey) == "test-api-key-123")

        KeychainHelper.delete(key: testKey)
    }

    @Test("Read returns nil for missing key")
    func readMissing() {
        KeychainHelper.delete(key: testKey)
        let result = KeychainHelper.read(key: testKey)
        #expect(result == nil)
    }

    @Test("Save overwrites existing value")
    func saveOverwrites() {
        KeychainHelper.delete(key: testKey)

        _ = KeychainHelper.save(key: testKey, value: "first")
        _ = KeychainHelper.save(key: testKey, value: "second")

        let result = KeychainHelper.read(key: testKey)
        #expect(result == "second")

        KeychainHelper.delete(key: testKey)
    }

    @Test("Delete removes the value")
    func deleteKey() {
        _ = KeychainHelper.save(key: testKey, value: "to-delete")
        KeychainHelper.delete(key: testKey)

        let result = KeychainHelper.read(key: testKey)
        #expect(result == nil)
    }

    @Test("Delete succeeds when value is missing")
    func deleteMissingKey() {
        KeychainHelper.delete(key: testKey)

        let deleted = KeychainHelper.delete(key: testKey)

        #expect(deleted)
    }

    @Test("Successful save cleans up stale value in the other backend")
    func saveCleansUpOtherBackend() throws {
        KeychainHelper.delete(key: crossBackendKey)

        let dataProtectionSeed = KeychainHelper.saveForTesting(
            key: crossBackendKey,
            value: "stale-data-protection",
            backend: .dataProtection
        )
        let fileBasedSeed = KeychainHelper.saveForTesting(
            key: crossBackendKey,
            value: "stale-file-based",
            backend: .fileBased
        )

        guard dataProtectionSeed.succeeded, fileBasedSeed.succeeded else {
            KeychainHelper.delete(key: crossBackendKey)
            return
        }

        let saved = KeychainHelper.saveResult(key: crossBackendKey, value: "fresh")
        #expect(saved.succeeded)
        #expect(KeychainHelper.readForTesting(key: crossBackendKey, backend: saved.backend) == "fresh")
        #expect(KeychainHelper.readForTesting(key: crossBackendKey, backend: saved.backend.other) == nil)

        KeychainHelper.delete(key: crossBackendKey)
    }
}
