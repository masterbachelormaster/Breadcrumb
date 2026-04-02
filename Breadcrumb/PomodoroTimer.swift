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

    private var timerTask: Task<Void, Never>?

    // MARK: - Computed Properties

    var formattedTime: String {
        if isOvertime {
            let minutes = overtimeSeconds / 60
            let seconds = overtimeSeconds % 60
            return "+\(minutes):\(String(format: "%02d", seconds))"
        } else {
            let minutes = remainingSeconds / 60
            let seconds = remainingSeconds % 60
            return "\(minutes):\(String(format: "%02d", seconds))"
        }
    }

    var menuBarLabel: String {
        switch currentPhase {
        case .idle:
            return "Breadcrumb"
        case .work:
            return "🍅 \(formattedTime)"
        case .shortBreak, .longBreak:
            return "☕ \(formattedTime)"
        case .sessionEnded:
            return "🍅 Fertig!"
        }
    }

    // MARK: - Methods

    func startWork(project: Project?, durationMinutes: Int) {
        boundProject = project
        originalDurationSeconds = durationMinutes * 60
        remainingSeconds = durationMinutes * 60
        isRunning = true
        isPaused = false
        isOvertime = false
        overtimeSeconds = 0
        currentPhase = .work
        startTicking()
    }

    func startBreak(shortMinutes: Int, longMinutes: Int, sessionsBeforeLong: Int) {
        isOvertime = false
        overtimeSeconds = 0

        if currentSessionNumber >= sessionsBeforeLong {
            currentPhase = .longBreak
            remainingSeconds = longMinutes * 60
        } else {
            currentPhase = .shortBreak
            remainingSeconds = shortMinutes * 60
        }

        isRunning = true
        isPaused = false
        startTicking()
    }

    func startNextWorkSession(durationMinutes: Int, sessionsBeforeLong: Int) {
        if currentSessionNumber >= sessionsBeforeLong {
            currentSessionNumber = 1
        } else {
            currentSessionNumber += 1
        }
        startWork(project: boundProject, durationMinutes: durationMinutes)
    }

    func enterOvertime() {
        isOvertime = true
        overtimeSeconds = 0
        currentPhase = .work
        startTicking()
    }

    func pause() {
        isPaused = true
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
        currentPhase = .idle
        currentSessionNumber = 1
        boundProject = nil
    }

    func tick() {
        if isOvertime {
            overtimeSeconds += 1
        } else {
            remainingSeconds -= 1
            if remainingSeconds <= 0 {
                remainingSeconds = 0
                currentPhase = .sessionEnded
                timerTask?.cancel()
                timerTask = nil
            }
        }
    }

    // MARK: - Private

    private func startTicking() {
        timerTask?.cancel()
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { break }
                self?.tick()
            }
        }
    }
}
