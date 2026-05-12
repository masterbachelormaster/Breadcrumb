import AppKit
import OSLog
import UserNotifications

@MainActor
protocol UserNotificationCenterClient: AnyObject {
    var delegate: (any UNUserNotificationCenterDelegate)? { get set }

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
    func add(_ request: UNNotificationRequest) async throws
    func removePendingNotificationRequests(withIdentifiers identifiers: [String])
    func setNotificationCategories(_ categories: Set<UNNotificationCategory>)
}

extension UNUserNotificationCenter: UserNotificationCenterClient {}

@MainActor
protocol PomodoroNotificationScheduling: AnyObject {
    @discardableResult
    func scheduleWorkDoneBanner(language: AppLanguage, after seconds: TimeInterval) -> Task<Void, Never>?

    @discardableResult
    func scheduleBreakDoneBanner(language: AppLanguage, after seconds: TimeInterval) -> Task<Void, Never>?

    func cancelScheduledBanners()
    func notifyWorkDone(language: AppLanguage)
    func notifyBreakDone(language: AppLanguage)
    func notifyOvertime(language: AppLanguage)
}

@MainActor
final class NotificationService: NSObject, UNUserNotificationCenterDelegate, PomodoroNotificationScheduling {
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.roger.breadcrumb",
        category: "Notifications"
    )

    private enum Banner {
        case workDone
        case breakDone

        var identifier: String {
            switch self {
            case .workDone: "breadcrumb.pomodoro.workDone"
            case .breakDone: "breadcrumb.pomodoro.breakDone"
            }
        }

        func title(language: AppLanguage) -> String {
            switch self {
            case .workDone: Strings.Notifications.pomodoroFinishedTitle(language)
            case .breakDone: Strings.Notifications.breakOverTitle(language)
            }
        }

        func body(language: AppLanguage) -> String {
            switch self {
            case .workDone: Strings.Notifications.pomodoroFinishedBody(language)
            case .breakDone: Strings.Notifications.breakOverBody(language)
            }
        }

        static let allIdentifiers = [workDone.identifier, breakDone.identifier]
    }

    private let notificationCenter: any UserNotificationCenterClient
    private let userDefaults: UserDefaults

    init(
        notificationCenter: any UserNotificationCenterClient = UNUserNotificationCenter.current(),
        userDefaults: UserDefaults = .standard
    ) {
        self.notificationCenter = notificationCenter
        self.userDefaults = userDefaults
        super.init()
        self.notificationCenter.delegate = self
    }

    @discardableResult
    func requestAuthorization() -> Task<Void, Never> {
        Task {
            do {
                let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound])
                logger.info("Notification authorization requested: granted=\(granted, privacy: .public)")
            } catch {
                logger.error("Notification authorization failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    // MARK: - Scheduled Banners

    @discardableResult
    func scheduleWorkDoneBanner(language: AppLanguage, after seconds: TimeInterval) -> Task<Void, Never>? {
        scheduleBanner(.workDone, language: language, after: seconds)
    }

    @discardableResult
    func scheduleBreakDoneBanner(language: AppLanguage, after seconds: TimeInterval) -> Task<Void, Never>? {
        scheduleBanner(.breakDone, language: language, after: seconds)
    }

    func cancelScheduledBanners() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: Banner.allIdentifiers)
    }

    // MARK: - Tier 1: Work Done (full interruption feedback)

    func notifyWorkDone(language: AppLanguage) {
        let soundName = userDefaults.string(forKey: "pomodoro.sound.workDone") ?? "Glass"
        playSound(named: soundName)

        let autoOpen = userDefaults.object(forKey: "pomodoro.autoOpenPopover") as? Bool ?? true
        if autoOpen {
            NotificationCenter.default.post(name: .openPopover, object: nil)
        }
    }

    // MARK: - Tier 2: Break Done (medium feedback)

    func notifyBreakDone(language: AppLanguage) {
        let soundName = userDefaults.string(forKey: "pomodoro.sound.breakDone") ?? "Ping"
        playSound(named: soundName)
    }

    // MARK: - Tier 3: Overtime (gentle nudge)

    func notifyOvertime(language: AppLanguage) {
        let soundName = userDefaults.string(forKey: "pomodoro.sound.overtime") ?? "Tink"
        playSound(named: soundName)

        let autoOpen = userDefaults.object(forKey: "pomodoro.autoOpenPopover") as? Bool ?? true
        if autoOpen {
            NotificationCenter.default.post(name: .openPopover, object: nil)
        }
    }

    // MARK: - Sound

    func playSound(named name: String) {
        guard !name.isEmpty else { return }
        NSSound(named: NSSound.Name(name))?.play()
    }

    // MARK: - Banner

    private func scheduleBanner(_ banner: Banner, language: AppLanguage, after seconds: TimeInterval) -> Task<Void, Never>? {
        let showBanner = userDefaults.object(forKey: "pomodoro.showBannerNotification") as? Bool ?? true
        guard showBanner else { return nil }

        let content = UNMutableNotificationContent()
        content.title = banner.title(language: language)
        content.body = banner.body(language: language)

        let delay = max(1, seconds)
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: delay,
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: banner.identifier,
            content: content,
            trigger: trigger
        )

        return Task {
            do {
                let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound])
                guard granted else {
                    logger.info("Skipped Pomodoro banner because notification authorization was not granted: id=\(banner.identifier, privacy: .public)")
                    return
                }

                try await notificationCenter.add(request)
                logger.info("Scheduled Pomodoro banner: id=\(banner.identifier, privacy: .public), seconds=\(delay, privacy: .public)")
            } catch {
                logger.error("Failed to schedule Pomodoro banner: id=\(banner.identifier, privacy: .public), error=\(error.localizedDescription, privacy: .public)")
            }
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list]
    }
}
