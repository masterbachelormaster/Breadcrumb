import Testing
import Foundation
import UserNotifications
@testable import Breadcrumb

@Suite("NotificationService Tests")
@MainActor
struct NotificationServiceTests {

    @Test("Service initializes and sets itself as delegate")
    func initialization() throws {
        let center = RecordingUserNotificationCenter()
        let service = NotificationService(notificationCenter: center)
        let delegate = try #require(center.delegate as? NotificationService)

        #expect(delegate === service)
    }

    @Test("playSound plays named sound without crashing")
    func playSoundDoesNotCrash() {
        let service = NotificationService()
        // "Glass" is a real macOS system sound
        service.playSound(named: "Glass")
        // No crash = pass. NSSound.play() is fire-and-forget.
    }

    @Test("playSound with empty string does nothing")
    func playSoundEmptyString() {
        let service = NotificationService()
        service.playSound(named: "")
        // No crash = pass
    }

    @Test("playSound with invalid name does nothing")
    func playSoundInvalidName() {
        let service = NotificationService()
        service.playSound(named: "NonexistentSound12345")
        // NSSound(named:) returns nil, optional chain does nothing
    }

    @Test("Scheduling work done creates a native timed banner request")
    func scheduleWorkDoneBanner() async throws {
        let center = RecordingUserNotificationCenter()
        let suiteName = "NotificationServiceTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.set(true, forKey: "pomodoro.showBannerNotification")
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let service = NotificationService(notificationCenter: center, userDefaults: defaults)
        let task = try #require(service.scheduleWorkDoneBanner(language: .english, after: 90))
        await task.value

        let request = try #require(center.addedRequests.first)
        #expect(request.identifier == "breadcrumb.pomodoro.workDone")
        #expect(request.content.title == "Pomodoro Finished!")
        #expect(request.content.body == "Time for a break.")

        let trigger = try #require(request.trigger as? UNTimeIntervalNotificationTrigger)
        #expect(trigger.timeInterval == 90)
    }

    @Test("Scheduling requests notification authorization before adding banner")
    func scheduleRequestsAuthorizationBeforeAddingBanner() async throws {
        let center = RecordingUserNotificationCenter()
        let service = NotificationService(notificationCenter: center)

        let task = try #require(service.scheduleWorkDoneBanner(language: .english, after: 90))
        await task.value

        #expect(center.requestedAuthorizationOptions == [.alert, .sound])
        #expect(center.addedRequestCountWhenAuthorizationRequested == 0)
        #expect(center.addedRequests.count == 1)
    }

    @Test("Scheduling does nothing when banner notifications are disabled")
    func scheduleSkippedWhenBannersDisabled() throws {
        let center = RecordingUserNotificationCenter()
        let suiteName = "NotificationServiceTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.set(false, forKey: "pomodoro.showBannerNotification")
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let service = NotificationService(notificationCenter: center, userDefaults: defaults)
        let task = service.scheduleBreakDoneBanner(language: .english, after: 60)

        #expect(task == nil)
        #expect(center.addedRequests.isEmpty)
    }

    @Test("Cancelling removes pending Pomodoro banner requests")
    func cancelScheduledBanners() {
        let center = RecordingUserNotificationCenter()
        let service = NotificationService(notificationCenter: center)

        service.cancelScheduledBanners()

        #expect(center.removedIdentifiers == [
            "breadcrumb.pomodoro.workDone",
            "breadcrumb.pomodoro.breakDone"
        ])
    }
}

@MainActor
private final class RecordingUserNotificationCenter: UserNotificationCenterClient {
    var delegate: (any UNUserNotificationCenterDelegate)?
    var addedRequests: [UNNotificationRequest] = []
    var removedIdentifiers: [String] = []
    var requestedAuthorizationOptions: UNAuthorizationOptions?
    var addedRequestCountWhenAuthorizationRequested: Int?

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        requestedAuthorizationOptions = options
        addedRequestCountWhenAuthorizationRequested = addedRequests.count
        return true
    }

    func add(_ request: UNNotificationRequest) async throws {
        addedRequests.append(request)
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        removedIdentifiers = identifiers
    }

    var registeredCategories: Set<UNNotificationCategory> = []

    func setNotificationCategories(_ categories: Set<UNNotificationCategory>) {
        registeredCategories = categories
    }
}
