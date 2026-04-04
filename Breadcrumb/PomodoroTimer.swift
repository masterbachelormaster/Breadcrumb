import Foundation
import Observation

enum TimerPhase: Equatable {
    case idle
    case work
    case shortBreak
    case longBreak
    case sessionEnded
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
    var originalDurationSeconds: Int = 0

    // Per-session settings (set at start, read during cycle)
    var sessionWorkMinutes: Int = 25
    var sessionShortBreakMinutes: Int = 5
    var sessionLongBreakMinutes: Int = 15
    var sessionSessionsBeforeLong: Int = 4

    private var timerTask: Task<Void, Never>?
    var phaseStartDate: Date?
    var phaseDurationSeconds: Int = 0
    var elapsedBeforePause: Int = 0

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

    func menuBarLabel(_ l: AppLanguage) -> String {
        switch currentPhase {
        case .idle:
            return "Breadcrumb"
        case .work:
            return "🍅 \(formattedTime)"
        case .shortBreak, .longBreak:
            return "☕ \(formattedTime)"
        case .sessionEnded:
            return "🍅 \(Strings.Pomodoro.done(l))"
        }
    }

    // MARK: - Methods

    func startWork(project: Project?, durationMinutes: Int, shortBreakMinutes: Int, longBreakMinutes: Int, sessionsBeforeLong: Int) {
        boundProject = project
        sessionWorkMinutes = durationMinutes
        sessionShortBreakMinutes = shortBreakMinutes
        sessionLongBreakMinutes = longBreakMinutes
        sessionSessionsBeforeLong = sessionsBeforeLong
        originalDurationSeconds = durationMinutes * 60
        phaseDurationSeconds = durationMinutes * 60
        remainingSeconds = durationMinutes * 60
        elapsedBeforePause = 0
        isRunning = true
        isPaused = false
        isOvertime = false
        overtimeSeconds = 0
        currentPhase = .work
        startTicking()
    }

    func startBreak() {
        isOvertime = false
        overtimeSeconds = 0
        elapsedBeforePause = 0

        if currentSessionNumber >= sessionSessionsBeforeLong {
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
        startTicking()
    }

    func startNextWorkSession() {
        if currentSessionNumber >= sessionSessionsBeforeLong {
            currentSessionNumber = 1
        } else {
            currentSessionNumber += 1
        }
        startWork(project: boundProject, durationMinutes: sessionWorkMinutes, shortBreakMinutes: sessionShortBreakMinutes, longBreakMinutes: sessionLongBreakMinutes, sessionsBeforeLong: sessionSessionsBeforeLong)
    }

    func enterOvertime() {
        isOvertime = true
        isRunning = true
        overtimeSeconds = 0
        elapsedBeforePause = 0
        currentPhase = .work
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
    }

    func resume() {
        isPaused = false
        startTicking()
    }

    func stop() {
        timerTask?.cancel()
        timerTask = nil
        remainingSeconds = 0
        isRunning = false
        isPaused = false
        isOvertime = false
        overtimeSeconds = 0
        originalDurationSeconds = 0
        phaseDurationSeconds = 0
        elapsedBeforePause = 0
        phaseStartDate = nil
        currentPhase = .idle
        currentSessionNumber = 1
        boundProject = nil
        sessionWorkMinutes = 25
        sessionShortBreakMinutes = 5
        sessionLongBreakMinutes = 15
        sessionSessionsBeforeLong = 4
    }

    func tick() {
        guard let start = phaseStartDate else { return }
        let elapsed = elapsedBeforePause + Int(Date.now.timeIntervalSince(start))

        if isOvertime {
            overtimeSeconds = elapsed
        } else {
            remainingSeconds = max(0, phaseDurationSeconds - elapsed)
            if remainingSeconds <= 0 {
                remainingSeconds = 0
                isRunning = false
                currentPhase = .sessionEnded
                timerTask?.cancel()
                timerTask = nil
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
}
