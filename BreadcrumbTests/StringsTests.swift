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
        #expect(Strings.Pomodoro.configureSession(.german) == "Sitzung konfigurieren")
        #expect(Strings.Pomodoro.configureSession(.english) == "Configure Session")
        #expect(Strings.Pomodoro.startSession(.german) == "Sitzung starten")
        #expect(Strings.Pomodoro.startSession(.english) == "Start Session")
    }

    @Test("AI extraction instructions exist for both languages")
    func aiInstructions() {
        let de = Strings.AIExtraction.instructions(.german)
        let en = Strings.AIExtraction.instructions(.english)
        #expect(de.contains("Extrahiere"))
        #expect(en.contains("Extract"))
    }

    @Test("Total sessions strings")
    func totalSessionsStrings() {
        #expect(Strings.Pomodoro.totalSessionsLabel(.german, count: 4) == "Gesamtsitzungen: 4")
        #expect(Strings.Pomodoro.totalSessionsLabel(.english, count: 4) == "Total Sessions: 4")
        #expect(Strings.Pomodoro.allSessionsComplete(.german) == "Alle Sitzungen abgeschlossen!")
        #expect(Strings.Pomodoro.allSessionsComplete(.english) == "All Sessions Complete!")
    }

    @Test("FocusMate strings")
    func focusMateStrings() {
        #expect(Strings.Pomodoro.pomodoroMode(.english) == "Pomodoro")
        #expect(Strings.Pomodoro.focusMateMode(.english) == "FocusMate")
        #expect(Strings.Pomodoro.focusMateLength(.german) == "Sitzungslänge")
        #expect(Strings.Pomodoro.focusMateLength(.english) == "Session Length")
        #expect(Strings.Pomodoro.focusMateMinutesOption(.german, minutes: 25) == "25 Min.")
        #expect(Strings.Pomodoro.focusMateMinutesOption(.english, minutes: 25) == "25 min")
        #expect(Strings.Pomodoro.focusMateSessionStart(.english) == "Session Start")
        #expect(Strings.Pomodoro.focusMateSessionStart(.german) == "Sitzungsbeginn")
        #expect(Strings.Pomodoro.focusMateEndsAt(.english, time: "11:05") == "Ends at 11:05")
        #expect(Strings.Pomodoro.focusMateEndsAt(.german, time: "11:05") == "Endet um 11:05")
        #expect(Strings.Pomodoro.focusMateComplete(.english).contains("FocusMate"))
        #expect(Strings.Pomodoro.saveAndDone(.english) == "Save & Done")
        #expect(Strings.Pomodoro.saveAndDone(.german) == "Speichern & Fertig")
    }

    @Test("Overtime notification strings")
    func overtimeNotificationStrings() {
        #expect(Strings.Notifications.overtimeNotificationBody(.english).contains("overtime"))
        #expect(Strings.Notifications.overtimeNotificationBody(.german).contains("Überstunden"))
    }

    @Test("Documents strings return correct translations")
    func documentsStrings() {
        #expect(Strings.Documents.documents(.german) == "Dokumente")
        #expect(Strings.Documents.documents(.english) == "Documents")
        #expect(Strings.Documents.addFile(.german) == "Datei hinzufügen…")
        #expect(Strings.Documents.addFile(.english) == "Add File…")
        #expect(Strings.Documents.addURL(.german) == "Link hinzufügen…")
        #expect(Strings.Documents.addURL(.english) == "Add URL…")
        #expect(Strings.Documents.fileNotFound(.german) == "Datei nicht gefunden")
        #expect(Strings.Documents.fileNotFound(.english) == "File not found")
        #expect(Strings.Documents.editLabel(.german) == "Bezeichnung bearbeiten")
        #expect(Strings.Documents.editLabel(.english) == "Edit Label")
        #expect(Strings.Documents.urlPlaceholder(.german) == "URL eingeben")
        #expect(Strings.Documents.urlPlaceholder(.english) == "Enter URL")
        #expect(Strings.Documents.labelPlaceholder(.german) == "Bezeichnung (optional)")
        #expect(Strings.Documents.labelPlaceholder(.english) == "Label (optional)")
    }

    @Test("Notification settings strings")
    func notificationSettingsStrings() {
        #expect(Strings.Settings.soundWorkDone(.english) == "Work done sound")
        #expect(Strings.Settings.soundWorkDone(.german) == "Ton bei Arbeitsende")
        #expect(Strings.Settings.soundBreakDone(.english) == "Break done sound")
        #expect(Strings.Settings.soundBreakDone(.german) == "Ton bei Pausenende")
        #expect(Strings.Settings.soundOvertime(.english) == "Overtime sound")
        #expect(Strings.Settings.soundOvertime(.german) == "Ton bei Überstunden")
        #expect(Strings.Settings.showBannerNotification(.english) == "Show banner notification")
        #expect(Strings.Settings.showBannerNotification(.german) == "Bannerbenachrichtigung anzeigen")
        #expect(Strings.Settings.autoOpenPopover(.english) == "Auto-open popover")
        #expect(Strings.Settings.autoOpenPopover(.german) == "Popover automatisch öffnen")
        #expect(Strings.Settings.previewSound(.english) == "Preview")
        #expect(Strings.Settings.previewSound(.german) == "Vorschau")
        #expect(Strings.Settings.noSound(.english) == "None")
        #expect(Strings.Settings.noSound(.german) == "Kein Ton")
    }

    @Test("Snooze strings")
    func snoozeStrings() {
        #expect(Strings.Pomodoro.snooze5(.english) == "+5 min")
        #expect(Strings.Pomodoro.snooze5(.german) == "+5 Min.")
        #expect(Strings.Pomodoro.snooze10(.english) == "+10 min")
        #expect(Strings.Pomodoro.snooze10(.german) == "+10 Min.")
    }

    @Test("AI settings strings return correct translations")
    func aiSettingsStrings() {
        #expect(Strings.Settings.aiProvider(.german) == "KI-Anbieter")
        #expect(Strings.Settings.aiProvider(.english) == "AI Provider")
        #expect(Strings.Settings.aiProviderLocal(.german) == "Apple KI")
        #expect(Strings.Settings.aiProviderLocal(.english) == "Apple AI")
        #expect(Strings.Settings.aiProviderOpenRouter(.german) == "OpenRouter")
        #expect(Strings.Settings.aiProviderOpenRouter(.english) == "OpenRouter")
        #expect(Strings.Settings.apiKey(.german) == "API-Schlüssel")
        #expect(Strings.Settings.apiKey(.english) == "API Key")
        #expect(Strings.Settings.model(.german) == "Modell")
        #expect(Strings.Settings.model(.english) == "Model")
        #expect(Strings.Settings.apiKeyPlaceholder(.german) == "OpenRouter API-Schlüssel eingeben")
        #expect(Strings.Settings.apiKeyPlaceholder(.english) == "Enter OpenRouter API key")
        #expect(Strings.Settings.modelPlaceholder(.german) == "z. B. anthropic/claude-sonnet-4")
        #expect(Strings.Settings.modelPlaceholder(.english) == "e.g. anthropic/claude-sonnet-4")
        #expect(Strings.Settings.apiKeyHelp(.german).contains("openrouter.ai"))
        #expect(Strings.Settings.apiKeyHelp(.english).contains("openrouter.ai"))
        #expect(Strings.Settings.modelHelp(.german).contains("Modell-ID"))
        #expect(Strings.Settings.modelHelp(.english).contains("model ID"))
        #expect(Strings.Settings.aiReady(.german) == "Bereit")
        #expect(Strings.Settings.aiReady(.english) == "Ready")
        #expect(Strings.Settings.aiNotConfigured(.german) == "Nicht konfiguriert")
        #expect(Strings.Settings.aiNotConfigured(.english) == "Not configured")
    }

    @Test("AI error strings for new error cases")
    func aiErrorStrings() {
        #expect(Strings.Errors.networkError(.german, message: "timeout").contains("Netzwerk"))
        #expect(Strings.Errors.networkError(.english, message: "timeout").contains("Network"))
        #expect(Strings.Errors.authenticationFailed(.german).contains("API"))
        #expect(Strings.Errors.authenticationFailed(.english).contains("API"))
        #expect(Strings.Errors.invalidResponse(.german).contains("Antwort"))
        #expect(Strings.Errors.invalidResponse(.english).contains("response"))
    }

    @Test("Status.addBullet returns correct translations")
    func statusAddBullet() {
        #expect(Strings.Status.addBullet(.german) == "Aufzählungspunkt hinzufügen")
        #expect(Strings.Status.addBullet(.english) == "Add bullet")
    }
}
