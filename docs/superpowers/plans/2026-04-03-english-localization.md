# English Localization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add English language support with an in-app language selector, translating all ~120 German strings and bilingual Apple Intelligence prompts.

**Architecture:** `@Observable LanguageManager` service injected via `.environment()` (same pattern as existing `PomodoroTimer`, `WindowManager`, `AIService`). A `Strings` case-less enum with nested feature enums holds all translations. Two `@Generable` structs for language-matched AI extraction. Language selector in Settings.

**Tech Stack:** Swift 6.0, SwiftUI, SwiftData, Foundation Models (`@Generable`), xcodegen

---

## File Structure

### New Files
| File | Responsibility |
|------|---------------|
| `Breadcrumb/Models/AppLanguage.swift` | Language enum with `displayName` |
| `Breadcrumb/Services/LanguageManager.swift` | `@Observable` service, reads/writes `UserDefaults` |
| `Breadcrumb/Strings.swift` | All ~120 translated strings organized by feature |
| `BreadcrumbTests/LanguageManagerTests.swift` | Tests for LanguageManager |
| `BreadcrumbTests/StringsTests.swift` | Tests for Strings completeness |

### Modified Files
| File | Change |
|------|--------|
| `Breadcrumb/BreadcrumbApp.swift` | Inject `LanguageManager`, translate menu strings |
| `Breadcrumb/AppDelegate.swift` | Read language from `UserDefaults` for right-click menu |
| `Breadcrumb/WindowManager.swift` | `windowTitle` takes `AppLanguage` parameter |
| `Breadcrumb/Models/ExtractedStatus.swift` | Split into `ExtractedStatusDE` + `ExtractedStatusEN` |
| `Breadcrumb/Services/AIService.swift` | `description(for:)` on error enum, translated availability messages |
| `Breadcrumb/Views/SettingsView.swift` | Add language picker, translate all strings |
| `Breadcrumb/Views/AIExtractButton.swift` | Use language-aware instructions, branch on struct |
| `Breadcrumb/Views/WelcomeView.swift` | Translate all strings |
| `Breadcrumb/Views/ProjectListView.swift` | Translate empty state strings |
| `Breadcrumb/Views/ProjectDetailView.swift` | Translate all strings |
| `Breadcrumb/Views/ProjectFormView.swift` | Translate all strings |
| `Breadcrumb/Views/ProjectRowView.swift` | Translate placeholder string |
| `Breadcrumb/Views/ProjectPickerView.swift` | Translate all strings |
| `Breadcrumb/Views/ArchivedProjectsView.swift` | Translate all strings |
| `Breadcrumb/Views/StatusEntryForm.swift` | Translate all strings |
| `Breadcrumb/Views/HistoryView.swift` | Translate all strings |
| `Breadcrumb/Views/PomodoroRunningView.swift` | Translate all strings including notifications |
| `Breadcrumb/Views/PomodoroSessionEndView.swift` | Translate all strings |
| `Breadcrumb/Views/AboutView.swift` | Translate all strings |
| `Breadcrumb/Views/BreakoutWindowView.swift` | Use translated navigation titles |
| `Breadcrumb/Views/StatsContentView.swift` | Translate all strings |

---

### Task 1: Create AppLanguage Enum and LanguageManager Service

**Files:**
- Create: `Breadcrumb/Models/AppLanguage.swift`
- Create: `Breadcrumb/Services/LanguageManager.swift`
- Create: `BreadcrumbTests/LanguageManagerTests.swift`

- [ ] **Step 1: Write failing tests for LanguageManager**

Create `BreadcrumbTests/LanguageManagerTests.swift`:

```swift
import Testing
import Foundation
@testable import Breadcrumb

@Suite("AppLanguage Tests")
struct AppLanguageTests {

    @Test("AppLanguage has correct raw values")
    func rawValues() {
        #expect(AppLanguage.german.rawValue == "de")
        #expect(AppLanguage.english.rawValue == "en")
    }

    @Test("AppLanguage displayName is native language name")
    func displayNames() {
        #expect(AppLanguage.german.displayName == "Deutsch")
        #expect(AppLanguage.english.displayName == "English")
    }

    @Test("AppLanguage conforms to CaseIterable")
    func caseIterable() {
        #expect(AppLanguage.allCases.count == 2)
    }
}

@Suite("LanguageManager Tests")
@MainActor
struct LanguageManagerTests {

    @Test("Defaults to German when no stored value")
    func defaultLanguage() {
        UserDefaults.standard.removeObject(forKey: "app.language")
        let manager = LanguageManager()
        #expect(manager.language == .german)
    }

    @Test("Reads stored language from UserDefaults")
    func readsStoredLanguage() {
        UserDefaults.standard.set("en", forKey: "app.language")
        let manager = LanguageManager()
        #expect(manager.language == .english)
        // Cleanup
        UserDefaults.standard.removeObject(forKey: "app.language")
    }

    @Test("Persists language change to UserDefaults")
    func persistsChange() {
        UserDefaults.standard.removeObject(forKey: "app.language")
        let manager = LanguageManager()
        manager.language = .english
        #expect(UserDefaults.standard.string(forKey: "app.language") == "en")
        // Cleanup
        UserDefaults.standard.removeObject(forKey: "app.language")
    }

    @Test("Falls back to German for invalid stored value")
    func invalidStoredValue() {
        UserDefaults.standard.set("fr", forKey: "app.language")
        let manager = LanguageManager()
        #expect(manager.language == .german)
        // Cleanup
        UserDefaults.standard.removeObject(forKey: "app.language")
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd /Users/roger/Claude/Code/Breadcrumb && xcodegen generate && xcodebuild test -project Breadcrumb.xcodeproj -scheme Breadcrumb 2>&1 | tail -20`
Expected: FAIL — `AppLanguage` and `LanguageManager` not found

- [ ] **Step 3: Create AppLanguage.swift**

Create `Breadcrumb/Models/AppLanguage.swift`:

```swift
enum AppLanguage: String, CaseIterable {
    case german = "de"
    case english = "en"

    var displayName: String {
        switch self {
        case .german: "Deutsch"
        case .english: "English"
        }
    }
}
```

- [ ] **Step 4: Create LanguageManager.swift**

Create `Breadcrumb/Services/LanguageManager.swift`:

```swift
import Foundation
import Observation

@Observable
@MainActor
final class LanguageManager {
    private static let storageKey = "app.language"

    var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: Self.storageKey)
        }
    }

    init() {
        let stored = UserDefaults.standard.string(forKey: Self.storageKey) ?? "de"
        language = AppLanguage(rawValue: stored) ?? .german
    }
}
```

- [ ] **Step 5: Run xcodegen and tests to verify they pass**

Run: `cd /Users/roger/Claude/Code/Breadcrumb && xcodegen generate && xcodebuild test -project Breadcrumb.xcodeproj -scheme Breadcrumb 2>&1 | tail -20`
Expected: All tests PASS

- [ ] **Step 6: Commit**

```bash
cd /Users/roger/Claude/Code/Breadcrumb
git add Breadcrumb/Models/AppLanguage.swift Breadcrumb/Services/LanguageManager.swift BreadcrumbTests/LanguageManagerTests.swift
git commit -m "feat: add AppLanguage enum and LanguageManager service"
```

---

### Task 2: Create Strings Enum with All Translations

**Files:**
- Create: `Breadcrumb/Strings.swift`
- Create: `BreadcrumbTests/StringsTests.swift`

- [ ] **Step 1: Write failing tests for Strings**

Create `BreadcrumbTests/StringsTests.swift`:

