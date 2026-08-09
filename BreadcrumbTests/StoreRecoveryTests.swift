import Testing
import Foundation
@testable import Breadcrumb

@Suite("Store Recovery")
@MainActor
struct StoreRecoveryTests {

    private func makeTempStoreDirectory() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appending(path: "StoreRecoveryTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    @Test("Moves store and sidecars to a timestamped backup")
    func movesAllStoreFiles() throws {
        let fm = FileManager.default
        let dir = try makeTempStoreDirectory()
        defer { try? fm.removeItem(at: dir) }
        for suffix in ["", "-wal", "-shm"] {
            fm.createFile(
                atPath: dir.appending(path: "Breadcrumb.store\(suffix)").path(percentEncoded: false),
                contents: Data("junk".utf8)
            )
        }

        let storeURL = dir.appending(path: "Breadcrumb.store")
        let backupBase = try #require(BreadcrumbApp.moveIncompatibleStoreAside(at: storeURL))

        #expect(backupBase.hasPrefix("Breadcrumb.store.backup-"))
        for suffix in ["", "-wal", "-shm"] {
            #expect(!fm.fileExists(atPath: dir.appending(path: "Breadcrumb.store\(suffix)").path(percentEncoded: false)))
            #expect(fm.fileExists(atPath: dir.appending(path: "\(backupBase)\(suffix)").path(percentEncoded: false)))
        }
    }

    @Test("Moves the main store even when sidecar files are absent")
    func movesStoreWithoutSidecars() throws {
        let fm = FileManager.default
        let dir = try makeTempStoreDirectory()
        defer { try? fm.removeItem(at: dir) }
        fm.createFile(
            atPath: dir.appending(path: "Breadcrumb.store").path(percentEncoded: false),
            contents: Data("junk".utf8)
        )

        let backupBase = try #require(
            BreadcrumbApp.moveIncompatibleStoreAside(at: dir.appending(path: "Breadcrumb.store"))
        )

        #expect(!fm.fileExists(atPath: dir.appending(path: "Breadcrumb.store").path(percentEncoded: false)))
        #expect(fm.fileExists(atPath: dir.appending(path: backupBase).path(percentEncoded: false)))
    }

    @Test("Returns nil when no store files exist")
    func returnsNilWithoutStore() throws {
        let fm = FileManager.default
        let dir = try makeTempStoreDirectory()
        defer { try? fm.removeItem(at: dir) }

        #expect(BreadcrumbApp.moveIncompatibleStoreAside(at: dir.appending(path: "Breadcrumb.store")) == nil)
    }
}
