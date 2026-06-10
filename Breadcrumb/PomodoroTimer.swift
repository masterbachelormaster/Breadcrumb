import AppKit
import Foundation
import Observation
import SwiftData

enum TimerPhase: Equatable {
    case idle
    case work
    case shortBreak
    case longBreak
    case sessionEnded
}

enum SessionEndReason: Equatable {
    case workDone
    case breakDone
    case focusMateDone
    case stopped
}

enum SessionEndPresentation: String, CaseIterable, Identifiable {
    case window
    case menuBar

    var id: String { rawValue }
}

@Observable
@MainActor
final class PomodoroTimer {
    var remainingSeconds: Int = 0
    var isRunning: Bool = false
    var isPaused: Bool = false
    var isOvertime: Bool = false
    var overtimeSeconds: Int = 0
    var currentPhase: TimerPhase = .idle
    var currentSessionNumber: Int = 1
    var boundProject: Project?
    var boundProjectID: PersistentIdentifier?
    var originalDurationSeconds: Int = 0
    var didCrossZero: Bool = false
    var pendingSessionEnd: SessionEndReason?

    // FocusMate properties
    var isFocusMateSession: Bool = false
    var focusMateEndTime: Date?
    var focusMateEarlyEndSeconds: Int = 0

    var notificationService: (any PomodoroNotificationScheduling)?

    // Per-session settings (set at start, read during cycle)
    var sessionWorkMinutes: Int = 25
    var sessionShortBreakMinutes: Int = 5
    var sessionLongBreakMinutes: Int = 15
    var sessionSessionsBeforeLong: Int = 4
    var sessionTotalSessions: Int = 4

    var isCycleComplete: Bool { currentSessionNumber >= sessionTotalSessions }

    private var timerTask: Task<Void, Never>?
    var phaseStartDate: Date?
    var phaseDurationSeconds: Int = 0
    var elapsedBeforePause: Int = 0