```swift
import Testing
@testable import Breadcrumb

@Suite("Strings Tests")
struct StringsTests {

    @Test("General strings return German for .german")
    func generalGerman() {
        let l = AppLanguage.german
        #expect(Strings.General.back(l) == "Zurück")
        #expect(Strings.General.settings(l) == "Einstellungen")
        #expect(Strings.General.save(l) == "Speichern")
        #expect(Strings.General.cancel(l) == "Abbrechen")
    }

    @Test("General strings return English for .english")
    func generalEnglish() {
        let l = AppLanguage.english
        #expect(Strings.General.back(l) == "Back")
        #expect(Strings.General.settings(l) == "Settings")
        #expect(Strings.General.save(l) == "Save")
        #expect(Strings.General.cancel(l) == "Cancel")
    }

    @Test("Pomodoro strings return correct translations")
    func pomodoroStrings() {
        #expect(Strings.Pomodoro.focusTime(.german) == "Fokuszeit")
        #expect(Strings.Pomodoro.focusTime(.english) == "Focus Time")
        #expect(Strings.Pomodoro.shortBreak(.german) == "Kurze Pause")
        #expect(Strings.Pomodoro.shortBreak(.english) == "Short Break")
    }

    @Test("AI extraction instructions exist for both languages")
    func aiInstructions() {
        let de = Strings.AIExtraction.instructions(.german)
        let en = Strings.AIExtraction.instructions(.english)
        #expect(de.contains("extrahierst"))
        #expect(en.contains("extract"))
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd /Users/roger/Claude/Code/Breadcrumb && xcodegen generate && xcodebuild test -project Breadcrumb.xcodeproj -scheme Breadcrumb 2>&1 | tail -20`
Expected: FAIL — `Strings` not found

- [ ] **Step 3: Create Strings.swift with all translations**

Create `Breadcrumb/Strings.swift`:

