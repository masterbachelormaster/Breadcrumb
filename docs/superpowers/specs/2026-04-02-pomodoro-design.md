# Pomodoro Timer for Breadcrumb

## Context

Breadcrumb is a macOS menu bar app for tracking where you left off on projects. Users log status entries (current status, last step, next step, open questions) per project. Adding a Pomodoro timer creates a natural workflow: focus on a project → timer ends → log where you left off. The timer turns Breadcrumb from a passive note-taking tool into an active focus companion.

## Core Concept

The menu bar *is* the timer. While a Pomodoro is running, the menu bar icon and label show the countdown. Clicking it opens the full timer view. No persistent banners, no floating windows — just the menu bar doing double duty.

## Timer Lifecycle

### Full Pomodoro Cycle

Work (25 min) → Short Break (5 min) → Work → Short Break → Work → Short Break → Work → **Long Break (15 min)** → cycle resets.

All durations configurable in Settings. Default: 4 work sessions before a long break.

### States

| State | Menu Bar Icon | Menu Bar Label | Window Content |
|-------|--------------|----------------|----------------|
| No timer | `bookmark.fill` | "Breadcrumb" | Normal project list |
| Work session | 🍅 (tomato) | `17:42` countdown | Full timer view with pause/stop |
| Break (short/long) | ☕ (coffee) | `3:15` countdown | Break timer view with skip button |
| Overtime | 🍅 (tomato) | `+2:15` (orange, counting up) | Overtime view with "end session" button |
| Session ended | 🍅 (tomato) | "Fertig!" | Status entry form |

### Timer End Flow

1. Work timer reaches 0:00
2. Notification + sound (per user settings)
3. Status entry form auto-appears when user opens the window
4. User has three choices:
   - **Speichern & Pause starten** — saves status entry, starts break timer
   - **Weiterarbeiten** — dismisses form, timer switches to overtime (counts up)
   - **Überspringen** — skips the status entry, starts break timer directly
5. If user chose "Weiterarbeiten": they work in overtime mode. When they manually end, the status entry form appears again.

### Break End Flow

1. Break timer reaches 0:00
2. Notification + sound
3. Window shows "Break over" with a button to start next work session
4. After long break, cycle counter resets to 1

## Starting a Pomodoro

### Two Entry Points

1. **Project Detail View** — "Pomodoro starten" button in the footer alongside "Status aktualisieren". Session is pre-bound to that project.

2. **Footer Bar (standalone)** — Tomato icon added to the footer bar (next to archive, settings, quit). Tapping opens a project picker, then starts the timer. User can also choose "Ohne Projekt" (without project) for untracked focus time.

### Standalone → Project Binding

When a standalone timer ends and the status entry form appears, the user picks which project to log the entry to (or skips if it was untracked).

## Menu Bar Integration

### Dynamic Menu Bar Label

