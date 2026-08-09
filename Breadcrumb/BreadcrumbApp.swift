import AppKit
import SwiftUI
import SwiftData
import SQLite3

@main
struct BreadcrumbApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // The menu bar item (status item + popover) is owned by AppDelegate /
        // MenuBarController — see MenuBarController.swift for why MenuBarExtra
        // can't be used on macOS 27. These scenes are the breakout windows; they
        // open on demand via WindowManager, never at launch.

        Window("Breadcrumb", id: "main") {
            BreakoutWindowView()
                .environment(appDelegate.pomodoroTimer)
                .environment(appDelegate.windowManager)
                .environment(appDelegate.aiService)
                .environment(appDelegate.aiExtractionCoordinator)
                .environment(appDelegate.languageManager)
                .environment(appDelegate.speechRecognizer)
        }
        .modelContainer(appDelegate.modelContainer)
        .defaultSize(width: 500, height: 400)
        .defaultLaunchBehavior(.suppressed)
        .commands {
            BreadcrumbCommands(windowManager: appDelegate.windowManager, languageManager: appDelegate.languageManager)
        }

        Settings {
            SettingsRootView()
                .environment(appDelegate.windowManager)
                .environment(appDelegate.aiService)
                .environment(appDelegate.languageManager)
        }
        .windowResizability(.contentSize)

        Window("Session Complete", id: "session-end") {
            SessionEndWindowView()
                .environment(appDelegate.pomodoroTimer)
                .environment(appDelegate.windowManager)
                .environment(appDelegate.aiService)
                .environment(appDelegate.aiExtractionCoordinator)
                .environment(appDelegate.languageManager)
                .environment(appDelegate.speechRecognizer)
        }
        .modelContainer(appDelegate.modelContainer)
        .defaultSize(width: 360, height: 420)
        .defaultLaunchBehavior(.suppressed)
    }

    // MARK: - Model Container

    static func createModelContainer() -> ModelContainer {
        let storeURL = URL.applicationSupportDirectory
            .appending(path: "Breadcrumb")
            .appending(path: "Breadcrumb.store")

        migrateStoreIfNeeded(to: storeURL)

        let schema = Schema([
            Project.self, StatusEntry.self, PomodoroSession.self, LinkedDocument.self
        ])

        let config = ModelConfiguration(
            "Breadcrumb",
            schema: schema,
            url: storeURL
        )

        do {
            return try ModelContainer(
                for: schema,
                migrationPlan: BreadcrumbMigrationPlan.self,
                configurations: config
            )
        } catch {
            // The store exists but can't be opened — e.g. it was written by an
            // unreleased dev build whose schema no released version recognizes
            // ("Cannot use staged migration with an unknown model version").
            // Never delete data: move the store aside and retry with a fresh one.
            if let backupName = moveIncompatibleStoreAside(at: storeURL),
               let container = try? ModelContainer(
                   for: schema,
                   migrationPlan: BreadcrumbMigrationPlan.self,
                   configurations: config
               ) {
                showAlert(
                    style: .warning,
                    title: Strings.Errors.storeResetTitle(alertLanguage),
                    body: Strings.Errors.storeResetBody(alertLanguage, backupName: backupName)
                )
                return container
            }

            // A silent fatalError here means the app dies with no visible UI at
            // all (it has no dock icon). Show the reason before exiting so a
            // startup failure is diagnosable on someone else's machine.
            showAlert(
                style: .critical,
                title: Strings.Errors.startupFailedTitle(alertLanguage),
                body: Strings.Errors.startupFailedBody(alertLanguage, message: String(describing: error))
            )
            exit(1)
        }
    }

    /// Moves an unopenable store (plus its -wal/-shm sidecars) to a timestamped
    /// backup name in the same directory. Returns the backup base name, or nil
    /// if nothing could be moved. Internal (not private) for test access.
    static func moveIncompatibleStoreAside(at storeURL: URL) -> String? {
        let fileManager = FileManager.default
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let backupBase = "Breadcrumb.store.backup-\(formatter.string(from: .now))"
        let directory = storeURL.deletingLastPathComponent()

        var movedAny = false
        for suffix in ["", "-wal", "-shm"] {
            let source = directory.appending(path: "Breadcrumb.store\(suffix)")
            guard fileManager.fileExists(atPath: source.path(percentEncoded: false)) else { continue }
            do {
                try fileManager.moveItem(
                    at: source,
                    to: directory.appending(path: "\(backupBase)\(suffix)")
                )
                movedAny = true
            } catch {
                print("[Breadcrumb] Failed to move incompatible store file '\(source.lastPathComponent)': \(error)")
            }
        }
        return movedAny ? backupBase : nil
    }

    private static var alertLanguage: AppLanguage {
        let stored = UserDefaults.standard.string(forKey: "app.language") ?? "de"
        return AppLanguage(rawValue: stored) ?? .german
    }

    private static func showAlert(style: NSAlert.Style, title: String, body: String) {
        let alert = NSAlert()
        alert.alertStyle = style
        alert.messageText = title
        alert.informativeText = body
        alert.runModal()
    }

    private static func migrateStoreIfNeeded(to newURL: URL) {
        let fileManager = FileManager.default
        let oldPath = URL.applicationSupportDirectory
            .appending(path: "default.store")
            .path(percentEncoded: false)

        guard fileManager.fileExists(atPath: oldPath),
              !fileManager.fileExists(atPath: newURL.path(percentEncoded: false)) else {
            return
        }

        // Checkpoint the WAL so all data is flushed into the main store file
        var db: OpaquePointer?
        if sqlite3_open(oldPath, &db) == SQLITE_OK {
            sqlite3_wal_checkpoint_v2(db, nil, SQLITE_CHECKPOINT_FULL, nil, nil)
            sqlite3_close(db)
        }

        let directory = newURL.deletingLastPathComponent()
        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        } catch {
            return
        }

        // Copy all SQLite files (store, wal, shm), then delete sources
        let suffixes = ["", "-wal", "-shm"]
        var copiedSuffixes: [String] = []

        do {
            for suffix in suffixes {
                let source = URL.applicationSupportDirectory.appending(path: "default.store\(suffix)")
                let destination = directory.appending(path: "Breadcrumb.store\(suffix)")

                if fileManager.fileExists(atPath: source.path(percentEncoded: false)) {
                    try fileManager.copyItem(at: source, to: destination)
                    copiedSuffixes.append(suffix)
                }
            }
        } catch {
            // Copy failed — clean up only destination copies, source files remain intact
            print("[Breadcrumb] Store migration copy failed: \(error)")
            for suffix in copiedSuffixes {
                let destination = directory.appending(path: "Breadcrumb.store\(suffix)")
                try? fileManager.removeItem(at: destination)
            }
            return
        }

        // All copies succeeded — safe to delete source files
        for suffix in copiedSuffixes {
            let source = URL.applicationSupportDirectory.appending(path: "default.store\(suffix)")
            do {
                try fileManager.removeItem(at: source)
            } catch {
                print("[Breadcrumb] Failed to remove old store file 'default.store\(suffix)': \(error)")
            }
        }
    }
}
