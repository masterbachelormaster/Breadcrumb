import Testing
import Foundation
import SwiftData
@testable import Breadcrumb

@Suite("PomodoroTimer Tests")
@MainActor
struct PomodoroTimerTests {

    @Test("Timer initializes in idle state")
    func idleState() {
        let timer = PomodoroTimer()
        #expect(timer.currentPhase == .idle)
        #expect(timer.isRunning == false)
        #expect(timer.isPaused == false)
        #expect(timer.isOvertime == false)
        #expect(timer.currentSessionNumber == 1)
        #expect(timer.boundProject == nil)
    }

    @Test("Starting work session sets correct state")
    func startWorkSession() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4, totalSessions: 4)
        #expect(timer.currentPhase == .work)
        #expect(timer.isRunning == true)
        #expect(timer.remainingSeconds == 25 * 60)
        #expect(timer.currentSessionNumber == 1)
    }

    @Test("Starting work schedules a native completion banner")
    func startWorkSchedulesCompletionBanner() {
        let notifier = RecordingPomodoroNotifier()
        let timer = PomodoroTimer()
        timer.notificationService = notifier

        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4, totalSessions: 4)

        #expect(notifier.scheduledBanners == [.workDone(seconds: 25 * 60, completion: .breakAvailable)])
    }

    @Test("Starting a break schedules a native break completion banner")
    func startBreakSchedulesCompletionBanner() {
        let notifier = RecordingPomodoroNotifier()
        let timer = PomodoroTimer()
        timer.notificationService = notifier
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4, totalSessions: 4)

        timer.startBreak()

        #expect(notifier.scheduledBanners == [
            .workDone(seconds: 25 * 60, completion: .breakAvailable),
            .breakDone(seconds: 5 * 60)
        ])
    }

    @Test("Pausing and stopping cancel pending native completion banners")
    func pauseAndStopCancelCompletionBanners() {
        let notifier = RecordingPomodoroNotifier()
        let timer = PomodoroTimer()
        timer.notificationService = notifier
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4, totalSessions: 4)
        let countAfterStart = notifier.cancelCount

        timer.pause()
        timer.stop()

        #expect(notifier.cancelCount == countAfterStart + 2)
    }

    @Test("Work expiry keeps the scheduled end banner as the only user-facing notification")
    func workExpiryDoesNotPostImmediateOvertimeBanner() {
        let notifier = RecordingPomodoroNotifier()
        let timer = PomodoroTimer()
        timer.notificationService = notifier
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4, totalSessions: 1)
        let countAfterStart = notifier.cancelCount

        timer.phaseStartDate = Date.now.addingTimeInterval(-1500)
        timer.tick()

        #expect(notifier.cancelCount == countAfterStart)
        #expect(notifier.scheduledBanners == [.workDone(seconds: 25 * 60, completion: .sessionComplete)])
        #expect(notifier.workDoneFeedbackCount == 1)
        #expect(notifier.workDoneCount == 0)
        #expect(notifier.overtimeCount == 0)
        #expect(timer.isOvertime == true)
    }

    @Test("Break expiry keeps the scheduled break banner as the only user-facing notification")
    func breakExpiryDoesNotPostImmediateBreakDoneBanner() {
        let notifier = RecordingPomodoroNotifier()
        let timer = PomodoroTimer()
        timer.notificationService = notifier
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4, totalSessions: 4)
        timer.startBreak()
        let countAfterBreakStart = notifier.cancelCount

        timer.phaseStartDate = Date.now.addingTimeInterval(-Double(5 * 60))
        timer.tick()

        #expect(notifier.cancelCount == countAfterBreakStart)
        #expect(notifier.breakDoneFeedbackCount == 1)
        #expect(notifier.breakDoneCount == 0)
        #expect(timer.currentPhase == .sessionEnded)
    }

    @Test("FocusMate expiry keeps the scheduled work banner as the only user-facing notification")
    func focusMateExpiryDoesNotPostImmediateWorkDoneBanner() {
        let notifier = RecordingPomodoroNotifier()
        let timer = PomodoroTimer()
        timer.notificationService = notifier
        let endTime = Date.now.addingTimeInterval(25 * 60)
        timer.startFocusMate(project: nil, durationMinutes: 25, endTime: endTime)
        let countAfterStart = notifier.cancelCount

        timer.phaseStartDate = Date.now.addingTimeInterval(-Double(timer.phaseDurationSeconds))
        timer.tick()

        #expect(notifier.cancelCount == countAfterStart)
        #expect(notifier.scheduledBanners == [.workDone(seconds: timer.phaseDurationSeconds, completion: .focusMateComplete)])
        #expect(notifier.workDoneFeedbackCount == 1)
        #expect(notifier.workDoneCount == 0)
        #expect(timer.currentPhase == .sessionEnded)
    }

    @Test("Break expiry is one-shot: a wake-triggered tick must not flip the prompt or replay feedback")
    func breakExpiryTickReentryDoesNotRefire() {
        let notifier = RecordingPomodoroNotifier()
        let timer = PomodoroTimer()
        timer.notificationService = notifier
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4, totalSessions: 4)
        timer.startBreak()
        timer.phaseStartDate = Date.now.addingTimeInterval(-Double(5 * 60))
        timer.tick()
        #expect(timer.pendingSessionEnd == .breakDone)
        #expect(timer.phaseStartDate == nil)

        // Simulate the NSWorkspace.didWakeNotification observer re-entering tick()
        timer.tick()

        #expect(timer.pendingSessionEnd == .breakDone)
        #expect(timer.currentPhase == .sessionEnded)
        #expect(notifier.breakDoneFeedbackCount == 1)
        #expect(notifier.workDoneFeedbackCount == 0)
    }

    @Test("FocusMate expiry is one-shot: a wake-triggered tick must not replay completion feedback")
    func focusMateExpiryTickReentryDoesNotReplayFeedback() {
        let notifier = RecordingPomodoroNotifier()
        let timer = PomodoroTimer()
        timer.notificationService = notifier
        let endTime = Date.now.addingTimeInterval(25 * 60)
        timer.startFocusMate(project: nil, durationMinutes: 25, endTime: endTime)
        timer.phaseStartDate = Date.now.addingTimeInterval(-Double(timer.phaseDurationSeconds))
        timer.tick()
        #expect(timer.pendingSessionEnd == .focusMateDone)
        #expect(timer.phaseStartDate == nil)

        // Simulate the NSWorkspace.didWakeNotification observer re-entering tick()
        timer.tick()

        #expect(timer.pendingSessionEnd == .focusMateDone)
        #expect(timer.currentPhase == .sessionEnded)
        #expect(notifier.workDoneFeedbackCount == 1)
    }

    @Test("Work expiry sets pending work-done prompt")
    func workExpirySetsPendingWorkDonePrompt() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4, totalSessions: 4)

        timer.phaseStartDate = Date.now.addingTimeInterval(-Double(25 * 60))
        timer.tick()

        #expect(timer.pendingSessionEnd == .workDone)
        #expect(timer.didCrossZero == true)
        #expect(timer.currentPhase == .work)
        #expect(timer.isOvertime == true)
    }

    @Test("Break expiry sets pending break-done prompt")
    func breakExpirySetsPendingBreakDonePrompt() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4, totalSessions: 4)
        timer.startBreak()

        timer.phaseStartDate = Date.now.addingTimeInterval(-Double(5 * 60))
        timer.tick()

        #expect(timer.pendingSessionEnd == .breakDone)
        #expect(timer.currentPhase == .sessionEnded)
    }

    @Test("FocusMate expiry sets pending FocusMate prompt")
    func focusMateExpirySetsPendingFocusMatePrompt() {
        let timer = PomodoroTimer()
        let endTime = Date.now.addingTimeInterval(25 * 60)
        timer.startFocusMate(project: nil, durationMinutes: 25, endTime: endTime)

        timer.phaseStartDate = Date.now.addingTimeInterval(-Double(timer.phaseDurationSeconds))
        timer.tick()

        #expect(timer.pendingSessionEnd == .focusMateDone)
        #expect(timer.currentPhase == .sessionEnded)
    }

    @Test("Manual stop pauses timer and sets pending stopped prompt")
    func manualStopSetsPendingStoppedPrompt() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4, totalSessions: 4)

        timer.requestStop()

        #expect(timer.pendingSessionEnd == .stopped)
        #expect(timer.isPaused == true)
        #expect(timer.currentPhase == .work)
    }

    @Test("Starting work stores bound project identifier")
    func startWorkStoresBoundProjectIdentifier() {
        let timer = PomodoroTimer()
        let project = Project(name: "Planning", icon: "list.bullet")

        timer.startWork(project: project, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4, totalSessions: 4)

        #expect(timer.boundProject === project)
        #expect(timer.boundProjectID == project.persistentModelID)
    }

    @Test("Clearing pending session end leaves timer state intact")
    func clearPendingSessionEndLeavesTimerStateIntact() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4, totalSessions: 4)
        timer.requestStop()

        timer.clearPendingSessionEnd()

        #expect(timer.pendingSessionEnd == nil)
        #expect(timer.isPaused == true)
        #expect(timer.currentPhase == .work)
    }

    @Test("Final session in a multi-session cycle schedules all-sessions completion")
    func finalCycleSessionSchedulesAllSessionsCompletionBanner() {
        let notifier = RecordingPomodoroNotifier()
        let timer = PomodoroTimer()
        timer.notificationService = notifier
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4, totalSessions: 2)

        timer.startBreak()
        timer.startNextWorkSession()

        #expect(notifier.scheduledBanners.last == .workDone(seconds: 25 * 60, completion: .cycleComplete))
    }

    @Test("Tick decrements remaining seconds")
    func tickDecrement() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4, totalSessions: 4)
        timer.phaseStartDate = Date.now.addingTimeInterval(-1)
        timer.tick()
        #expect(timer.remainingSeconds == 25 * 60 - 1)
    }

    // MARK: - Feature 1: Auto-continue overtime

    @Test("Work phase auto-continues into overtime at zero")
    func workAutoOvertimeAtZero() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4, totalSessions: 4)
        timer.phaseStartDate = Date.now.addingTimeInterval(-Double(25 * 60))
        timer.tick()
        #expect(timer.remainingSeconds == 0)
        #expect(timer.isOvertime == true)
        #expect(timer.didCrossZero == true)
        #expect(timer.currentPhase == .work)
        #expect(timer.isRunning == true)
    }

    @Test("Break phase still ends at zero")
    func breakStillEndsAtZero() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4, totalSessions: 4)
        timer.startBreak()
        timer.phaseStartDate = Date.now.addingTimeInterval(-Double(5 * 60))
        timer.tick()
        #expect(timer.remainingSeconds == 0)
        #expect(timer.currentPhase == .sessionEnded)
        #expect(timer.isRunning == false)
    }

    @Test("Overtime seconds count up after crossing zero")
    func overtimeSecondsCountUp() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4, totalSessions: 4)
        timer.phaseStartDate = Date.now.addingTimeInterval(-Double(25 * 60 + 10))
        timer.tick()
        #expect(timer.isOvertime == true)
        #expect(timer.overtimeSeconds == 10)
        #expect(timer.currentPhase == .work)
    }

    @Test("didCrossZero resets on stop")
    func didCrossZeroResetsOnStop() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4, totalSessions: 4)
        timer.phaseStartDate = Date.now.addingTimeInterval(-Double(25 * 60))
        timer.tick()
        #expect(timer.didCrossZero == true)
        timer.stop()
        #expect(timer.didCrossZero == false)
    }

    @Test("didCrossZero resets on startWork")
    func didCrossZeroResetsOnStartWork() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4, totalSessions: 4)
        timer.phaseStartDate = Date.now.addingTimeInterval(-Double(25 * 60))
        timer.tick()
        #expect(timer.didCrossZero == true)
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4, totalSessions: 4)
        #expect(timer.didCrossZero == false)
    }

    // MARK: - Feature 2: Total sessions

    @Test("Cycle completes after total sessions")
    func cycleCompletesAfterTotalSessions() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4, totalSessions: 2)
        #expect(timer.isCycleComplete == false)
        timer.currentSessionNumber = 2
        #expect(timer.isCycleComplete == true)
    }

    @Test("Single session cycle completes immediately")
    func singleSessionCycle() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4, totalSessions: 1)
        #expect(timer.isCycleComplete == true)
    }

    @Test("Total sessions stored on startWork")
    func totalSessionsStored() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4, totalSessions: 3)
        #expect(timer.sessionTotalSessions == 3)
    }

    @Test("startNextWorkSession guards cycle complete")
    func startNextGuardsCycleComplete() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4, totalSessions: 1)
        timer.startNextWorkSession()
        #expect(timer.currentSessionNumber == 1)
    }

    @Test("startBreak stops instead of starting break when cycle is complete")
    func startBreakStopsWhenCycleComplete() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4, totalSessions: 1)
        timer.startBreak()
        #expect(timer.currentPhase == .idle)
        #expect(timer.isRunning == false)
        #expect(timer.currentSessionNumber == 1)
    }

    @Test("sessionsBeforeLong determines long break trigger")
    func sessionsBeforeLongDeterminesBreakType() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 3, totalSessions: 6)
        timer.currentSessionNumber = 2
        timer.startBreak()
        #expect(timer.currentPhase == .shortBreak)

        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 3, totalSessions: 6)
        timer.currentSessionNumber = 3
        timer.startBreak()
        #expect(timer.currentPhase == .longBreak)
        #expect(timer.remainingSeconds == 15 * 60)
    }

    @Test("Minimum work duration of 5 minutes works correctly")
    func minimumWorkDuration() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 5, shortBreakMinutes: 1, longBreakMinutes: 5, sessionsBeforeLong: 2, totalSessions: 2)
        #expect(timer.remainingSeconds == 300)
        #expect(timer.originalDurationSeconds == 300)
    }

    // MARK: - Feature 3: FocusMate

    @Test("FocusMate session starts correctly")
    func startFocusMateSession() {
        let timer = PomodoroTimer()
        let endTime = Date.now.addingTimeInterval(50 * 60)
        timer.startFocusMate(project: nil, durationMinutes: 50, endTime: endTime)
        #expect(timer.currentPhase == .work)
        #expect(timer.isFocusMateSession == true)
        #expect(timer.isRunning == true)
        #expect(timer.remainingSeconds > 0)
        #expect(timer.remainingSeconds <= 3000)
        #expect(timer.focusMateEndTime != nil)
    }

    @Test("FocusMate session ends at zero (no overtime)")
    func focusMateEndsAtZero() {
        let timer = PomodoroTimer()
        let endTime = Date.now.addingTimeInterval(25 * 60)
        timer.startFocusMate(project: nil, durationMinutes: 25, endTime: endTime)
        timer.phaseStartDate = Date.now.addingTimeInterval(-Double(timer.phaseDurationSeconds))
        timer.tick()
        #expect(timer.currentPhase == .sessionEnded)
        #expect(timer.isRunning == false)
        #expect(timer.isOvertime == false)
    }

    @Test("FocusMate menu bar label shows people emoji")
    func focusMateMenuBarLabel() {
        let timer = PomodoroTimer()
        let endTime = Date.now.addingTimeInterval(50 * 60)
        timer.startFocusMate(project: nil, durationMinutes: 50, endTime: endTime)
        #expect(timer.menuBarLabel(.english).hasPrefix("👥"))
    }

    @Test("Stop resets FocusMate properties")
    func stopResetsFocusMateProperties() {
        let timer = PomodoroTimer()
        let endTime = Date.now.addingTimeInterval(50 * 60)
        timer.startFocusMate(project: nil, durationMinutes: 50, endTime: endTime, earlyEndSeconds: 120)
        timer.stop()
        #expect(timer.isFocusMateSession == false)
        #expect(timer.focusMateEndTime == nil)
        #expect(timer.focusMateEarlyEndSeconds == 0)
    }

    @Test("FocusMate early-end offset shortens the countdown")
    func focusMateEarlyEndReducesRemaining() {
        let timer = PomodoroTimer()
        let endTime = Date.now.addingTimeInterval(50 * 60)
        timer.startFocusMate(project: nil, durationMinutes: 50, endTime: endTime, earlyEndSeconds: 120)
        #expect(timer.isFocusMateSession == true)
        #expect(timer.focusMateEarlyEndSeconds == 120)
        #expect(timer.focusMateEndTime == endTime)
        #expect(abs(timer.remainingSeconds - (48 * 60)) <= 1)
    }

    @Test("FocusMate early-end offset supports sub-minute (seconds) granularity")
    func focusMateEarlyEndSupportsSeconds() {
        let timer = PomodoroTimer()
        let endTime = Date.now.addingTimeInterval(50 * 60)
        timer.startFocusMate(project: nil, durationMinutes: 50, endTime: endTime, earlyEndSeconds: 90)
        #expect(timer.focusMateEarlyEndSeconds == 90)
        #expect(abs(timer.remainingSeconds - (50 * 60 - 90)) <= 1)
    }

    @Test("FocusMate early-end offset triggers session end early")
    func focusMateEarlyEndTriggersSessionEnd() {
        let timer = PomodoroTimer()
        let endTime = Date.now.addingTimeInterval(25 * 60)
        timer.startFocusMate(project: nil, durationMinutes: 25, endTime: endTime, earlyEndSeconds: 120)
        timer.phaseStartDate = Date.now.addingTimeInterval(-Double(timer.phaseDurationSeconds))
        timer.tick()
        #expect(timer.currentPhase == .sessionEnded)
        #expect(timer.isRunning == false)
    }

    // MARK: - Existing tests

    @Test("Entering overtime counts up")
    func overtimeCounting() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4, totalSessions: 4)
        timer.remainingSeconds = 0
        timer.currentPhase = .sessionEnded
        timer.enterOvertime()
        #expect(timer.isOvertime == true)
        #expect(timer.currentPhase == .work)
        #expect(timer.overtimeSeconds == 0)
        timer.phaseStartDate = Date.now.addingTimeInterval(-1)
        timer.tick()
        #expect(timer.overtimeSeconds == 1)
    }

    @Test("Starting break sets correct phase")
    func startBreak() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4, totalSessions: 4)
        timer.currentSessionNumber = 1
        timer.startBreak()
        #expect(timer.currentPhase == .shortBreak)
        #expect(timer.remainingSeconds == 5 * 60)
        #expect(timer.isOvertime == false)
    }

    @Test("Long break after configured sessions")
    func longBreakAfterFourSessions() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4, totalSessions: 5)
        timer.currentSessionNumber = 4
        timer.startBreak()
        #expect(timer.currentPhase == .longBreak)
        #expect(timer.remainingSeconds == 15 * 60)
    }

    @Test("Pause and resume")
    func pauseResume() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4, totalSessions: 4)
        timer.pause()
        #expect(timer.isPaused == true)
        #expect(timer.isRunning == true)
        timer.resume()
        #expect(timer.isPaused == false)
        #expect(timer.isRunning == true)
    }

    @Test("Stop resets to idle")
    func stopResetsToIdle() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4, totalSessions: 4)
        timer.stop()
        #expect(timer.currentPhase == .idle)
        #expect(timer.isRunning == false)
        #expect(timer.currentSessionNumber == 1)
        #expect(timer.isOvertime == false)
        #expect(timer.overtimeSeconds == 0)
        #expect(timer.sessionTotalSessions == 4)
    }

    @Test("Menu bar label reflects timer state and language")
    func menuBarLabel() {
        let timer = PomodoroTimer()
        #expect(timer.menuBarLabel(.german) == "Breadcrumb")
        #expect(timer.menuBarLabel(.english) == "Breadcrumb")
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4, totalSessions: 4)
        #expect(timer.menuBarLabel(.german).contains("🍅"))
        timer.currentPhase = .shortBreak
        timer.remainingSeconds = 195
        #expect(timer.menuBarLabel(.german).contains("☕"))
        timer.currentPhase = .sessionEnded
        #expect(timer.menuBarLabel(.german) == "🍅 Fertig!")
        #expect(timer.menuBarLabel(.english) == "🍅 Done!")
    }

    @Test("Phase emoji reflects phase and FocusMate mode")
    func phaseEmojiReflectsPhase() {
        let timer = PomodoroTimer()
        #expect(timer.phaseEmoji == "🔖")
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4, totalSessions: 4)
        #expect(timer.phaseEmoji == "🍅")
        timer.startBreak()
        #expect(timer.phaseEmoji == "☕")

        let focusMate = PomodoroTimer()
        focusMate.startFocusMate(project: nil, durationMinutes: 25, endTime: Date.now.addingTimeInterval(25 * 60))
        #expect(focusMate.phaseEmoji == "👥")
    }

    @Test("Phase label reflects phase and language")
    func phaseLabelReflectsPhase() {
        let timer = PomodoroTimer()
        #expect(timer.phaseLabel(.english).isEmpty)
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4, totalSessions: 4)
        #expect(timer.phaseLabel(.english) == Strings.Pomodoro.focusTimeSession(.english, number: 1, total: 4))
        #expect(timer.phaseLabel(.german) == Strings.Pomodoro.focusTimeSession(.german, number: 1, total: 4))
        timer.startBreak()
        #expect(timer.phaseLabel(.english) == Strings.Pomodoro.shortBreak(.english))
        timer.currentPhase = .sessionEnded
        #expect(timer.phaseLabel(.english) == Strings.Pomodoro.sessionEnded(.english))
    }

    @Test("Phase label shows overtime variant during overtime")
    func phaseLabelOvertime() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4, totalSessions: 4)
        timer.phaseStartDate = Date.now.addingTimeInterval(-Double(25 * 60))
        timer.tick()
        #expect(timer.isOvertime == true)
        #expect(timer.phaseLabel(.english) == Strings.Pomodoro.overtimeSession(.english, number: 1))
    }

    @Test("Original duration is tracked")
    func originalDuration() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4, totalSessions: 4)
        #expect(timer.originalDurationSeconds == 1500)
        timer.stop()
        #expect(timer.originalDurationSeconds == 0)
    }

    @Test("Formatted time displays correctly")
    func formattedTime() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4, totalSessions: 4)
        timer.remainingSeconds = 754
        #expect(timer.formattedTime == "12:34")
        timer.remainingSeconds = 60
        #expect(timer.formattedTime == "1:00")
        timer.remainingSeconds = 5
        #expect(timer.formattedTime == "0:05")
    }

    @Test("Menu bar time zero-pads minutes for constant width")
    func menuBarFormattedTime() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4, totalSessions: 4)
        timer.remainingSeconds = 1500
        #expect(timer.menuBarFormattedTime == "25:00")
        timer.remainingSeconds = 599
        #expect(timer.menuBarFormattedTime == "09:59")
        timer.remainingSeconds = 5
        #expect(timer.menuBarFormattedTime == "00:05")
        timer.isOvertime = true
        timer.overtimeSeconds = 5
        #expect(timer.menuBarFormattedTime == "+00:05")
    }

    @Test("Session settings are stored on startWork")
    func sessionSettings() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 30, shortBreakMinutes: 3, longBreakMinutes: 20, sessionsBeforeLong: 6, totalSessions: 5)
        #expect(timer.sessionWorkMinutes == 30)
        #expect(timer.sessionShortBreakMinutes == 3)
        #expect(timer.sessionLongBreakMinutes == 20)
        #expect(timer.sessionSessionsBeforeLong == 6)
        #expect(timer.sessionTotalSessions == 5)
    }

    @Test("Stop resets session settings to defaults")
    func stopResetsSessionSettings() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 30, shortBreakMinutes: 3, longBreakMinutes: 20, sessionsBeforeLong: 6, totalSessions: 3)
        timer.stop()
        #expect(timer.sessionWorkMinutes == 25)
        #expect(timer.sessionShortBreakMinutes == 5)
        #expect(timer.sessionLongBreakMinutes == 15)
        #expect(timer.sessionSessionsBeforeLong == 4)
        #expect(timer.sessionTotalSessions == 4)
    }

    // MARK: - Snooze

    @Test("Snooze sets timer to given minutes and resumes work")
    func snoozeResumesWork() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4, totalSessions: 4)
        // Simulate reaching overtime
        timer.isOvertime = true
        timer.overtimeSeconds = 120
        timer.currentPhase = .sessionEnded

        timer.snooze(minutes: 5)

        #expect(timer.currentPhase == .work)
        #expect(timer.remainingSeconds == 5 * 60)
        #expect(timer.isOvertime == false)
        #expect(timer.overtimeSeconds == 0)
        #expect(timer.isRunning == true)
        #expect(timer.isPaused == false)
    }

    @Test("Snooze resets didCrossZero")
    func snoozeResetsDidCrossZero() {
        let timer = PomodoroTimer()
        timer.startWork(project: nil, durationMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15, sessionsBeforeLong: 4, totalSessions: 4)
        timer.didCrossZero = true
        timer.snooze(minutes: 10)
        #expect(timer.didCrossZero == false)
    }
}

