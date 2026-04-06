import Testing
@testable import Breadcrumb

@Suite("KeychainHelper Tests", .serialized)
struct KeychainHelperTests {

    private let testKey = "com.roger.breadcrumb.test.keychainHelper"

    @Test("Save and read a value")
    func saveAndRead() {
        KeychainHelper.delete(key: testKey)

        let saved = KeychainHelper.save(key: testKey, value: "test-api-key-123")
        #expect(saved)

        let retrieved = KeychainHelper.read(key: testKey)
        #expect(retrieved == "test-api-key-123")

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
}
