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

enum PomodoroWorkCompletionContext: Equatable {
    case breakAvailable
    case sessionComplete
    case cycleComplete
    case focusMateComplete
}

@MainActor
protocol PomodoroNotificationScheduling: AnyObject {
    @discardableResult
    func scheduleWorkDoneBanner(
        language: AppLanguage,
        after seconds: TimeInterval,
        completion: PomodoroWorkCompletionContext
    ) -> Task<Void, Never>?

    @discardableResult
    func scheduleBreakDoneBanner(language: AppLanguage, after seconds: TimeInterval) -> Task<Void, Never>?

    func cancelScheduledBanners()
    func playWorkDoneFeedback(language: AppLanguage)
    func playBreakDoneFeedback(language: AppLanguage)
    func notifyWorkDone(language: AppLanguage)
    func notifyBreakDone(language: AppLanguage)
}

@MainActor
final class NotificationService: NSObject, UNUserNotificationCenterDelegate, PomodoroNotificationScheduling {
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.roger.breadcrumb",
        category: "Notifications"
    )

    private enum Banner {
        case workDone(PomodoroWorkCompletionContext)
        case breakDone

        var identifier: String {
            switch self {
            case .workDone: "breadcrumb.pomodoro.workDone"
            case .breakDone: "breadcrumb.pomodoro.breakDone"
            }
        }

        var categoryIdentifier: String {
            switch self {
            case .workDone(.breakAvailable): "breadcrumb.category.workDone"
            case .workDone: "breadcrumb.category.workComplete"
            case .breakDone: "breadcrumb.category.breakDone"
            }
        }

        func title(language: AppLanguage) -> String {
            switch self {
            case .workDone(.focusMateComplete): Strings.Notifications.focusMateFinishedTitle(language)
            case .workDone: Strings.Notifications.pomodoroFinishedTitle(language)
            case .breakDone: Strings.Notifications.breakOverTitle(language)
            }
        }

        func body(language: AppLanguage) -> String {
            switch self {
            case .workDone(.breakAvailable): Strings.Notifications.pomodoroFinishedBody(language)
            case .workDone(.sessionComplete): Strings.Notifications.sessionCompleteBody(language)
            case .workDone(.cycleComplete): Strings.Notifications.allSessionsCompleteBody(language)
            case .workDone(.focusMateComplete): Strings.Notifications.sessionCompleteBody(language)
            case .breakDone: Strings.Notifications.breakOverBody(language)
            }
        }

        static let allIdentifiers = [
            Banner.workDone(.breakAvailable).identifier,
            Banner.breakDone.identifier
        ]
    }

    private let notificationCenter: any UserNotificationCenterClient
    private let userDefaults: UserDefaults
    private let postAppNotification: (Notification.Name) -> Void

    init(
        notificationCenter: any UserNotificationCenterClient = UNUserNotificationCenter.current(),
        userDefaults: UserDefaults = .standard,
        postAppNotification: @escaping (Notification.Name) -> Void = {
            NotificationCenter.default.post(name: $0, object: nil)
        }
    ) {
        self.notificationCenter = notificationCenter
        self.userDefaults = userDefaults
        self.postAppNotification = postAppNotification
        super.init()
        self.notificationCenter.delegate = self
        registerCategories()
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
    func scheduleWorkDoneBanner(
        language: AppLanguage,
        after seconds: TimeInterval,
        completion: PomodoroWorkCompletionContext
    ) -> Task<Void, Never>? {
        scheduleBanner(.workDone(completion), language: language, after: seconds)
    }

    @discardableResult
    func scheduleBreakDoneBanner(language: AppLanguage, after seconds: TimeInterval) -> Task<Void, Never>? {
        scheduleBanner(.breakDone, language: language, after: seconds)
    }

    func cancelScheduledBanners() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: Banner.allIdentifiers)
    }

    private func registerCategories() {
        let stored = userDefaults.string(forKey: "app.language") ?? "de"
        let language = AppLanguage(rawValue: stored) ?? .german

        let nextSession = UNNotificationAction(
            identifier: "breadcrumb.action.nextSession",
            title: Strings.Notifications.actionNextSession(language)
        )
        let continueWorking = UNNotificationAction(
            identifier: "breadcrumb.action.continueWorking",
            title: Strings.Notifications.actionContinueWorking(language)
        )
        let openSessionEnd = UNNotificationAction(
            identifier: "breadcrumb.action.openSessionEnd",
            title: Strings.Notifications.actionStop(language),
            options: [.foreground]
        )
        let workDoneCategory = UNNotificationCategory(
            identifier: "breadcrumb.category.workDone",
            actions: [continueWorking, openSessionEnd],
            intentIdentifiers: []
        )
        let workCompleteCategory = UNNotificationCategory(
            identifier: "breadcrumb.category.workComplete",
            actions: [continueWorking, openSessionEnd],
            intentIdentifiers: []
        )
        let breakDoneCategory = UNNotificationCategory(
            identifier: "breadcrumb.category.breakDone",
            actions: [nextSession],
            intentIdentifiers: []
        )

        notificationCenter.setNotificationCategories([workDoneCategory, workCompleteCategory, breakDoneCategory])
    }

    // MARK: - Tier 1: Work Done (full interruption feedback)

    func playWorkDoneFeedback(language: AppLanguage) {
        let soundName = userDefaults.string(forKey: "pomodoro.sound.workDone") ?? "Glass"
        playSound(named: soundName)
    }

    func notifyWorkDone(language: AppLanguage) {
        playWorkDoneFeedback(language: language)
        sendImmediateBanner(.workDone(.breakAvailable), language: language)
    }

    // MARK: - Tier 2: Break Done (medium feedback)

    func playBreakDoneFeedback(language: AppLanguage) {
        let soundName = userDefaults.string(forKey: "pomodoro.sound.breakDone") ?? "Ping"
        playSound(named: soundName)
    }

    func notifyBreakDone(language: AppLanguage) {
        playBreakDoneFeedback(language: language)
        sendImmediateBanner(.breakDone, language: language)
    }

    // MARK: - Sound

    func playSound(named name: String) {
        guard !name.isEmpty else { return }
        NSSound(named: NSSound.Name(name))?.play()
    }

    // MARK: - Banner

    private func sendImmediateBanner(_ banner: Banner, language: AppLanguage) {
        let showBanner = userDefaults.object(forKey: "pomodoro.showBannerNotification") as? Bool ?? true
        guard showBanner else { return }

        notificationCenter.removePendingNotificationRequests(withIdentifiers: [banner.identifier])

        let content = UNMutableNotificationContent()
        content.title = banner.title(language: language)
        content.body = banner.body(language: language)
        content.categoryIdentifier = banner.categoryIdentifier

        let request = UNNotificationRequest(
            identifier: banner.identifier,
            content: content,
            trigger: nil
        )

        Task {
            do {
                try await notificationCenter.add(request)
                logger.info("Posted immediate banner: id=\(banner.identifier, privacy: .public)")
            } catch {
                logger.error("Failed to post immediate banner: id=\(banner.identifier, privacy: .public), error=\(error.localizedDescription, privacy: .public)")
            }
        }
    }

    private func scheduleBanner(_ banner: Banner, language: AppLanguage, after seconds: TimeInterval) -> Task<Void, Never>? {
        let showBanner = userDefaults.object(forKey: "pomodoro.showBannerNotification") as? Bool ?? true
        guard showBanner else { return nil }

        let content = UNMutableNotificationContent()
        content.title = banner.title(language: language)
        content.body = banner.body(language: language)
        content.categoryIdentifier = banner.categoryIdentifier

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

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let actionIdentifier = response.actionIdentifier
        await MainActor.run {
            handleActionIdentifier(actionIdentifier)
        }
    }

    func handleActionIdentifier(_ actionIdentifier: String) {
        switch actionIdentifier {
        case "breadcrumb.action.continueWorking":
            break
        case "breadcrumb.action.openSessionEnd", "breadcrumb.action.openPopover":
            postAppNotification(.openSessionEnd)
        case "breadcrumb.action.startBreak":
            postAppNotification(.pomodoroStartBreak)
        case "breadcrumb.action.nextSession":
            postAppNotification(.pomodoroNextSession)
        default:
            break
        }
    }
}