```swift
// swiftlint:disable type_body_length file_length
enum Strings {

    // MARK: - General

    enum General {
        static func back(_ l: AppLanguage) -> String {
            l == .german ? "Zurück" : "Back"
        }
        static func settings(_ l: AppLanguage) -> String {
            l == .german ? "Einstellungen" : "Settings"
        }
        static func save(_ l: AppLanguage) -> String {
            l == .german ? "Speichern" : "Save"
        }
        static func cancel(_ l: AppLanguage) -> String {
            l == .german ? "Abbrechen" : "Cancel"
        }
        static func delete(_ l: AppLanguage) -> String {
            l == .german ? "Löschen" : "Delete"
        }
        static func edit(_ l: AppLanguage) -> String {
            l == .german ? "Bearbeiten" : "Edit"
        }
        static func create(_ l: AppLanguage) -> String {
            l == .german ? "Erstellen" : "Create"
        }
        static func quit(_ l: AppLanguage) -> String {
            l == .german ? "Beenden" : "Quit"
        }
        static func about(_ l: AppLanguage) -> String {
            l == .german ? "Über Breadcrumb" : "About Breadcrumb"
        }
        static func settingsEllipsis(_ l: AppLanguage) -> String {
            l == .german ? "Einstellungen..." : "Settings..."
        }
    }

    // MARK: - Projects

    enum Projects {
        static func noProjects(_ l: AppLanguage) -> String {
            l == .german ? "Keine Projekte" : "No Projects"
        }
        static func noProjectsDescription(_ l: AppLanguage) -> String {
            l == .german ? "Erstelle dein erstes Projekt mit dem + Button" : "Create your first project with the + button"
        }
        static func newProject(_ l: AppLanguage) -> String {
            l == .german ? "Neues Projekt" : "New Project"
        }
        static func editProject(_ l: AppLanguage) -> String {
            l == .german ? "Projekt bearbeiten" : "Edit Project"
        }
        static func projectName(_ l: AppLanguage) -> String {
            l == .german ? "Projektname" : "Project Name"
        }
        static func icon(_ l: AppLanguage) -> String {
            l == .german ? "Icon" : "Icon"
        }
        static func archive(_ l: AppLanguage) -> String {
            l == .german ? "Archivieren" : "Archive"
        }
        static func chooseProject(_ l: AppLanguage) -> String {
            l == .german ? "Projekt wählen" : "Choose Project"
        }
        static func withoutProject(_ l: AppLanguage) -> String {
            l == .german ? "Ohne Projekt" : "Without Project"
        }
        static func project(_ l: AppLanguage) -> String {
            l == .german ? "Projekt" : "Project"
        }
        static func noArchivedProjects(_ l: AppLanguage) -> String {
            l == .german ? "Keine archivierten Projekte" : "No Archived Projects"
        }
        static func archivedProjectsDescription(_ l: AppLanguage) -> String {
            l == .german ? "Archivierte Projekte erscheinen hier" : "Archived projects appear here"
        }
        static func archiveTitle(_ l: AppLanguage) -> String {
            l == .german ? "Archiv" : "Archive"
        }
        static func reactivate(_ l: AppLanguage) -> String {
            l == .german ? "Reaktivieren" : "Reactivate"
        }
        static func permanentlyDelete(_ l: AppLanguage) -> String {
            l == .german ? "Endgültig löschen" : "Permanently Delete"
        }
    }

    // MARK: - Status

    enum Status {
        static func updateStatus(_ l: AppLanguage) -> String {
            l == .german ? "Status aktualisieren" : "Update Status"
        }
        static func whereAreYou(_ l: AppLanguage) -> String {
            l == .german ? "Wo stehst du gerade?" : "Where do you stand right now?"
        }
        static func noStatusYet(_ l: AppLanguage) -> String {
            l == .german ? "Noch kein Status erfasst" : "No Status Recorded Yet"
        }
        static func noStatusYetDescription(_ l: AppLanguage) -> String {
            l == .german ? "Halte fest, wo du gerade stehst" : "Record where you currently stand"
        }
        static func noStatus(_ l: AppLanguage) -> String {
            l == .german ? "Noch kein Status" : "No status yet"
        }
        static func currentStatus(_ l: AppLanguage) -> String {
            l == .german ? "Aktueller Stand" : "Current Status"
        }
        static func optionalFields(_ l: AppLanguage) -> String {
            l == .german ? "Optionale Felder" : "Optional Fields"
        }
        static func lastStep(_ l: AppLanguage) -> String {
            l == .german ? "Letzter Schritt" : "Last Step"
        }
        static func nextStep(_ l: AppLanguage) -> String {
            l == .german ? "Nächster Schritt" : "Next Step"
        }
        static func openQuestions(_ l: AppLanguage) -> String {
            l == .german ? "Offene Fragen" : "Open Questions"
        }
        static func noEntries(_ l: AppLanguage) -> String {
            l == .german ? "Keine Einträge" : "No Entries"
        }
        static func noEntriesDescription(_ l: AppLanguage) -> String {
            l == .german ? "Noch keine Status-Einträge vorhanden" : "No status entries yet"
        }
        static func history(_ l: AppLanguage) -> String {
            l == .german ? "Historie" : "History"
        }
    }

    // MARK: - Pomodoro

    enum Pomodoro {
        static func focusTime(_ l: AppLanguage) -> String {
            l == .german ? "Fokuszeit" : "Focus Time"
        }
        static func shortBreak(_ l: AppLanguage) -> String {
            l == .german ? "Kurze Pause" : "Short Break"
        }
        static func longBreak(_ l: AppLanguage) -> String {
            l == .german ? "Lange Pause" : "Long Break"
        }
        static func sessionEnded(_ l: AppLanguage) -> String {
            l == .german ? "Sitzung beendet" : "Session Ended"
        }
        static func overtime(_ l: AppLanguage) -> String {
            l == .german ? "Überstunden" : "Overtime"
        }
        static func resume(_ l: AppLanguage) -> String {
            l == .german ? "Fortsetzen" : "Resume"
        }
        static func pause(_ l: AppLanguage) -> String {
            l == .german ? "Pause" : "Pause"
        }
        static func stop(_ l: AppLanguage) -> String {
            l == .german ? "Stopp" : "Stop"
        }
        static func skip(_ l: AppLanguage) -> String {
            l == .german ? "Überspringen" : "Skip"
        }
        static func pomodoro(_ l: AppLanguage) -> String {
            l == .german ? "Pomodoro" : "Pomodoro"
        }
        static func details(_ l: AppLanguage) -> String {
            l == .german ? "Details" : "Details"
        }
        static func completed(_ l: AppLanguage) -> String {
            l == .german ? "Abgeschlossen" : "Completed"
        }
        static func completedSessions(_ l: AppLanguage) -> String {
            l == .german ? "Abgeschlossene Sitzungen" : "Completed Sessions"
        }
        static func sessionFinished(_ l: AppLanguage) -> String {
            l == .german ? "✅ Sitzung beendet!" : "✅ Session Complete!"
        }
        static func breakOver(_ l: AppLanguage) -> String {
            l == .german ? "☕ Pause vorbei!" : "☕ Break Over!"
        }
        static func readyForNext(_ l: AppLanguage) -> String {
            l == .german ? "Bereit für die nächste Sitzung?" : "Ready for the next session?"
        }
        static func nextSession(_ l: AppLanguage) -> String {
            l == .german ? "Nächste Sitzung" : "Next Session"
        }
        static func stopCompletely(_ l: AppLanguage) -> String {
            l == .german ? "Aufhören" : "Stop"
        }
        static func saveAndBreak(_ l: AppLanguage) -> String {
            l == .german ? "Speichern & Pause" : "Save & Break"
        }
        static func continueWorking(_ l: AppLanguage) -> String {
            l == .german ? "Weiterarbeiten" : "Continue Working"
        }
        static func pomodoroStatistics(_ l: AppLanguage) -> String {
            l == .german ? "Pomodoro-Statistiken" : "Pomodoro Statistics"
        }
        static func focusTimeLabel(_ l: AppLanguage, minutes: Int) -> String {
            l == .german ? "Fokuszeit: \(minutes) Min." : "Focus Time: \(minutes) min"
        }
        static func shortBreakLabel(_ l: AppLanguage, minutes: Int) -> String {
            l == .german ? "Kurze Pause: \(minutes) Min." : "Short Break: \(minutes) min"
        }
        static func longBreakLabel(_ l: AppLanguage, minutes: Int) -> String {
            l == .german ? "Lange Pause: \(minutes) Min." : "Long Break: \(minutes) min"
        }
        static func sessionsBeforeLongBreak(_ l: AppLanguage, count: Int) -> String {
            l == .german ? "Sitzungen bis lange Pause: \(count)" : "Sessions Before Long Break: \(count)"
        }
        static func overtimeSession(_ l: AppLanguage, number: Int) -> String {
            l == .german ? "Überstunden · Sitzung \(number)" : "Overtime · Session \(number)"
        }
        static func focusTimeSession(_ l: AppLanguage, number: Int, total: Int) -> String {
            l == .german ? "Fokuszeit · Sitzung \(number) von \(total)" : "Focus Time · Session \(number) of \(total)"
        }
    }

    // MARK: - Notifications

    enum Notifications {
        static func pomodoroFinishedTitle(_ l: AppLanguage) -> String {
            l == .german ? "Pomodoro beendet!" : "Pomodoro Finished!"
        }
        static func pomodoroFinishedBody(_ l: AppLanguage) -> String {
            l == .german ? "Zeit für eine Pause." : "Time for a break."
        }
        static func breakOverTitle(_ l: AppLanguage) -> String {
            l == .german ? "Pause vorbei!" : "Break Over!"
        }
        static func breakOverBody(_ l: AppLanguage) -> String {
            l == .german ? "Bereit für die nächste Sitzung?" : "Ready for the next session?"
        }
    }

    // MARK: - Settings

    enum Settings {
        static func language(_ l: AppLanguage) -> String {
            l == .german ? "Sprache" : "Language"
        }
        static func general(_ l: AppLanguage) -> String {
            l == .german ? "Allgemein" : "General"
        }
        static func launchAtLogin(_ l: AppLanguage) -> String {
            l == .german ? "Beim Login starten" : "Launch at Login"
        }
        static func notifications(_ l: AppLanguage) -> String {
            l == .german ? "Benachrichtigungen" : "Notifications"
        }
        static func playSound(_ l: AppLanguage) -> String {
            l == .german ? "Ton abspielen" : "Play Sound"
        }
        static func systemNotification(_ l: AppLanguage) -> String {
            l == .german ? "Systembenachrichtigung" : "System Notification"
        }
    }

    // MARK: - Welcome

    enum Welcome {
        static func title(_ l: AppLanguage) -> String {
            l == .german ? "Willkommen bei Breadcrumb" : "Welcome to Breadcrumb"
        }
        static func trackProjects(_ l: AppLanguage) -> String {
            l == .german ? "Projekte verfolgen" : "Track Projects"
        }
        static func trackProjectsDescription(_ l: AppLanguage) -> String {
            l == .german ? "Halte fest, wo du bei jedem Projekt stehst" : "Keep track of where you stand with each project"
        }
        static func pomodoroTimer(_ l: AppLanguage) -> String {
            l == .german ? "Pomodoro-Timer" : "Pomodoro Timer"
        }
        static func pomodoroTimerDescription(_ l: AppLanguage) -> String {
            l == .german ? "Fokussierte Arbeitssitzungen mit Pausen" : "Focused work sessions with breaks"
        }
        static func statusHistory(_ l: AppLanguage) -> String {
            l == .german ? "Status-Historie" : "Status History"
        }
        static func statusHistoryDescription(_ l: AppLanguage) -> String {
            l == .german ? "Sieh dir an, was du wann gemacht hast" : "See what you did and when"
        }
        static func letsGo(_ l: AppLanguage) -> String {
            l == .german ? "Los geht's!" : "Let's Go!"
        }
    }

    // MARK: - About

    enum About {
        static func tagline(_ l: AppLanguage) -> String {
            l == .german
                ? "Behalte den Überblick über deine Projekte.\nFokussiere dich mit dem Pomodoro-Timer."
                : "Keep track of your projects.\nStay focused with the Pomodoro timer."
        }
    }

    // MARK: - Breakout Windows

    enum BreakoutWindows {
        static func historyTitle(_ l: AppLanguage, projectName: String) -> String {
            l == .german ? "Historie — \(projectName)" : "History — \(projectName)"
        }
        static func statsTitle(_ l: AppLanguage, projectName: String) -> String {
            l == .german ? "Statistiken — \(projectName)" : "Statistics — \(projectName)"
        }
    }

    // MARK: - AI Extraction

    enum AIExtraction {
        static func buttonLabel(_ l: AppLanguage) -> String {
            l == .german ? "KI-Extraktion" : "AI Extraction"
        }
        static func extracting(_ l: AppLanguage) -> String {
            l == .german ? "Extrahiere…" : "Extracting…"
        }
        static func instructions(_ l: AppLanguage) -> String {
            switch l {
            case .german:
                return """
                    Du extrahierst aus gesprochenen Statusmeldungen drei Felder.

                    REGELN:
                    - Bleib nah an den Originalworten. Nicht in Fachsprache umformulieren.
                    - Mehrere Punkte pro Feld mit ". " trennen.
                    - Kurze Stichpunkte ohne Pronomen. "UI verbessert" statt "Wir haben die UI verbessert".
                    - lastAction: Was erledigt wurde. Nur Vergangenes.
                    - nextStep: ALLES was geplant, gewünscht oder vorgeschlagen wird. Auch Ideen und Feature-Wünsche. Im Zweifel hierhin.
                    - openQuestions: NUR wenn der User explizit unsicher ist oder eine Frage stellt ("weiß nicht", "bin unsicher", "ob wir X oder Y"). Leerer String wenn nichts unklar ist.

                    BEISPIEL:
                    Input: "Login ist fertig. Als nächstes Dashboard bauen und API anbinden. Bin unsicher ob Redis oder Memcached."
                    lastAction: "Login fertig"
                    nextStep: "Dashboard bauen. API anbinden"
                    openQuestions: "Redis oder Memcached – Entscheidung offen"
                    """
            case .english:
                return """
                    You extract three fields from spoken status updates.

                    RULES:
                    - Stay close to the original words. Don't rephrase into jargon.
                    - Separate multiple points per field with ". ".
                    - Short bullet points without pronouns. "Improved UI" instead of "We improved the UI".
                    - lastAction: What was completed. Past actions only.
                    - nextStep: EVERYTHING planned, desired, or suggested. Including ideas and feature wishes. When in doubt, put it here.
                    - openQuestions: ONLY when the user is explicitly uncertain or asks a question ("don't know", "unsure", "whether X or Y"). Empty string if nothing is unclear.

                    EXAMPLE:
                    Input: "Login is done. Next up build the dashboard and connect the API. Not sure whether Redis or Memcached."
                    lastAction: "Login done"
                    nextStep: "Build dashboard. Connect API"
                    openQuestions: "Redis or Memcached – decision pending"
                    """
            }
        }
    }

    // MARK: - Errors

    enum Errors {
        static func textTooLong(_ l: AppLanguage) -> String {
            l == .german ? "Der Text ist zu lang für die Verarbeitung" : "The text is too long to process"
        }
        static func unsupportedLanguage(_ l: AppLanguage) -> String {
            l == .german ? "Diese Sprache wird nicht unterstützt" : "This language is not supported"
        }
        static func contentNotProcessed(_ l: AppLanguage) -> String {
            l == .german ? "Der Inhalt konnte nicht verarbeitet werden" : "The content could not be processed"
        }
        static func generationFailed(_ l: AppLanguage, message: String) -> String {
            l == .german ? "Fehler bei der Textgenerierung: \(message)" : "Text generation error: \(message)"
        }
        static func deviceNotSupported(_ l: AppLanguage) -> String {
            l == .german ? "Dieses Gerät unterstützt Apple Intelligence nicht" : "This device does not support Apple Intelligence"
        }
        static func enableAppleIntelligence(_ l: AppLanguage) -> String {
            l == .german ? "Bitte aktiviere Apple Intelligence in den Systemeinstellungen" : "Please enable Apple Intelligence in System Settings"
        }
        static func modelLoading(_ l: AppLanguage) -> String {
            l == .german ? "Das KI-Modell wird noch geladen" : "The AI model is still loading"
        }
        static func notAvailable(_ l: AppLanguage) -> String {
            l == .german ? "Apple Intelligence ist nicht verfügbar" : "Apple Intelligence is not available"
        }
        static func requiresMacOS26(_ l: AppLanguage) -> String {
            l == .german ? "Erfordert macOS 26 oder neuer" : "Requires macOS 26 or later"
        }
        static func notSupportedInVersion(_ l: AppLanguage) -> String {
            l == .german ? "Apple Intelligence wird in dieser App-Version nicht unterstützt" : "Apple Intelligence is not supported in this app version"
        }
    }
}
```

