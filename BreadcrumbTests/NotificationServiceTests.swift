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
        let task = try #require(service.scheduleWorkDoneBanner(language: .english, after: 90, completion: .breakAvailable))
        await task.value

        let request = try #require(center.addedRequests.first)
        #expect(request.identifier == "breadcrumb.pomodoro.workDone")
        #expect(request.content.title == "Pomodoro Finished!")
        #expect(request.content.body == "Time for a break")
        #expect(request.content.categoryIdentifier == "breadcrumb.category.workDone")

        let trigger = try #require(request.trigger as? UNTimeIntervalNotificationTrigger)
        #expect(trigger.timeInterval == 90)
    }

    @Test("Scheduling final single-session work done uses completion copy")
    func scheduleSingleSessionWorkDoneBanner() async throws {
        let center = RecordingUserNotificationCenter()
        let suiteName = "NotificationServiceTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.set(true, forKey: "pomodoro.showBannerNotification")
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let service = NotificationService(notificationCenter: center, userDefaults: defaults)
        let task = try #require(service.scheduleWorkDoneBanner(language: .german, after: 90, completion: .sessionComplete))
        await task.value

        let request = try #require(center.addedRequests.first)
        #expect(request.identifier == "breadcrumb.pomodoro.workDone")
        #expect(request.content.title == "Pomodoro beendet!")
        #expect(request.content.body == "Sitzung abgeschlossen")
        #expect(request.content.categoryIdentifier == "breadcrumb.category.workComplete")
    }

    @Test("Scheduling final cycle work done uses all sessions copy")
    func scheduleFinalCycleWorkDoneBanner() async throws {
        let center = RecordingUserNotificationCenter()
        let suiteName = "NotificationServiceTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.set(true, forKey: "pomodoro.showBannerNotification")
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let service = NotificationService(notificationCenter: center, userDefaults: defaults)
        let task = try #require(service.scheduleWorkDoneBanner(language: .german, after: 90, completion: .cycleComplete))
        await task.value

        let request = try #require(center.addedRequests.first)
        #expect(request.identifier == "breadcrumb.pomodoro.workDone")
        #expect(request.content.title == "Pomodoro beendet!")
        #expect(request.content.body == "Alle Sitzungen abgeschlossen")
        #expect(request.content.categoryIdentifier == "breadcrumb.category.workComplete")
    }

    @Test("Scheduling FocusMate done uses FocusMate completion copy")
    func scheduleFocusMateDoneBanner() async throws {
        let center = RecordingUserNotificationCenter()
        let suiteName = "NotificationServiceTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.set(true, forKey: "pomodoro.showBannerNotification")
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let service = NotificationService(notificationCenter: center, userDefaults: defaults)
        let task = try #require(service.scheduleWorkDoneBanner(language: .german, after: 90, completion: .focusMateComplete))
        await task.value

        let request = try #require(center.addedRequests.first)
        #expect(request.identifier == "breadcrumb.pomodoro.workDone")
        #expect(request.content.title == "FocusMate beendet!")
        #expect(request.content.body == "Sitzung abgeschlossen")
        #expect(request.content.categoryIdentifier == "breadcrumb.category.workComplete")
    }

    @Test("Scheduling requests notification authorization before adding banner")
    func scheduleRequestsAuthorizationBeforeAddingBanner() async throws {
        let center = RecordingUserNotificationCenter()
        let service = NotificationService(notificationCenter: center)

        let task = try #require(service.scheduleWorkDoneBanner(language: .english, after: 90, completion: .breakAvailable))
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

    @Test("notifyWorkDone posts an immediate banner")
    func notifyWorkDonePostsImmediateBanner() async throws {
        let center = RecordingUserNotificationCenter()
        let suiteName = "NotificationServiceTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.set(true, forKey: "pomodoro.showBannerNotification")
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let service = NotificationService(notificationCenter: center, userDefaults: defaults)
        service.notifyWorkDone(language: .english)

        await Task.yield()
        try await Task.sleep(for: .milliseconds(50))

        let request = try #require(center.addedRequests.first)
        #expect(request.identifier == "breadcrumb.pomodoro.workDone")
        #expect(request.content.title == "Pomodoro Finished!")
        #expect(request.trigger == nil)
        #expect(request.content.categoryIdentifier == "breadcrumb.category.workDone")
    }

    @Test("notifyBreakDone posts an immediate banner")
    func notifyBreakDonePostsImmediateBanner() async throws {
        let center = RecordingUserNotificationCenter()
        let suiteName = "NotificationServiceTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.set(true, forKey: "pomodoro.showBannerNotification")
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let service = NotificationService(notificationCenter: center, userDefaults: defaults)
        service.notifyBreakDone(language: .english)

        await Task.yield()
        try await Task.sleep(for: .milliseconds(50))

        let request = try #require(center.addedRequests.first)
        #expect(request.identifier == "breadcrumb.pomodoro.breakDone")
        #expect(request.content.title == "Break Over!")
        #expect(request.trigger == nil)
        #expect(request.content.categoryIdentifier == "breadcrumb.category.breakDone")
    }

    @Test("notifyWorkDone skips banner when disabled")
    func notifyWorkDoneSkipsBannerWhenDisabled() async throws {
        let center = RecordingUserNotificationCenter()
        let suiteName = "NotificationServiceTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.set(false, forKey: "pomodoro.showBannerNotification")
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let service = NotificationService(notificationCenter: center, userDefaults: defaults)
        service.notifyWorkDone(language: .english)

        await Task.yield()
        try await Task.sleep(for: .milliseconds(50))

        #expect(center.addedRequests.isEmpty)
    }

    @Test("Work done feedback does not open the popover automatically")
    func workDoneFeedbackDoesNotOpenPopover() throws {
        let center = RecordingUserNotificationCenter()
        let suiteName = "NotificationServiceTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.set("", forKey: "pomodoro.sound.workDone")
        defer { defaults.removePersistentDomain(forName: suiteName) }
        var postedNames: [Notification.Name] = []
        let service = NotificationService(notificationCenter: center, userDefaults: defaults) { name in
            postedNames.append(name)
        }

        service.playWorkDoneFeedback(language: .english)

        #expect(postedNames.isEmpty)
        #expect(center.addedRequests.isEmpty)
    }

    @Test("Continue working action does not post an app notification")
    func continueWorkingActionIsNoOp() {
        let center = RecordingUserNotificationCenter()
        var postedNames: [Notification.Name] = []
        let service = NotificationService(notificationCenter: center) { name in
            postedNames.append(name)
        }

        service.handleActionIdentifier("breadcrumb.action.continueWorking")

        #expect(postedNames.isEmpty)
    }

    @Test("Stop action opens the session-end prompt")
    func stopActionOpensSessionEndPrompt() {
        let center = RecordingUserNotificationCenter()
        var postedNames: [Notification.Name] = []
        let service = NotificationService(notificationCenter: center) { name in
            postedNames.append(name)
        }

        service.handleActionIdentifier("breadcrumb.action.openSessionEnd")

        #expect(postedNames == [.openSessionEnd])
    }

    @Test("Legacy stop action identifier still opens the session-end prompt")
    func legacyStopActionIdentifierStillOpensSessionEndPrompt() {
        let center = RecordingUserNotificationCenter()
        var postedNames: [Notification.Name] = []
        let service = NotificationService(notificationCenter: center) { name in
            postedNames.append(name)
        }

        service.handleActionIdentifier("breadcrumb.action.openPopover")

        #expect(postedNames == [.openSessionEnd])
    }

    @Test("Break action still starts the next session")
    func nextSessionActionStillPostsNextSession() {
        let center = RecordingUserNotificationCenter()
        var postedNames: [Notification.Name] = []
        let service = NotificationService(notificationCenter: center) { name in
            postedNames.append(name)
        }

        service.handleActionIdentifier("breadcrumb.action.nextSession")

        #expect(postedNames == [.pomodoroNextSession])
    }

    @Test("Init registers notification categories with action buttons")
    func registersCategoriesOnInit() {
        let center = RecordingUserNotificationCenter()
        let _ = NotificationService(notificationCenter: center)

        #expect(center.registeredCategories.count == 3)

        let categoryIDs = center.registeredCategories.map(\.identifier).sorted()
        #expect(categoryIDs == [
            "breadcrumb.category.breakDone",
            "breadcrumb.category.workComplete",
            "breadcrumb.category.workDone"
        ])

        let workDone = center.registeredCategories.first { $0.identifier == "breadcrumb.category.workDone" }!
        assertWorkCompletionActions(workDone.actions)

        let breakDone = center.registeredCategories.first { $0.identifier == "breadcrumb.category.breakDone" }!
        #expect(breakDone.actions.count == 1)
        #expect(breakDone.actions[0].identifier == "breadcrumb.action.nextSession")

        let workComplete = center.registeredCategories.first { $0.identifier == "breadcrumb.category.workComplete" }!
        assertWorkCompletionActions(workComplete.actions)
    }

    private func assertWorkCompletionActions(_ actions: [UNNotificationAction]) {
        #expect(actions.count == 2)
        #expect(actions[0].identifier == "breadcrumb.action.continueWorking")
        #expect(actions[0].title == "Weiterarbeiten")
        #expect(actions[0].options.isEmpty)
        #expect(actions[1].identifier == "breadcrumb.action.openSessionEnd")
        #expect(actions[1].title == "Stopp")
        #expect(actions[1].options.contains(.foreground))
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
