# English Localization Design

**Date:** 2026-04-03
**Scope:** Add English language support with in-app language selector

## Overview

The Breadcrumb app is currently 100% hardcoded German. This design adds English as a second language with an in-app toggle in Settings. The app manages its own translations via an `@Observable LanguageManager` — no Apple localization infrastructure (String Catalogs / .xcstrings).

## Design Decisions

- **App-internal language setting** (not system language). A picker in Settings stores the preference in `UserDefaults`. Simple, self-contained, appropriate for a small menu bar utility with two languages.
- **AI instructions follow app language.** The on-device Foundation Models model is 3B parameters — mixed-language signals (e.g., English `@Guide` + German prompt) risk inconsistent behavior. All AI-facing text must be in the same language.
- **Two `@Generable` structs** (`ExtractedStatusDE` / `ExtractedStatusEN`) to keep `@Guide` descriptions language-consistent, since `@Guide` is a compile-time annotation.

## Architecture

### New Files

#### `AppLanguage.swift` (Models/)

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

#### `LanguageManager.swift` (Services/)

`@Observable @MainActor final class` — same pattern as `PomodoroTimer`, `WindowManager`, `AIService`.

```swift
@Observable @MainActor
final class LanguageManager {
    private static let storageKey = "app.language"

    var language: AppLanguage {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: Self.storageKey) }
    }

    init() {
        let stored = UserDefaults.standard.string(forKey: Self.storageKey) ?? "de"
        language = AppLanguage(rawValue: stored) ?? .german
    }
}
```

Injected in `BreadcrumbApp.swift` via `.environment()` alongside the existing 3 services.

#### `Strings.swift`

Case-less enum with nested case-less enums per feature area. All ~120 strings in one file.

```swift
enum Strings {
    enum General {
        static func back(_ language: AppLanguage) -> String {
            language == .german ? "Zurueck" : "Back"
        }
        static func settings(_ language: AppLanguage) -> String {
            language == .german ? "Einstellungen" : "Settings"
        }
        static func save(_ language: AppLanguage) -> String {
            language == .german ? "Speichern" : "Save"
        }
        static func cancel(_ language: AppLanguage) -> String {
            language == .german ? "Abbrechen" : "Cancel"
        }
        static func delete(_ language: AppLanguage) -> String {
            language == .german ? "Loeschen" : "Delete"
        }
        static func edit(_ language: AppLanguage) -> String {
            language == .german ? "Bearbeiten" : "Edit"
        }
        static func create(_ language: AppLanguage) -> String {
            language == .german ? "Erstellen" : "Create"
        }
        static func quit(_ language: AppLanguage) -> String {
            language == .german ? "Beenden" : "Quit"
        }
        // ... remaining shared strings
    }
    enum Projects { /* project-related strings */ }
    enum Pomodoro { /* timer and session strings */ }
    enum Status { /* status entry strings */ }
    enum Welcome { /* onboarding strings */ }
    enum Settings { /* settings labels */ }
    enum Notifications { /* notification titles/bodies */ }
    enum AIExtraction { /* AI prompts, labels, instructions */ }
    enum About { /* about view strings */ }
    enum Errors { /* AIService error messages */ }
}
```

### Modified Files

#### `ExtractedStatus.swift` — Split into Two Structs

Replace single `ExtractedStatus` with `ExtractedStatusDE` and `ExtractedStatusEN`. Same field names, language-matched `@Guide` descriptions.