- [ ] **Step 4: Run xcodegen and tests to verify they pass**

Run: `cd /Users/roger/Claude/Code/Breadcrumb && xcodegen generate && xcodebuild test -project Breadcrumb.xcodeproj -scheme Breadcrumb 2>&1 | tail -20`
Expected: All tests PASS

- [ ] **Step 5: Commit**

```bash
cd /Users/roger/Claude/Code/Breadcrumb
git add Breadcrumb/Strings.swift BreadcrumbTests/StringsTests.swift
git commit -m "feat: add Strings enum with all German/English translations"
```

---

### Task 3: Inject LanguageManager and Translate App Shell

**Files:**
- Modify: `Breadcrumb/BreadcrumbApp.swift`
- Modify: `Breadcrumb/AppDelegate.swift`
- Modify: `Breadcrumb/WindowManager.swift`
- Modify: `Breadcrumb/Views/BreakoutWindowView.swift`

- [ ] **Step 1: Modify BreadcrumbApp.swift**

Add `LanguageManager` as a `@State` property and inject via `.environment()`. Translate menu strings.

In `BreadcrumbApp.swift`, add after line 10 (`@State private var aiService = AIService()`):
```swift
    @State private var languageManager = LanguageManager()
```

Add `.environment(languageManager)` after each existing `.environment(aiService)` (lines 21 and 36):
```swift
                .environment(languageManager)
```

In `BreadcrumbCommands`, change the struct to accept `languageManager`:
```swift
struct BreadcrumbCommands: Commands {
    @Environment(\.openWindow) private var openWindow
    let windowManager: WindowManager
    let languageManager: LanguageManager

    var body: some Commands {
        CommandGroup(replacing: .appInfo) {
            Button(Strings.General.about(languageManager.language)) {
                windowManager.open(.about)
                openWindow(id: "main")
            }
        }
        CommandGroup(replacing: .appSettings) {
            Button(Strings.General.settingsEllipsis(languageManager.language)) {
                windowManager.open(.settings)
                openWindow(id: "main")
            }
            .keyboardShortcut(",", modifiers: .command)
        }
    }
}
```

Update the `.commands` call in the Window scene to pass `languageManager`:
```swift
        .commands {
            BreadcrumbCommands(windowManager: windowManager, languageManager: languageManager)
        }
```

- [ ] **Step 2: Modify AppDelegate.swift**

`AppDelegate` doesn't have access to `LanguageManager` via environment (it's an `NSApplicationDelegate`, not a SwiftUI view). Read directly from `UserDefaults`:

Replace lines 20-46 (the menu creation block inside `MainActor.assumeIsolated`) with:

```swift
            MainActor.assumeIsolated {
                let menu = NSMenu()

                let stored = UserDefaults.standard.string(forKey: "app.language") ?? "de"
                let language = AppLanguage(rawValue: stored) ?? .german

                let settingsItem = NSMenuItem(
                    title: Strings.General.settingsEllipsis(language),
                    action: #selector(AppDelegate.openSettings),
                    keyEquivalent: ","
                )
                settingsItem.target = NSApp.delegate
                menu.addItem(settingsItem)

                let aboutItem = NSMenuItem(
                    title: Strings.General.about(language),
                    action: #selector(AppDelegate.openAbout),
                    keyEquivalent: ""
                )
                aboutItem.target = NSApp.delegate
                aboutItem.image = NSImage(systemSymbolName: "info.circle", accessibilityDescription: nil)
                menu.addItem(aboutItem)

                menu.addItem(NSMenuItem.separator())

                let quitItem = NSMenuItem(
                    title: Strings.General.quit(language),
                    action: #selector(NSApplication.terminate(_:)),
                    keyEquivalent: "q"
                )
                menu.addItem(quitItem)

                if let view = window.contentView {
                    NSMenu.popUpContextMenu(menu, with: event, for: view)
                }
            }
```

- [ ] **Step 3: Modify WindowManager.swift**

Change `windowTitle` to accept a language parameter. Replace the `windowTitle` computed property (lines 23-30) with:

```swift
    func windowTitle(for language: AppLanguage) -> String {
        switch self {
        case .settings: return Strings.General.settings(language)
        case .about: return Strings.General.about(language)
        case .history: return Strings.Status.history(language)
        case .stats: return Strings.Pomodoro.pomodoroStatistics(language)
        }
    }
```

- [ ] **Step 4: Modify BreakoutWindowView.swift**

Add `LanguageManager` environment and use translated navigation titles.

Add after line 4 (`@Environment(WindowManager.self) private var windowManager`):
```swift
    @Environment(LanguageManager.self) private var languageManager
```

Replace the `contentView(for:)` method (lines 30-44) with:

```swift
    @ViewBuilder
    private func contentView(for content: BreakoutContent) -> some View {
        let l = languageManager.language
        switch content {
        case .settings:
            SettingsView()
                .navigationTitle(Strings.General.settings(l))
        case .about:
            AboutView()
                .navigationTitle(Strings.General.about(l))
        case .history(let project):
            HistoryView(project: project)
                .navigationTitle(Strings.BreakoutWindows.historyTitle(l, projectName: project.name))
        case .stats(let project):
            StatsContentView(project: project)
                .navigationTitle(Strings.BreakoutWindows.statsTitle(l, projectName: project.name))
        }
    }
```

- [ ] **Step 5: Run xcodegen and build to verify compilation**

Run: `cd /Users/roger/Claude/Code/Breadcrumb && xcodegen generate && xcodebuild -project Breadcrumb.xcodeproj -scheme Breadcrumb -configuration Debug build 2>&1 | tail -10`
Expected: BUILD SUCCEEDED

- [ ] **Step 6: Commit**

```bash
cd /Users/roger/Claude/Code/Breadcrumb
git add Breadcrumb/BreadcrumbApp.swift Breadcrumb/AppDelegate.swift Breadcrumb/WindowManager.swift Breadcrumb/Views/BreakoutWindowView.swift
git commit -m "feat: inject LanguageManager and translate app shell"
```