    init() {
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.tick()
            }
        }
    }

    // MARK: - Computed Properties

    var formattedTime: String {
        if isOvertime {
            let minutes = overtimeSeconds / 60
            let seconds = overtimeSeconds % 60
            return "+\(minutes):\(seconds.formatted(.number.precision(.integerLength(2))))"
        } else {
            let minutes = remainingSeconds / 60
            let seconds = remainingSeconds % 60
            return "\(minutes):\(seconds.formatted(.number.precision(.integerLength(2))))"
        }
    }

    /// Like `formattedTime`, but minutes are zero-padded so the menu bar label
    /// keeps a constant width for the whole session (09:59 instead of 9:59).
    var menuBarFormattedTime: String {
        let total = isOvertime ? overtimeSeconds : remainingSeconds
        let minutes = total / 60
        let seconds = total % 60
        let time = "\(minutes.formatted(.number.precision(.integerLength(2...)))):\(seconds.formatted(.number.precision(.integerLength(2))))"
        return isOvertime ? "+\(time)" : time
    }

    func menuBarLabel(_ l: AppLanguage) -> String {
        switch currentPhase {
        case .idle:
            return "Breadcrumb"
        case .work:
            if isFocusMateSession {
                return "👥 \(menuBarFormattedTime)"
            }
            return "🍅 \(menuBarFormattedTime)"
        case .shortBreak, .longBreak:
            return "☕ \(menuBarFormattedTime)"
        case .sessionEnded:
            if isFocusMateSession {
                return "👥 \(Strings.Pomodoro.done(l))"
            }
            return "🍅 \(Strings.Pomodoro.done(l))"
        }
    }

    // MARK: - Methods

    func startWork(project: Project?, durationMinutes: Int, shortBreakMinutes: Int, longBreakMinutes: Int, sessionsBeforeLong: Int, totalSessions: Int) {
        pendingSessionEnd = nil
        boundProject = project
        boundProjectID = project?.persistentModelID
        sessionWorkMinutes = durationMinutes
        sessionShortBreakMinutes = shortBreakMinutes
        sessionLongBreakMinutes = longBreakMinutes
        sessionSessionsBeforeLong = sessionsBeforeLong
        sessionTotalSessions = totalSessions
        originalDurationSeconds = durationMinutes * 60
        phaseDurationSeconds = durationMinutes * 60
        remainingSeconds = durationMinutes * 60
        elapsedBeforePause = 0
        isRunning = true
        isPaused = false
        isOvertime = false
        overtimeSeconds = 0
        didCrossZero = false
        currentPhase = .work
        notificationService?.cancelScheduledBanners()
        scheduleCurrentPhaseBanner()
        startTicking()
    }

    func startFocusMate(project: Project?, durationMinutes: Int, endTime: Date, earlyEndSeconds: Int = 0) {
        let offsetSeconds = max(0, earlyEndSeconds)
        let remaining = max(0, Int(endTime.timeIntervalSince(Date.now)) - offsetSeconds)

        pendingSessionEnd = nil
        boundProject = project
        boundProjectID = project?.persistentModelID
        focusMateEndTime = endTime
        focusMateEarlyEndSeconds = offsetSeconds
        isFocusMateSession = true
        originalDurationSeconds = durationMinutes * 60
        phaseDurationSeconds = remaining
        remainingSeconds = remaining
        elapsedBeforePause = 0
        isRunning = true
        isPaused = false
        isOvertime = false
        overtimeSeconds = 0
        didCrossZero = false
        currentPhase = .work
        currentSessionNumber = 1
        notificationService?.cancelScheduledBanners()
        scheduleCurrentPhaseBanner()
        startTicking()
    }

    func startBreak() {
        pendingSessionEnd = nil
        guard !isCycleComplete else {
            stop()
            return
        }

        isOvertime = false
        overtimeSeconds = 0
        didCrossZero = false
        elapsedBeforePause = 0

        if currentSessionNumber % sessionSessionsBeforeLong == 0 {
            currentPhase = .longBreak
            remainingSeconds = sessionLongBreakMinutes * 60
            phaseDurationSeconds = sessionLongBreakMinutes * 60
        } else {
            currentPhase = .shortBreak
            remainingSeconds = sessionShortBreakMinutes * 60
            phaseDurationSeconds = sessionShortBreakMinutes * 60
        }

        isRunning = true
        isPaused = false
        notificationService?.cancelScheduledBanners()
        scheduleCurrentPhaseBanner()
        startTicking()
    }

    func startNextWorkSession() {
        guard !isCycleComplete else { return }
        currentSessionNumber += 1
        startWork(project: boundProject, durationMinutes: sessionWorkMinutes, shortBreakMinutes: sessionShortBreakMinutes, longBreakMinutes: sessionLongBreakMinutes, sessionsBeforeLong: sessionSessionsBeforeLong, totalSessions: sessionTotalSessions)
    }

    func enterOvertime() {
        pendingSessionEnd = nil
        isOvertime = true
        isRunning = true
        overtimeSeconds = 0
        phaseDurationSeconds = 0
        elapsedBeforePause = 0
        currentPhase = .work
        notificationService?.cancelScheduledBanners()
        startTicking()
    }

    func snooze(minutes: Int) {
        pendingSessionEnd = nil
        isOvertime = false
        overtimeSeconds = 0
        didCrossZero = false
        isPaused = false
        elapsedBeforePause = 0
        remainingSeconds = minutes * 60
        phaseDurationSeconds = minutes * 60
        currentPhase = .work
        isRunning = true
        notificationService?.cancelScheduledBanners()
        scheduleCurrentPhaseBanner()
        startTicking()
    }

    func pause() {
        isPaused = true
        if let start = phaseStartDate {
            elapsedBeforePause += Int(Date.now.timeIntervalSince(start))
        }
        phaseStartDate = nil
        timerTask?.cancel()
        timerTask = nil
        notificationService?.cancelScheduledBanners()
    }

    func resume() {
        isPaused = false
        scheduleCurrentPhaseBanner()
        startTicking()
    }

    func requestStop() {
        pause()
        pendingSessionEnd = .stopped
    }

    func clearPendingSessionEnd() {
        pendingSessionEnd = nil
    }

    func stop() {
        pendingSessionEnd = nil
        notificationService?.cancelScheduledBanners()
        timerTask?.cancel()
        timerTask = nil
        remainingSeconds = 0
        isRunning = false
        isPaused = false
        isOvertime = false
        overtimeSeconds = 0
        didCrossZero = false
        originalDurationSeconds = 0
        phaseDurationSeconds = 0
        elapsedBeforePause = 0
        phaseStartDate = nil
        currentPhase = .idle
        currentSessionNumber = 1
        boundProject = nil
        boundProjectID = nil
        isFocusMateSession = false
        focusMateEndTime = nil
        focusMateEarlyEndSeconds = 0
        sessionWorkMinutes = 25
        sessionShortBreakMinutes = 5
        sessionLongBreakMinutes = 15
        sessionSessionsBeforeLong = 4
        sessionTotalSessions = 4
    }

    func tick() {
        guard let start = phaseStartDate else { return }
        let elapsed = elapsedBeforePause + Int(Date.now.timeIntervalSince(start))

        if isOvertime {
            overtimeSeconds = elapsed - phaseDurationSeconds
        } else {
            remainingSeconds = max(0, phaseDurationSeconds - elapsed)
            if remainingSeconds <= 0 {
                remainingSeconds = 0
                let stored = UserDefaults.standard.string(forKey: "app.language") ?? "de"
                let language = AppLanguage(rawValue: stored) ?? .german
                if currentPhase == .work && !isFocusMateSession {
                    // Auto-continue into overtime for regular Pomodoro work phases
                    isOvertime = true
                    didCrossZero = true
                    pendingSessionEnd = .workDone
                    overtimeSeconds = elapsed - phaseDurationSeconds
                    notificationService?.playWorkDoneFeedback(language: language)
                } else {
                    // Breaks and FocusMate sessions stop at zero
                    isRunning = false
                    let wasBreak = currentPhase == .shortBreak || currentPhase == .longBreak
                    currentPhase = .sessionEnded
                    pendingSessionEnd = wasBreak ? .breakDone : (isFocusMateSession ? .focusMateDone : .workDone)
                    timerTask?.cancel()
                    timerTask = nil
                    // One-shot transition: clear the start date so a stray tick()
                    // (e.g. from the wake-notification observer) cannot re-enter
                    // this branch and overwrite pendingSessionEnd or replay feedback.
                    phaseStartDate = nil
                    if wasBreak {
                        notificationService?.playBreakDoneFeedback(language: language)
                    } else {
                        notificationService?.playWorkDoneFeedback(language: language)
                    }
                }
            }
        }
    }

    // MARK: - Private

    private func startTicking() {
        timerTask?.cancel()
        phaseStartDate = Date.now
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled, let self else { break }
                self.tick()
            }
        }
    }

    private func scheduleCurrentPhaseBanner() {
        guard !isOvertime else { return }

        let seconds = TimeInterval(max(1, phaseDurationSeconds - elapsedBeforePause))
        let language = currentLanguage

        switch currentPhase {
        case .work:
            notificationService?.scheduleWorkDoneBanner(
                language: language,
                after: seconds,
                completion: workCompletionContext
            )
        case .shortBreak, .longBreak:
            notificationService?.scheduleBreakDoneBanner(language: language, after: seconds)
        case .idle, .sessionEnded:
            break
        }
    }

    private var workCompletionContext: PomodoroWorkCompletionContext {
        if isFocusMateSession {
            return .focusMateComplete
        }

        if isCycleComplete {
            return sessionTotalSessions == 1 ? .sessionComplete : .cycleComplete
        }

        return .breakAvailable
    }

    private var currentLanguage: AppLanguage {
        let stored = UserDefaults.standard.string(forKey: "app.language") ?? "de"
        return AppLanguage(rawValue: stored) ?? .german
    }
}