`MenuBarExtra` supports a `Label` view for its title. Use `Text` with emoji characters for the icon (SF Symbols don't include a tomato). The label updates every second via the `@Observable` timer.

- No timer: `"☁️ Breadcrumb"` (or keep `bookmark.fill` SF Symbol)
- Work session: `"🍅 MM:SS"`
- Break: `"☕ MM:SS"`
- Overtime: `"🍅 +MM:SS"`

Note: `MenuBarExtra("title", ...)` accepts a string or a Label view. To use dynamic text, use the `content` + `label` initializer variant.

### Window Takeover

When a timer is running, the entire 350×450 window shows only the timer view. The normal project list is hidden until the timer cycle is fully stopped. The timer view shows:

- Large countdown (48pt font)
- Session type label (e.g., "Fokuszeit · Sitzung 2 von 4")
- Project name (if bound)
- Controls: Pause/Resume, Stop (work session), Skip (break)

## Data Model

### New: `PomodoroSession` (SwiftData)

```
PomodoroSession
├── id: UUID
├── startedAt: Date
├── endedAt: Date?
├── plannedDuration: TimeInterval (in seconds)
├── actualDuration: TimeInterval? (includes overtime)
├── sessionType: SessionType (.work / .shortBreak / .longBreak)
├── sessionNumber: Int (1-4, which work session in the cycle)
├── completed: Bool (finished vs manually stopped)
├── project: Project? (optional relationship)
```

This model enables basic stats (completed count, total focus time per project). Break sessions are also recorded for completeness.

### Existing Model Changes

**`StatusEntry`** — add optional relationship:
- `pomodoroSession: PomodoroSession?` — links a status entry to the Pomodoro that triggered it

**`Project`** — add relationship:
- `pomodoroSessions: [PomodoroSession]` — all Pomodoro sessions for this project

## Timer Engine

### `PomodoroTimer` (@Observable)

A non-persisted `@Observable` class that manages the running timer state:

- `remainingSeconds: Int`
- `isRunning: Bool`
- `isPaused: Bool`
- `isOvertime: Bool`
- `overtimeSeconds: Int`
- `currentPhase: TimerPhase` (.work / .shortBreak / .longBreak / .sessionEnded / .idle)
- `currentSessionNumber: Int`
- `boundProject: Project?`

Uses a `Timer.publish(every: 1)` for the countdown. The `PomodoroTimer` is owned by `BreadcrumbApp` and injected into `ContentView` via `@Environment`. The `MenuBarExtra` title is a computed binding that reads from this timer.

### Stopping Mid-Session

If the user presses Stop during a work session, the status entry form appears (same as session end). The session is recorded with `completed: false`. After submitting or skipping the form, the timer returns to idle and the window shows the project list.

## Settings

Add to the existing `SettingsView`:

**Pomodoro section:**
- Fokuszeit: Stepper (5–60 min, default 25)
- Kurze Pause: Stepper (1–15 min, default 5)
- Lange Pause: Stepper (5–30 min, default 15)
- Sitzungen bis lange Pause: Stepper (2–8, default 4)

**Benachrichtigungen section:**
- Ton abspielen: Toggle (default on)
- Systembenachrichtigung: Toggle (default on)

Settings stored via `@AppStorage` (UserDefaults), not SwiftData.

## Statistics

### Basic Stats on Project Detail

Show below the latest status entry on the project detail view:

- **Pomodoros abgeschlossen:** count of completed work sessions
- **Fokuszeit gesamt:** total actual duration of completed work sessions (formatted as hours/minutes)

No charts, no streaks, no daily/weekly views. Just two numbers.

## Navigation Changes

### `ContentView.Screen` Enum

Add new case:
- `.pomodoroRunning` — shows the timer view (only reachable when timer is active)
- `.projectPicker` — shows project picker for standalone timer start

### Flow

```
ProjectListView
├── Footer: 🍅 tap → .projectPicker → select project → timer starts → .pomodoroRunning
├── Footer: archive, settings, quit (unchanged)

ProjectDetailView  
├── "Pomodoro starten" → timer starts (bound to project) → .pomodoroRunning

PomodoroRunningView (new)
├── Shows countdown, controls
├── Session ends → PomodoroSessionEndView (inline, same screen)
│   ├── Status entry form + "Speichern & Pause starten"
│   ├── "Weiterarbeiten" → overtime mode
│   └── "Überspringen" → break starts
├── Break ends → "Nächste Sitzung starten" button
├── All sessions done / Stop pressed → returns to ProjectListView
```

## Notifications

Uses `UNUserNotificationCenter`. Request permission on first Pomodoro start. Notification content:

- Work session end: "Pomodoro beendet! Zeit für eine Pause." 
- Break end: "Pause vorbei! Bereit für die nächste Sitzung?"
- Sound: system default alert sound

## Files to Create

| File | Purpose |
|------|---------|
| `Models/PomodoroSession.swift` | SwiftData model for completed sessions |
| `Views/PomodoroRunningView.swift` | Timer display with countdown and controls |
| `Views/PomodoroSessionEndView.swift` | Post-session view with status form and choices |
| `Views/ProjectPickerView.swift` | Project selector for standalone timer start |
| `PomodoroTimer.swift` | Observable timer engine (non-persisted state) |

## Files to Modify

| File | Changes |
|------|---------|
| `BreadcrumbApp.swift` | Dynamic menu bar label/icon based on timer state |
| `ContentView.swift` | Add `.pomodoroRunning` and `.projectPicker` screens, pass timer |
| `ProjectDetailView.swift` | Add "Pomodoro starten" button, show basic stats |
| `ProjectListView.swift` | Add tomato icon to footer |
| `SettingsView.swift` | Add Pomodoro duration and notification settings |
| `Models/Project.swift` | Add `pomodoroSessions` relationship |
| `Models/StatusEntry.swift` | Add optional `pomodoroSession` relationship |
| `project.yml` | Ensure new files are included |

## Verification

1. Start a Pomodoro from project detail → menu bar shows tomato + countdown
2. Click menu bar → timer view fills the window with correct countdown
3. Let timer expire → notification fires, window shows status entry form
4. Fill and save status entry → break timer starts, menu bar shows coffee icon
5. Choose "Weiterarbeiten" instead → timer counts up in orange (+MM:SS)
6. End overtime manually → status entry form appears again
7. Complete 4 work sessions → long break triggers automatically
8. Start standalone timer from footer → project picker appears → timer starts
9. Check project detail → Pomodoro count and total focus time shown
10. Settings → all durations configurable, notification toggles work
11. Quit and reopen → stats persist, no timer running (timer is ephemeral)