---

### Task 4: Translate Settings and Welcome Views

**Files:**
- Modify: `Breadcrumb/Views/SettingsView.swift`
- Modify: `Breadcrumb/Views/WelcomeView.swift`
- Modify: `Breadcrumb/Views/AboutView.swift`

- [ ] **Step 1: Modify SettingsView.swift — add language picker and translate**

Replace the entire file content with:

```swift
import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @Environment(LanguageManager.self) private var languageManager
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    @AppStorage("pomodoro.workMinutes") private var workMinutes = 25
    @AppStorage("pomodoro.shortBreakMinutes") private var shortBreakMinutes = 5
    @AppStorage("pomodoro.longBreakMinutes") private var longBreakMinutes = 15
    @AppStorage("pomodoro.sessionsBeforeLongBreak") private var sessionsBeforeLongBreak = 4
    @AppStorage("pomodoro.playSound") private var playSound = true
    @AppStorage("pomodoro.showNotification") private var showNotification = true

    var onBack: (() -> Void)? = nil

    var body: some View {
        @Bindable var languageManager = languageManager
        let l = languageManager.language

        VStack(spacing: 0) {
            // Header
            if let onBack {
                HStack {
                    Button(action: onBack) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text(Strings.General.back(l))
                        }
                        .font(.body)
                    }
                    .buttonStyle(ToolbarButtonStyle())

                    Spacer()

                    Text(Strings.General.settings(l))
                        .font(.headline)

                    Spacer()

                    Color.clear.frame(width: 60, height: 1)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }

            // Content
            Form {
                Section(Strings.Settings.language(l)) {
                    Picker(Strings.Settings.language(l), selection: $languageManager.language) {
                        ForEach(AppLanguage.allCases, id: \.self) { lang in
                            Text(lang.displayName).tag(lang)
                        }
                    }
                    .labelsHidden()
                }

                Section(Strings.Settings.general(l)) {
                    Toggle(Strings.Settings.launchAtLogin(l), isOn: $launchAtLogin)
                        .onChange(of: launchAtLogin) { _, newValue in
                            do {
                                if newValue {
                                    try SMAppService.mainApp.register()
                                } else {
                                    try SMAppService.mainApp.unregister()
                                }
                            } catch {
                                launchAtLogin = SMAppService.mainApp.status == .enabled
                            }
                        }
                }

                Section("Pomodoro") {
                    Stepper(Strings.Pomodoro.focusTimeLabel(l, minutes: workMinutes), value: $workMinutes, in: 5...60)
                    Stepper(Strings.Pomodoro.shortBreakLabel(l, minutes: shortBreakMinutes), value: $shortBreakMinutes, in: 1...15)
                    Stepper(Strings.Pomodoro.longBreakLabel(l, minutes: longBreakMinutes), value: $longBreakMinutes, in: 5...30)
                    Stepper(Strings.Pomodoro.sessionsBeforeLongBreak(l, count: sessionsBeforeLongBreak), value: $sessionsBeforeLongBreak, in: 2...8)
                }

                Section(Strings.Settings.notifications(l)) {
                    Toggle(Strings.Settings.playSound(l), isOn: $playSound)
                    Toggle(Strings.Settings.systemNotification(l), isOn: $showNotification)
                }
            }
            .formStyle(.grouped)
        }
    }
}
```

- [ ] **Step 2: Modify WelcomeView.swift**

Replace the entire file content with:

```swift
import SwiftUI

struct WelcomeView: View {
    @Environment(LanguageManager.self) private var languageManager
    var onDismiss: () -> Void

    var body: some View {
        let l = languageManager.language

        VStack(spacing: 20) {
            Spacer()

            Image("BreadcrumbIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .shadow(radius: 6)

            Text(Strings.Welcome.title(l))
                .font(.title2)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 12) {
                featureRow(
                    icon: "bookmark.fill",
                    title: Strings.Welcome.trackProjects(l),
                    description: Strings.Welcome.trackProjectsDescription(l)
                )
                featureRow(
                    icon: "timer",
                    title: Strings.Welcome.pomodoroTimer(l),
                    description: Strings.Welcome.pomodoroTimerDescription(l)
                )
                featureRow(
                    icon: "clock",
                    title: Strings.Welcome.statusHistory(l),
                    description: Strings.Welcome.statusHistoryDescription(l)
                )
            }
            .padding(.horizontal, 24)

            Spacer()

            Button(Strings.Welcome.letsGo(l)) {
                onDismiss()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Spacer()
                .frame(height: 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.accentColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
```

- [ ] **Step 3: Modify AboutView.swift**

Replace the entire file content with:

```swift
import SwiftUI

struct AboutView: View {
    @Environment(LanguageManager.self) private var languageManager
    var onBack: (() -> Void)? = nil

    var body: some View {
        let l = languageManager.language

        VStack(spacing: 0) {
            // Header
            if let onBack {
                HStack {
                    Button(action: onBack) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text(Strings.General.back(l))
                        }
                        .font(.body)
                    }
                    .buttonStyle(ToolbarButtonStyle())

                    Spacer()

                    Text(Strings.General.about(l))
                        .font(.headline)

                    Spacer()

                    Color.clear.frame(width: 60, height: 1)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }

            Spacer()

            // Content
            VStack(spacing: 12) {
                Image("BreadcrumbIcon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(radius: 4)

                Text("Breadcrumb")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(Strings.About.tagline(l))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()
        }
    }
}
```

- [ ] **Step 4: Build to verify compilation**

Run: `cd /Users/roger/Claude/Code/Breadcrumb && xcodegen generate && xcodebuild -project Breadcrumb.xcodeproj -scheme Breadcrumb -configuration Debug build 2>&1 | tail -10`
Expected: BUILD SUCCEEDED

- [ ] **Step 5: Commit**

```bash
cd /Users/roger/Claude/Code/Breadcrumb
git add Breadcrumb/Views/SettingsView.swift Breadcrumb/Views/WelcomeView.swift Breadcrumb/Views/AboutView.swift
git commit -m "feat: translate Settings, Welcome, and About views"
```

---

### Task 5: Translate Project Views

**Files:**
- Modify: `Breadcrumb/Views/ProjectListView.swift`
- Modify: `Breadcrumb/Views/ProjectRowView.swift`
- Modify: `Breadcrumb/Views/ProjectDetailView.swift`
- Modify: `Breadcrumb/Views/ProjectFormView.swift`
- Modify: `Breadcrumb/Views/ProjectPickerView.swift`
- Modify: `Breadcrumb/Views/ArchivedProjectsView.swift`

- [ ] **Step 1: Modify ProjectListView.swift**

Add after line 3 (`struct ProjectListView: View {`), as first property:
```swift
    @Environment(LanguageManager.self) private var languageManager
```

Replace line 46 (`"Keine Projekte",`):
```swift
                        Strings.Projects.noProjects(languageManager.language),
```

Replace line 48 (`description: Text("Erstelle dein erstes Projekt mit dem + Button")`):
```swift
                        description: Text(Strings.Projects.noProjectsDescription(languageManager.language))
```

- [ ] **Step 2: Modify ProjectRowView.swift**

Add after line 3 (`struct ProjectRowView: View {`), before `let project`:
```swift
    @Environment(LanguageManager.self) private var languageManager
```

Replace line 24 (`Text("Noch kein Status")`):
```swift
                    Text(Strings.Status.noStatus(languageManager.language))
```

- [ ] **Step 3: Modify ProjectDetailView.swift**

Add after line 9 (`@Environment(\.openWindow) private var openWindow`):
```swift
    @Environment(LanguageManager.self) private var languageManager
```

Then replace all German strings. The changes — replace each line:

Line 35 `Text("Zurück")` → `Text(Strings.General.back(languageManager.language))`

Line 50 `Button("Bearbeiten", systemImage: "pencil")` → `Button(Strings.General.edit(languageManager.language), systemImage: "pencil")`