```swift
@Generable
struct ExtractedStatusDE {
    @Guide(description: "Kurze Ueberlegung: Was hat der User gesagt? Was ist erledigt, was ist geplant, was ist unklar?")
    var reasoning: String
    @Guide(description: "Was bereits erledigt oder abgeschlossen wurde. Vergangene Aktionen.")
    var lastAction: String
    @Guide(description: "Alles was als Naechstes geplant ist - Schritte, Ideen, Wuensche. Mehrere Punkte mit '. ' trennen.")
    var nextStep: String
    @Guide(description: "Nur echte Unsicherheiten oder explizite Fragen. Leerer String wenn nichts unklar ist.")
    var openQuestions: String
}

@Generable
struct ExtractedStatusEN {
    @Guide(description: "Brief reasoning: What did the user say? What is done, what is planned, what is unclear?")
    var reasoning: String
    @Guide(description: "What was already completed or finished. Past actions.")
    var lastAction: String
    @Guide(description: "Everything planned next - steps, ideas, wishes. Separate multiple points with '. '.")
    var nextStep: String
    @Guide(description: "Only genuine uncertainties or explicit questions. Empty string if nothing is unclear.")
    var openQuestions: String
}
```

Both structs share the same field names (`reasoning`, `lastAction`, `nextStep`, `openQuestions`), so the extraction result is mapped to local variables the same way regardless of which struct was used. This is handled with a simple local helper or inline in `AIExtractButton.extract()`.

#### `AIExtractButton.swift`

- Add `@Environment(LanguageManager.self)`
- Replace static `instructions` with `Strings.AIExtraction.instructions(language)`
- Branch on language to use `ExtractedStatusDE` or `ExtractedStatusEN` in the `generate()` call
- Replace German UI labels ("KI-Extraktion", "Extrahiere...") with `Strings.AIExtraction.*`

#### `AIService.swift`

- `AIServiceError` gets a `func description(for language: AppLanguage) -> String` method
- Availability check messages moved to `Strings.Errors`
- Views that catch errors use `error.description(for: languageManager.language)`

#### `SettingsView.swift`

- Add `@Environment(LanguageManager.self)`
- Add language picker section at the top (before "Allgemein"):
  ```swift
  Section(Strings.Settings.language(languageManager.language)) {
      Picker(selection: $languageManager.language) {
          ForEach(AppLanguage.allCases, id: \.self) { lang in
              Text(lang.displayName).tag(lang)
          }
      }
      .labelsHidden()
  }
  ```
- Replace all German strings with `Strings.Settings.*` calls

#### `BreadcrumbApp.swift`

- Create `@State private var languageManager = LanguageManager()`
- Add `.environment(languageManager)` to both scenes
- Replace German menu item strings with `Strings.*` calls

#### All View Files (~20 files)

Each view gets:
1. `@Environment(LanguageManager.self) private var languageManager`
2. All hardcoded German strings replaced with `Strings.Feature.key(languageManager.language)`

No structural changes — purely string replacements.

**Full list of view files to migrate:**

- `BreadcrumbApp.swift`
- `AppDelegate.swift`
- `ContentView.swift`
- `ProjectListView.swift`
- `ProjectDetailView.swift`
- `ProjectRowView.swift`
- `ProjectFormView.swift`
- `ProjectPickerView.swift`
- `ArchivedProjectsView.swift`
- `StatusEntryForm.swift`
- `HistoryView.swift`
- `PomodoroRunningView.swift`
- `PomodoroSessionEndView.swift`
- `SettingsView.swift`
- `AboutView.swift`
- `WelcomeView.swift`
- `WindowManager.swift`
- `BreakoutWindowView.swift`
- `AIExtractButton.swift`
- `AIService.swift`
- `StatsContentView.swift`

### Notification Strings

Pomodoro notifications in `PomodoroRunningView.swift` use `UNNotificationContent`. Since the view already has `LanguageManager` via environment, it passes the current language when building notifications:

```swift
content.title = Strings.Notifications.pomodoroFinishedTitle(languageManager.language)
content.body = Strings.Notifications.pomodoroFinishedBody(languageManager.language)
```

## What This Design Does NOT Do

- No Apple String Catalogs or `.xcstrings` files
- No system language detection
- No third language support (just German + English)
- No model property changes (SwiftData models have no German text)
- No migration needed (purely additive)
