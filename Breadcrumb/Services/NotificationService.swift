import AppKit
import UserNotifications

@MainActor
final class NotificationService: NSObject, UNUserNotificationCenterDelegate {

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func requestAuthorization() {
        Task {
            try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
        }
    }

    // MARK: - Tier 1: Work Done (full interruption)

    func notifyWorkDone(language: AppLanguage) {
        let soundName = UserDefaults.standard.string(forKey: "pomodoro.sound.workDone") ?? "Glass"
        playSound(named: soundName)

        let showBanner = UserDefaults.standard.object(forKey: "pomodoro.showBannerNotification") as? Bool ?? true
        if showBanner {
            sendBanner(
                title: Strings.Notifications.pomodoroFinishedTitle(language),
                body: Strings.Notifications.pomodoroFinishedBody(language)
            )
        }

        let autoOpen = UserDefaults.standard.object(forKey: "pomodoro.autoOpenPopover") as? Bool ?? true
        if autoOpen {
            NotificationCenter.default.post(name: .openPopover, object: nil)
        }
    }

    // MARK: - Tier 2: Break Done (medium)

    func notifyBreakDone(language: AppLanguage) {
        let soundName = UserDefaults.standard.string(forKey: "pomodoro.sound.breakDone") ?? "Ping"
        playSound(named: soundName)

        let showBanner = UserDefaults.standard.object(forKey: "pomodoro.showBannerNotification") as? Bool ?? true
        if showBanner {
            sendBanner(
                title: Strings.Notifications.breakOverTitle(language),
                body: Strings.Notifications.breakOverBody(language)
            )
        }
    }

    // MARK: - Tier 3: Overtime (gentle nudge)

    func notifyOvertime(language: AppLanguage) {
        let soundName = UserDefaults.standard.string(forKey: "pomodoro.sound.overtime") ?? "Tink"
        playSound(named: soundName)
    }

    // MARK: - Sound

    func playSound(named name: String) {
        guard !name.isEmpty else { return }
        NSSound(named: NSSound.Name(name))?.play()
    }

    // MARK: - Banner

    private func sendBanner(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - UNUserNotificationCenterDelegate

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner]
    }
}