Line 57 `Button("Archivieren", systemImage: "archivebox")` → `Button(Strings.Projects.archive(languageManager.language), systemImage: "archivebox")`

Line 62 `Button("Löschen", systemImage: "trash", role: .destructive)` → `Button(Strings.General.delete(languageManager.language), systemImage: "trash", role: .destructive)`

Line 82 `"Noch kein Status erfasst",` → `Strings.Status.noStatusYet(languageManager.language),`

Line 84 `description: Text("Halte fest, wo du gerade stehst")` → `description: Text(Strings.Status.noStatusYetDescription(languageManager.language))`

Line 101 `Label("Pomodoro", systemImage: "timer")` → `Label(Strings.Pomodoro.pomodoro(languageManager.language), systemImage: "timer")`

Line 106 `Button("Status aktualisieren")` → `Button(Strings.Status.updateStatus(languageManager.language))`

Line 113 `Button("Historie")` → `Button(Strings.Status.history(languageManager.language))`

Line 156 `Text("Aktueller Stand")` → `Text(Strings.Status.currentStatus(languageManager.language))`

Line 168 `fieldRow(label: "Letzter Schritt", value: lastAction)` → `fieldRow(label: Strings.Status.lastStep(languageManager.language), value: lastAction)`

Line 171 `fieldRow(label: "Nächster Schritt", value: nextStep)` → `fieldRow(label: Strings.Status.nextStep(languageManager.language), value: nextStep)`

Line 174 `fieldRow(label: "Offene Fragen", value: openQuestions)` → `fieldRow(label: Strings.Status.openQuestions(languageManager.language), value: openQuestions)`

Line 199 `Text("Pomodoro")` → `Text(Strings.Pomodoro.pomodoro(languageManager.language))`

Line 203 `Text("Details")` → `Text(Strings.Pomodoro.details(languageManager.language))`

Line 214 `Text("Abgeschlossen")` → `Text(Strings.Pomodoro.completed(languageManager.language))`

Line 226 `Text("Fokuszeit")` → `Text(Strings.Pomodoro.focusTime(languageManager.language))`

- [ ] **Step 4: Modify ProjectFormView.swift**

Add after line 4 (`struct ProjectFormView: View {`), before `@Environment(\.modelContext)`:
```swift
    @Environment(LanguageManager.self) private var languageManager
```

Replace line 22:
```swift
            Text(isEditing ? Strings.Projects.editProject(languageManager.language) : Strings.Projects.newProject(languageManager.language))
```

Replace line 25:
```swift
            TextField(Strings.Projects.projectName(languageManager.language), text: $name)
```

Replace line 29:
```swift
                Text(Strings.Projects.icon(languageManager.language))
```

Replace line 52:
```swift
                Button(Strings.General.cancel(languageManager.language)) { onDismiss() }
```

Replace line 55:
```swift
                Button(isEditing ? Strings.General.save(languageManager.language) : Strings.General.create(languageManager.language)) { save() }
```

- [ ] **Step 5: Modify ProjectPickerView.swift**

Add after line 4 (`struct ProjectPickerView: View {`), before `@Query`:
```swift
    @Environment(LanguageManager.self) private var languageManager
```

Replace line 18 `Text("Zurück")` → `Text(Strings.General.back(languageManager.language))`

Replace line 26 `Text("Projekt wählen")` → `Text(Strings.Projects.chooseProject(languageManager.language))`

Replace line 44 `Text("Ohne Projekt")` → `Text(Strings.Projects.withoutProject(languageManager.language))`

- [ ] **Step 6: Modify ArchivedProjectsView.swift**

Add after line 4 (`struct ArchivedProjectsView: View {`), before `@Query`:
```swift
    @Environment(LanguageManager.self) private var languageManager
```

Replace line 19 `Text("Zurück")` → `Text(Strings.General.back(languageManager.language))`

Replace line 27 `Text("Archiv")` → `Text(Strings.Projects.archiveTitle(languageManager.language))`

Replace line 41 `"Keine archivierten Projekte",` → `Strings.Projects.noArchivedProjects(languageManager.language),`

Replace line 43 `description: Text("Archivierte Projekte erscheinen hier")` → `description: Text(Strings.Projects.archivedProjectsDescription(languageManager.language))`

Replace line 55 `Button("Reaktivieren", systemImage: "arrow.uturn.left")` → `Button(Strings.Projects.reactivate(languageManager.language), systemImage: "arrow.uturn.left")`

Replace line 59 `Button("Endgültig löschen", systemImage: "trash", role: .destructive)` → `Button(Strings.Projects.permanentlyDelete(languageManager.language), systemImage: "trash", role: .destructive)`

- [ ] **Step 7: Build to verify compilation**

Run: `cd /Users/roger/Claude/Code/Breadcrumb && xcodegen generate && xcodebuild -project Breadcrumb.xcodeproj -scheme Breadcrumb -configuration Debug build 2>&1 | tail -10`
Expected: BUILD SUCCEEDED

- [ ] **Step 8: Commit**

```bash
cd /Users/roger/Claude/Code/Breadcrumb
git add Breadcrumb/Views/ProjectListView.swift Breadcrumb/Views/ProjectRowView.swift Breadcrumb/Views/ProjectDetailView.swift Breadcrumb/Views/ProjectFormView.swift Breadcrumb/Views/ProjectPickerView.swift Breadcrumb/Views/ArchivedProjectsView.swift
git commit -m "feat: translate all project views to support English"
```

---

### Task 6: Translate Status and History Views

**Files:**
- Modify: `Breadcrumb/Views/StatusEntryForm.swift`
- Modify: `Breadcrumb/Views/HistoryView.swift`
- Modify: `Breadcrumb/Views/StatsContentView.swift`

- [ ] **Step 1: Modify StatusEntryForm.swift**

Add after line 4 (`struct StatusEntryForm: View {`), before `let project`:
```swift
    @Environment(LanguageManager.self) private var languageManager
```

Replace line 18 `Text("Status aktualisieren")` → `Text(Strings.Status.updateStatus(languageManager.language))`

Replace line 22 `Text("Wo stehst du gerade?")` → `Text(Strings.Status.whereAreYou(languageManager.language))`

Replace line 42 `DisclosureGroup("Optionale Felder"` → `DisclosureGroup(Strings.Status.optionalFields(languageManager.language)`

Replace line 44 `optionalField(label: "Letzter Schritt", text: $lastAction)` → `optionalField(label: Strings.Status.lastStep(languageManager.language), text: $lastAction)`

Replace line 45 `optionalField(label: "Nächster Schritt", text: $nextStep)` → `optionalField(label: Strings.Status.nextStep(languageManager.language), text: $nextStep)`

Replace line 46 `optionalField(label: "Offene Fragen", text: $openQuestions)` → `optionalField(label: Strings.Status.openQuestions(languageManager.language), text: $openQuestions)`

Replace line 52 `Button("Abbrechen")` → `Button(Strings.General.cancel(languageManager.language))`

Replace line 55 `Button("Speichern")` → `Button(Strings.General.save(languageManager.language))`

- [ ] **Step 2: Modify HistoryView.swift**

Add after line 4 (`struct HistoryView: View {`), before `let project`:
```swift
    @Environment(LanguageManager.self) private var languageManager
```

Replace line 23 `Text("Zurück")` → `Text(Strings.General.back(languageManager.language))`

Replace line 31 `Text("Historie")` → `Text(Strings.Status.history(languageManager.language))`

Replace line 45 `"Keine Einträge",` → `Strings.Status.noEntries(languageManager.language),`

Replace line 47 `description: Text("Noch keine Status-Einträge vorhanden")` → `description: Text(Strings.Status.noEntriesDescription(languageManager.language))`

For `HistoryEntryRow` (line 69), add environment and translate:

Add after `struct HistoryEntryRow: View {`:
```swift
    @Environment(LanguageManager.self) private var languageManager
```

Replace line 80 `detailField(label: "Letzter Schritt"` → `detailField(label: Strings.Status.lastStep(languageManager.language)`

Replace line 83 `detailField(label: "Nächster Schritt"` → `detailField(label: Strings.Status.nextStep(languageManager.language)`

