import SwiftUI
import SwiftData
import SQLite3

@main
struct BreadcrumbApp: App {
    let sharedModelContainer: ModelContainer

    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var pomodoroTimer = PomodoroTimer()
    @State private var windowManager = WindowManager()
    @State private var aiService = AIService()
    @State private var languageManager = LanguageManager()
    @State private var notificationService = NotificationService()

    init() {
        sharedModelContainer = Self.createModelContainer()
    }

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .onAppear {
                    pomodoroTimer.notificationService = notificationService
                    notificationService.requestAuthorization()
                }
                .environment(pomodoroTimer)
                .environment(windowManager)
                .environment(aiService)
                .environment(languageManager)
        } label: {
            if pomodoroTimer.currentPhase == .idle {
                Image(systemName: "bookmark.fill")
            } else {
                Text(pomodoroTimer.menuBarLabel(languageManager.language))
            }
        }
        .menuBarExtraStyle(.window)
        .modelContainer(sharedModelContainer)

        Window("Breadcrumb", id: "main") {
            BreakoutWindowView()
                .environment(pomodoroTimer)
                .environment(windowManager)
                .environment(aiService)
                .environment(languageManager)
        }
        .modelContainer(sharedModelContainer)
        .defaultSize(width: 500, height: 400)
        .commands {
            BreadcrumbCommands(windowManager: windowManager, languageManager: languageManager)
        }
    }

    // MARK: - Model Container

    private static func createModelContainer() -> ModelContainer {
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
            fatalError("Failed to create ModelContainer: \(error)")
        }
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
