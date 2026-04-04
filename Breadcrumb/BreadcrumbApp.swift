import SwiftUI
import SwiftData
import UserNotifications
import SQLite3

@main
struct BreadcrumbApp: App {
    let sharedModelContainer: ModelContainer

    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var pomodoroTimer = PomodoroTimer()
    @State private var windowManager = WindowManager()
    @State private var aiService = AIService()
    @State private var languageManager = LanguageManager()

    init() {
        sharedModelContainer = Self.createModelContainer()
        Task { try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) }
    }

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environment(pomodoroTimer)
                .environment(windowManager)
                .environment(aiService)
                .environment(languageManager)
        } label: {
            if pomodoroTimer.currentPhase == .idle {
                Image(systemName: "bookmark.fill")
            } else {
                Text(pomodoroTimer.menuBarLabel)
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

        let config = ModelConfiguration(
            "Breadcrumb",
            schema: Schema([Project.self, StatusEntry.self, PomodoroSession.self, LinkedDocument.self]),
            url: storeURL
        )

        do {
            return try ModelContainer(
                for: Project.self, StatusEntry.self, PomodoroSession.self, LinkedDocument.self,
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

        // Move all SQLite files (store, wal, shm)
        let suffixes = ["", "-wal", "-shm"]
        for suffix in suffixes {
            let source = URL.applicationSupportDirectory.appending(path: "default.store\(suffix)")
            let destination = directory.appending(path: "Breadcrumb.store\(suffix)")

            if fileManager.fileExists(atPath: source.path(percentEncoded: false)) {
                do {
                    try fileManager.moveItem(at: source, to: destination)
                } catch {
                    for cleanSuffix in suffixes {
                        let cleanDest = directory.appending(path: "Breadcrumb.store\(cleanSuffix)")
                        try? fileManager.removeItem(at: cleanDest)
                    }
                    return
                }
            }
        }
    }
}

struct BreadcrumbCommands: Commands {
    @Environment(\.openWindow) private var openWindow
    let windowManager: WindowManager
    let languageManager: LanguageManager

    var body: some Commands {
        CommandGroup(replacing: .appInfo) {
            Button(Strings.General.about(languageManager.language)) {
                windowManager.open(.about)
                openWindow(id: "main")
            }
        }
        CommandGroup(replacing: .appSettings) {
            Button(Strings.General.settingsEllipsis(languageManager.language)) {
                windowManager.open(.settings)
                openWindow(id: "main")
            }
            .keyboardShortcut(",", modifiers: .command)
        }
    }
}