private enum ScheduledBanner: Equatable {
    case workDone(seconds: Int, completion: PomodoroWorkCompletionContext)
    case breakDone(seconds: Int)
}

@MainActor
private final class RecordingPomodoroNotifier: PomodoroNotificationScheduling {
    var scheduledBanners: [ScheduledBanner] = []
    var cancelCount = 0
    var workDoneFeedbackCount = 0
    var breakDoneFeedbackCount = 0
    var workDoneCount = 0
    var breakDoneCount = 0
    var overtimeCount = 0

    @discardableResult
    func scheduleWorkDoneBanner(
        language: AppLanguage,
        after seconds: TimeInterval,
        completion: PomodoroWorkCompletionContext
    ) -> Task<Void, Never>? {
        scheduledBanners.append(.workDone(seconds: Int(seconds), completion: completion))
        return nil
    }

    @discardableResult
    func scheduleBreakDoneBanner(language: AppLanguage, after seconds: TimeInterval) -> Task<Void, Never>? {
        scheduledBanners.append(.breakDone(seconds: Int(seconds)))
        return nil
    }

    func cancelScheduledBanners() {
        cancelCount += 1
    }

    func playWorkDoneFeedback(language: AppLanguage) {
        workDoneFeedbackCount += 1
    }

    func playBreakDoneFeedback(language: AppLanguage) {
        breakDoneFeedbackCount += 1
    }

    func notifyWorkDone(language: AppLanguage) {
        workDoneCount += 1
    }

    func notifyBreakDone(language: AppLanguage) {
        breakDoneCount += 1
    }

}