Replace line 86 `detailField(label: "Offene Fragen"` → `detailField(label: Strings.Status.openQuestions(languageManager.language)`

- [ ] **Step 3: Modify StatsContentView.swift**

Add after line 3 (`struct StatsContentView: View {`), before `let project`:
```swift
    @Environment(LanguageManager.self) private var languageManager
```

Replace line 18 `Text("Abgeschlossene Sitzungen")` → `Text(Strings.Pomodoro.completedSessions(languageManager.language))`

Replace line 26 `Text("Fokuszeit")` → `Text(Strings.Pomodoro.focusTime(languageManager.language))`

- [ ] **Step 4: Build to verify compilation**

Run: `cd /Users/roger/Claude/Code/Breadcrumb && xcodegen generate && xcodebuild -project Breadcrumb.xcodeproj -scheme Breadcrumb -configuration Debug build 2>&1 | tail -10`
Expected: BUILD SUCCEEDED

- [ ] **Step 5: Commit**

```bash
cd /Users/roger/Claude/Code/Breadcrumb
git add Breadcrumb/Views/StatusEntryForm.swift Breadcrumb/Views/HistoryView.swift Breadcrumb/Views/StatsContentView.swift
git commit -m "feat: translate status, history, and stats views"
```

---

### Task 7: Translate Pomodoro Views

**Files:**
- Modify: `Breadcrumb/Views/PomodoroRunningView.swift`
- Modify: `Breadcrumb/Views/PomodoroSessionEndView.swift`

- [ ] **Step 1: Modify PomodoroRunningView.swift**

Add after line 6 (`@Environment(PomodoroTimer.self) private var timer`):
```swift
    @Environment(LanguageManager.self) private var languageManager
```

Replace line 61 `Button("Fortsetzen")` → `Button(Strings.Pomodoro.resume(languageManager.language))`

Replace line 64 `Button("Pause")` → `Button(Strings.Pomodoro.pause(languageManager.language))`

Replace line 67 `Button("Stopp")` → `Button(Strings.Pomodoro.stop(languageManager.language))`

Replace line 72 `Button("Überspringen")` → `Button(Strings.Pomodoro.skip(languageManager.language))`

Replace line 90:
```swift
                    sendNotification(title: Strings.Notifications.pomodoroFinishedTitle(languageManager.language), body: Strings.Notifications.pomodoroFinishedBody(languageManager.language))
```

Replace line 94:
```swift
                    sendNotification(title: Strings.Notifications.breakOverTitle(languageManager.language), body: Strings.Notifications.breakOverBody(languageManager.language))
```

Replace the `phaseLabel` computed property (lines 171-183) with:

```swift
    private var phaseLabel: String {
        let l = languageManager.language
        switch timer.currentPhase {
        case .idle: return ""
        case .work:
            if timer.isOvertime {
                return Strings.Pomodoro.overtimeSession(l, number: timer.currentSessionNumber)
            }
            return Strings.Pomodoro.focusTimeSession(l, number: timer.currentSessionNumber, total: sessionsBeforeLong)
        case .shortBreak: return Strings.Pomodoro.shortBreak(l)
        case .longBreak: return Strings.Pomodoro.longBreak(l)
        case .sessionEnded: return Strings.Pomodoro.sessionEnded(l)
        }
    }
```

- [ ] **Step 2: Modify PomodoroSessionEndView.swift**

Add after line 6 (`@Environment(PomodoroTimer.self) private var timer`):
```swift
    @Environment(LanguageManager.self) private var languageManager
```

Replace the `breakEndContent` view (lines 44-56) with:

```swift
    @ViewBuilder
    private var breakEndContent: some View {
        let l = languageManager.language
        Text(Strings.Pomodoro.breakOver(l))
            .font(.headline)
        Text(Strings.Pomodoro.readyForNext(l))
            .font(.subheadline)
            .foregroundStyle(.secondary)

        HStack {
            Button(Strings.Pomodoro.nextSession(l)) { onStartNextSession() }
                .buttonStyle(.borderedProminent)
            Button(Strings.Pomodoro.stopCompletely(l)) { onStopCompletely() }
                .buttonStyle(.bordered)
        }
    }
```

Replace the `workEndContent` view (lines 60-120) with:

```swift
    @ViewBuilder
    private var workEndContent: some View {
        let l = languageManager.language
        Text(Strings.Pomodoro.sessionFinished(l))
            .font(.headline)

        // Project picker for standalone sessions
        if timer.boundProject == nil {
            Picker(Strings.Projects.project(l), selection: $selectedProject) {
                Text(Strings.Projects.withoutProject(l)).tag(nil as Project?)
                ForEach(activeProjects) { project in
                    Label(project.name, systemImage: project.icon)
                        .tag(project as Project?)
                }
            }
        }

        // Status entry form
        VStack(alignment: .leading, spacing: 4) {
            Text(Strings.Status.whereAreYou(l))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            TextEditor(text: $freeText)
                .font(.body)
                .frame(minHeight: 60)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.3))
                )
        }

        AIExtractButton(
            freeText: $freeText,
            lastAction: $lastAction,
            nextStep: $nextStep,
            openQuestions: $openQuestions,
            showOptionalFields: $showOptionalFields
        )

        DisclosureGroup(Strings.Status.optionalFields(l), isExpanded: $showOptionalFields) {
            VStack(spacing: 8) {
                optionalField(label: Strings.Status.lastStep(l), text: $lastAction)
                optionalField(label: Strings.Status.nextStep(l), text: $nextStep)
                optionalField(label: Strings.Status.openQuestions(l), text: $openQuestions)
            }
            .padding(.top, 4)
        }

        HStack {
            Button(Strings.Pomodoro.saveAndBreak(l)) { saveAndBreak() }
                .buttonStyle(.borderedProminent)
                .disabled(selectedProject == nil && timer.boundProject == nil)
            Button(Strings.Pomodoro.continueWorking(l)) { onContinueWorking() }
                .buttonStyle(.bordered)
        }
        HStack(spacing: 16) {
            Button(Strings.Pomodoro.skip(l)) { onSkip() }
            Button(Strings.Pomodoro.stopCompletely(l)) { onStopCompletely() }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .buttonStyle(ToolbarButtonStyle())
    }
```

- [ ] **Step 3: Build to verify compilation**

Run: `cd /Users/roger/Claude/Code/Breadcrumb && xcodegen generate && xcodebuild -project Breadcrumb.xcodeproj -scheme Breadcrumb -configuration Debug build 2>&1 | tail -10`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
cd /Users/roger/Claude/Code/Breadcrumb
git add Breadcrumb/Views/PomodoroRunningView.swift Breadcrumb/Views/PomodoroSessionEndView.swift
git commit -m "feat: translate Pomodoro views and notifications"
```

---

### Task 8: Bilingual AI Extraction

**Files:**
- Modify: `Breadcrumb/Models/ExtractedStatus.swift`
- Modify: `Breadcrumb/Views/AIExtractButton.swift`
- Modify: `Breadcrumb/Services/AIService.swift`

- [ ] **Step 1: Split ExtractedStatus into two language-specific structs**

Replace the entire content of `Breadcrumb/Models/ExtractedStatus.swift` with:

```swift
#if canImport(FoundationModels)
import FoundationModels

@available(macOS 26, *)
@Generable
struct ExtractedStatusDE {
    @Guide(description: "Kurze Überlegung: Was hat der User gesagt? Was ist erledigt, was ist geplant, was ist unklar?")
    var reasoning: String

    @Guide(description: "Was bereits erledigt oder abgeschlossen wurde. Vergangene Aktionen.")
    var lastAction: String

    @Guide(description: "Alles was als Nächstes geplant ist – Schritte, Ideen, Wünsche. Mehrere Punkte mit '. ' trennen.")
    var nextStep: String

    @Guide(description: "Nur echte Unsicherheiten oder explizite Fragen. Leerer String wenn nichts unklar ist.")
    var openQuestions: String
}

@available(macOS 26, *)
@Generable
struct ExtractedStatusEN {
    @Guide(description: "Brief reasoning: What did the user say? What is done, what is planned, what is unclear?")
    var reasoning: String

    @Guide(description: "What was already completed or finished. Past actions.")
    var lastAction: String

    @Guide(description: "Everything planned next – steps, ideas, wishes. Separate multiple points with '. '.")
    var nextStep: String

    @Guide(description: "Only genuine uncertainties or explicit questions. Empty string if nothing is unclear.")
    var openQuestions: String
}
#endif
```

- [ ] **Step 2: Modify AIExtractButton.swift**

Replace the entire content with:

```swift
import SwiftUI

struct AIExtractButton: View {
    @Environment(AIService.self) private var aiService
    @Environment(LanguageManager.self) private var languageManager

    @Binding var freeText: String
    @Binding var lastAction: String
    @Binding var nextStep: String
    @Binding var openQuestions: String
    @Binding var showOptionalFields: Bool

    @State private var errorMessage: String?

    var body: some View {
        #if canImport(FoundationModels)
        if #available(macOS 26, *) {
            extractionContent
        }
        #endif
    }

    #if canImport(FoundationModels)
    @available(macOS 26, *)
    @ViewBuilder
    private var extractionContent: some View {
        let l = languageManager.language
        if aiService.isAvailable && !freeText.trimmingCharacters(in: .whitespaces).isEmpty {
            VStack(spacing: 4) {
                Button {
                    Task { await extract() }
                } label: {
                    if aiService.isGenerating {
                        HStack(spacing: 6) {
                            ProgressView()
                                .controlSize(.small)
                            Text(Strings.AIExtraction.extracting(l))
                                .font(.caption)
                        }
                    } else {
                        Label(Strings.AIExtraction.buttonLabel(l), systemImage: "wand.and.stars")
                            .font(.caption)
                    }
                }
                .buttonStyle(.bordered)
                .disabled(aiService.isGenerating)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption2)
                        .foregroundStyle(.red)
                }
            }
        }
    }

    @available(macOS 26, *)
    private func extract() async {
        errorMessage = nil
        let language = languageManager.language
        let instructions = Strings.AIExtraction.instructions(language)

        do {
            switch language {
            case .german:
                let result: ExtractedStatusDE = try await aiService.generate(
                    prompt: freeText,
                    instructions: instructions,
                    generating: ExtractedStatusDE.self
                )
                applyResult(lastAction: result.lastAction, nextStep: result.nextStep, openQuestions: result.openQuestions)
            case .english:
                let result: ExtractedStatusEN = try await aiService.generate(
                    prompt: freeText,
                    instructions: instructions,
                    generating: ExtractedStatusEN.self
                )
                applyResult(lastAction: result.lastAction, nextStep: result.nextStep, openQuestions: result.openQuestions)
            }
            showOptionalFields = true
        } catch {
            errorMessage = error.localizedDescription
            Task {
                try? await Task.sleep(for: .seconds(4))
                errorMessage = nil
            }
        }
    }

    private func applyResult(lastAction: String, nextStep: String, openQuestions: String) {
        if !lastAction.isEmpty {
            self.lastAction = lastAction
        }
        if !nextStep.isEmpty {
            self.nextStep = nextStep
        }
        if !openQuestions.isEmpty {
            self.openQuestions = openQuestions
        }
    }
    #endif
}
```

- [ ] **Step 3: Modify AIService.swift error descriptions**

Add a `description(for:)` method to `AIServiceError`. Replace the `errorDescription` computed property (lines 17-30) with:

```swift
    var errorDescription: String? {
        description(for: .german)
    }

    func description(for language: AppLanguage) -> String {
        switch self {
        case .notAvailable(let reason):
            return reason
        case .contextWindowExceeded:
            return Strings.Errors.textTooLong(language)
        case .unsupportedLanguage:
            return Strings.Errors.unsupportedLanguage(language)
        case .guardrailViolation:
            return Strings.Errors.contentNotProcessed(language)
        case .generationFailed(let message):
            return Strings.Errors.generationFailed(language, message: message)
        }
    }
```

Replace the `availability` computed property (lines 46-69) to accept language. Since `availability` is used in multiple places, the simplest approach is to make `unavailableReason` language-aware. Replace the `availability` property with:

```swift
    var availability: ServiceAvailability {
        #if canImport(FoundationModels)
        if #available(macOS 26, *) {
            switch SystemLanguageModel.default.availability {
            case .available:
                return .available
            case .unavailable(.deviceNotEligible):
                return .unavailable("deviceNotEligible")
            case .unavailable(.appleIntelligenceNotEnabled):
                return .unavailable("appleIntelligenceNotEnabled")
            case .unavailable(.modelNotReady):
                return .unavailable("modelNotReady")
            case .unavailable:
                return .unavailable("unavailable")
            @unknown default:
                return .unavailable("unavailable")
            }
        } else {
            return .unavailable("requiresMacOS26")
        }
        #else
        return .unavailable("notSupportedInVersion")
        #endif
    }
```

Replace the `unavailableReason` property (lines 192-197) with:

```swift
    private var unavailableReason: String {
        if case .unavailable(let reason) = availability {
            return reason
        }
        return "unavailable"
    }

    func localizedUnavailableReason(for language: AppLanguage) -> String {
        if case .unavailable(let key) = availability {
            switch key {
            case "deviceNotEligible": return Strings.Errors.deviceNotSupported(language)
            case "appleIntelligenceNotEnabled": return Strings.Errors.enableAppleIntelligence(language)
            case "modelNotReady": return Strings.Errors.modelLoading(language)
            case "requiresMacOS26": return Strings.Errors.requiresMacOS26(language)
            case "notSupportedInVersion": return Strings.Errors.notSupportedInVersion(language)
            default: return Strings.Errors.notAvailable(language)
            }
        }
        return Strings.Errors.notAvailable(language)
    }
```

- [ ] **Step 4: Build and run tests**

Run: `cd /Users/roger/Claude/Code/Breadcrumb && xcodegen generate && xcodebuild test -project Breadcrumb.xcodeproj -scheme Breadcrumb 2>&1 | tail -20`
Expected: All tests PASS, BUILD SUCCEEDED

- [ ] **Step 5: Commit**

```bash
cd /Users/roger/Claude/Code/Breadcrumb
git add Breadcrumb/Models/ExtractedStatus.swift Breadcrumb/Views/AIExtractButton.swift Breadcrumb/Services/AIService.swift
git commit -m "feat: bilingual AI extraction with language-matched prompts and guides"
```

---

### Task 9: Final Build, Test, and Verify

**Files:** None (verification only)

- [ ] **Step 1: Run full test suite**

Run: `cd /Users/roger/Claude/Code/Breadcrumb && xcodegen generate && xcodebuild test -project Breadcrumb.xcodeproj -scheme Breadcrumb 2>&1 | tail -30`
Expected: All tests PASS

- [ ] **Step 2: Verify no remaining German hardcoded strings in views**

Run a grep to find any remaining hardcoded German strings that might have been missed. Search for common German words in view files:

```bash
cd /Users/roger/Claude/Code/Breadcrumb
grep -rn '"Zurück\|"Einstellungen\|"Speichern\|"Abbrechen\|"Löschen\|"Bearbeiten\|"Erstellen\|"Beenden\|"Archiv\|"Keine \|"Noch kein\|"Fokuszeit"\|"Pause"\|"Sitzung\|"Überspringen\|"Fortsetzen\|"Stopp"\|"Aufhören\|"Pomodoro beendet\|"Pause vorbei\|"Projekt' Breadcrumb/Views/ Breadcrumb/BreadcrumbApp.swift Breadcrumb/AppDelegate.swift Breadcrumb/WindowManager.swift Breadcrumb/Services/AIService.swift || echo "No remaining hardcoded German strings found"
```
Expected: No matches (or only matches inside `Strings.swift`)

- [ ] **Step 3: Verify Strings.swift has no duplicates or typos**

Quick sanity check — build and confirm no warnings:

Run: `cd /Users/roger/Claude/Code/Breadcrumb && xcodebuild -project Breadcrumb.xcodeproj -scheme Breadcrumb -configuration Release build 2>&1 | tail -10`
Expected: BUILD SUCCEEDED
