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

    @Test("Timer banner and collapse strings exist for both languages")
    func bannerStrings() {
        #expect(Strings.Pomodoro.collapseToBanner(.german) == "Timer einklappen")
        #expect(Strings.Pomodoro.collapseToBanner(.english) == "Collapse timer")
        #expect(Strings.Pomodoro.showTimer(.german) == "Timer anzeigen")
        #expect(Strings.Pomodoro.showTimer(.english) == "Show timer")
    }

    @Test("Wrap-up buffer formats seconds as M:SS")
    func wrapUpBufferFormatsMinutesSeconds() {
        #expect(Strings.Pomodoro.wrapUpBuffer(.english, seconds: 90).contains("1:30"))
        #expect(Strings.Pomodoro.wrapUpBuffer(.english, seconds: 30).contains("0:30"))
        #expect(Strings.Pomodoro.wrapUpBuffer(.german, seconds: 650).contains("10:50"))
    }

    @Test("AI extraction instructions exist for both languages")
    func aiInstructions() {
        let de = Strings.AIExtraction.instructions(.german)
        let en = Strings.AIExtraction.instructions(.english)
        #expect(de.contains("Extrahiere"))
        #expect(en.contains("Extract"))
    }

    @Test("Per-field AI extraction instructions contain locale and focus keyword")
    func perFieldAIInstructions() {
        let la = Strings.AIExtraction.lastActionInstructions(.german)
        #expect(la.contains("finished"))
        #expect(la.contains("de_DE"))

        let ns = Strings.AIExtraction.nextStepInstructions(.english)
        #expect(ns.contains("planned"))
        #expect(!ns.contains("de_DE"))
    }

    @Test("Total sessions strings")
    func totalSessionsStrings() {
        #expect(Strings.Pomodoro.totalSessionsLabel(.german, count: 4) == "Fokus-Sitzungen: 4")
        #expect(Strings.Pomodoro.totalSessionsLabel(.english, count: 4) == "Focus sessions: 4")
        #expect(Strings.Pomodoro.allSessionsComplete(.german) == "Alle Sitzungen abgeschlossen!")
        #expect(Strings.Pomodoro.allSessionsComplete(.english) == "All Sessions Complete!")
    }

    @Test("Sessions before long break relabel")
    func sessionsBeforeLongBreakStrings() {
        #expect(Strings.Pomodoro.sessionsBeforeLongBreak(.german, count: 4) == "Lange Pause nach: 4 Sitzungen")
        #expect(Strings.Pomodoro.sessionsBeforeLongBreak(.english, count: 4) == "Long break after: 4 sessions")
    }

    @Test("Cycle summary formats duration and singular variant")
    func cycleSummaryStrings() {
        // 4 sessions × 25 min focus, totalMinutes 115 -> "1 h 55 min" / "1 Std. 55 Min."
        let en = Strings.Pomodoro.cycleSummary(.english, sessions: 4, workMinutes: 25, totalMinutes: 115)
        #expect(en.contains("1 h 55 min"))
        let de = Strings.Pomodoro.cycleSummary(.german, sessions: 4, workMinutes: 25, totalMinutes: 115)
        #expect(de.contains("1 Std. 55 Min."))
        // sessions == 1 -> singular variant, no duration
        #expect(Strings.Pomodoro.cycleSummary(.english, sessions: 1, workMinutes: 25, totalMinutes: 25)
            == "Your cycle: one 25 min focus session.")
        #expect(Strings.Pomodoro.cycleSummary(.german, sessions: 1, workMinutes: 25, totalMinutes: 25)
            == "Dein Durchgang: 1 Fokus-Sitzung à 25 Min.")
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

    @Test("FocusMate question strings")
    func focusMateQuestionStrings() {
        #expect(Strings.FocusMateQuestion.title(.german) == "Nutzt du FocusMate?")
        #expect(Strings.FocusMateQuestion.title(.english) == "Are you a FocusMate user?")
        #expect(Strings.FocusMateQuestion.yes(.german) == "Ja")
        #expect(Strings.FocusMateQuestion.yes(.english) == "Yes")
        #expect(Strings.FocusMateQuestion.no(.german) == "Nein")
        #expect(Strings.FocusMateQuestion.no(.english) == "No")
        #expect(Strings.FocusMateQuestion.explanation(.german).contains("FocusMate"))
        #expect(Strings.FocusMateQuestion.explanation(.english).contains("FocusMate"))
        #expect(Strings.FocusMateQuestion.linkLabel(.german).contains("FocusMate"))
        #expect(Strings.FocusMateQuestion.linkLabel(.english).contains("FocusMate"))
    }

    @Test("FocusMate settings strings")
    func focusMateSettingsStrings() {
        #expect(Strings.Settings.focusMateUser(.german) == "FocusMate-Modus")
        #expect(Strings.Settings.focusMateUser(.english) == "FocusMate mode")
        #expect(Strings.Settings.focusMateUserCaption(.german).contains("FocusMate"))
        #expect(Strings.Settings.focusMateUserCaption(.english).contains("FocusMate"))
        #expect(Strings.Settings.focusMateLink(.german).contains("focusmate.com"))
        #expect(Strings.Settings.focusMateLink(.english).contains("focusmate.com"))
    }

    @Test("Show intro again strings exist for both languages")
    func showIntroAgainStrings() {
        #expect(Strings.Settings.showIntroAgain(.german) == "Intro erneut anzeigen")
        #expect(Strings.Settings.showIntroAgain(.english) == "Show Intro Again")
        #expect(!Strings.Settings.showIntroAgainCaption(.german).isEmpty)
        #expect(!Strings.Settings.showIntroAgainCaption(.english).isEmpty)
        #expect(!Strings.Settings.introResetDone(.german).isEmpty)
        #expect(!Strings.Settings.introResetDone(.english).isEmpty)
    }

    @Test("Session end presentation strings")
    func sessionEndPresentationStrings() {
        #expect(Strings.Pomodoro.sessionEndedOpenPromptTitle(.english) == "Session ended")
        #expect(Strings.Pomodoro.sessionEndedOpenPromptTitle(.german) == "Sitzung beendet")
        #expect(Strings.Pomodoro.sessionEndedOpenPromptMessage(.english) == "Save or choose what happens next.")
        #expect(Strings.Pomodoro.sessionEndedOpenPromptMessage(.german) == "Speichere oder wähle, was als Nächstes passiert.")
        #expect(Strings.Pomodoro.openSessionEndPrompt(.english) == "Open Prompt")
        #expect(Strings.Pomodoro.openSessionEndPrompt(.german) == "Dialog öffnen")
    }

    @Test("Completion notification strings")
    func completionNotificationStrings() {
        #expect(Strings.Notifications.pomodoroFinishedBody(.english) == "Time for a break")
        #expect(Strings.Notifications.pomodoroFinishedBody(.german) == "Zeit für eine Pause")
        #expect(Strings.Notifications.sessionCompleteBody(.english) == "Session complete")
        #expect(Strings.Notifications.sessionCompleteBody(.german) == "Sitzung abgeschlossen")
        #expect(Strings.Notifications.allSessionsCompleteBody(.english) == "All sessions complete")
        #expect(Strings.Notifications.allSessionsCompleteBody(.german) == "Alle Sitzungen abgeschlossen")
        #expect(Strings.Notifications.focusMateFinishedTitle(.english) == "FocusMate Finished!")
        #expect(Strings.Notifications.focusMateFinishedTitle(.german) == "FocusMate beendet!")
        #expect(Strings.Notifications.actionContinueWorking(.english) == "Continue working")
        #expect(Strings.Notifications.actionContinueWorking(.german) == "Weiterarbeiten")
        #expect(Strings.Notifications.actionStop(.english) == "Stop")
        #expect(Strings.Notifications.actionStop(.german) == "Stopp")
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
        #expect(Strings.Settings.soundWorkDone(.english) == "Sound when focus ends")
        #expect(Strings.Settings.soundWorkDone(.german) == "Ton bei Sitzungsende")
        #expect(Strings.Settings.soundBreakDone(.english) == "Sound when break ends")
        #expect(Strings.Settings.soundBreakDone(.german) == "Ton bei Pausenende")
        #expect(Strings.Settings.showBannerNotification(.english) == "Show banner notification")
        #expect(Strings.Settings.showBannerNotification(.german) == "Bannerbenachrichtigung anzeigen")
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
        #expect(Strings.Settings.aiProvider(.german) == "Anbieter")
        #expect(Strings.Settings.aiProvider(.english) == "Provider")
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
        #expect(Strings.Settings.apiKeySaveFailed(.german) == "API-Schlüssel konnte nicht gespeichert werden.")
        #expect(Strings.Settings.apiKeySaveFailed(.english) == "Could not save API key.")
        #expect(Strings.Settings.modelHelp(.german).contains("Modell-ID"))
        #expect(Strings.Settings.modelHelp(.english).contains("model ID"))
        #expect(Strings.Settings.aiReady(.german) == "Bereit")
        #expect(Strings.Settings.aiReady(.english) == "Ready")
        #expect(Strings.Settings.aiNotConfigured(.german) == "Nicht konfiguriert")
        #expect(Strings.Settings.aiNotConfigured(.english) == "Not configured")
    }

    @Test("Settings redesign strings return correct translations")
    func settingsRedesignStrings() {
        // Tab labels
        #expect(Strings.Settings.timerTab(.german) == "Timer")
        #expect(Strings.Settings.timerTab(.english) == "Timer")
        #expect(Strings.Settings.notificationsTab(.german) == "Mitteilungen")
        #expect(Strings.Settings.notificationsTab(.english) == "Notifications")

        // Notification tab group headers
        #expect(Strings.Settings.soundsGroup(.german) == "Töne")
        #expect(Strings.Settings.soundsGroup(.english) == "Sounds")
        #expect(Strings.Settings.bannerGroup(.german) == "Banner")
        #expect(Strings.Settings.bannerGroup(.english) == "Banner")

        // AI status row
        #expect(Strings.Settings.aiStatus(.german) == "Status")
        #expect(Strings.Settings.aiStatus(.english) == "Status")

        // Session end wording
        #expect(Strings.Pomodoro.sessionEndAppears(.german) == "Abfrage erscheint")
        #expect(Strings.Pomodoro.sessionEndAppears(.english) == "Prompt appears")
        #expect(Strings.Pomodoro.sessionEndModeWindow(.german) == "Automatisch im Fenster")
        #expect(Strings.Pomodoro.sessionEndModeWindow(.english) == "Automatically in a window")
        #expect(Strings.Pomodoro.sessionEndModeMenuBar(.german) == "In der Menüleiste")
        #expect(Strings.Pomodoro.sessionEndModeMenuBar(.english) == "In the menu bar")
        #expect(Strings.Pomodoro.sessionEndModeWindowCaption(.german)
            == "Wenn die Sitzung endet, öffnet sich die Abfrage von selbst in einem eigenen Fenster.")
        #expect(Strings.Pomodoro.sessionEndModeWindowCaption(.english)
            == "When the session ends, the prompt opens by itself in its own window.")
        #expect(Strings.Pomodoro.sessionEndModeMenuBarCaption(.german)
            == "Kein Fenster öffnet sich — die Abfrage erscheint erst, wenn du das Menüleisten-Symbol anklickst.")
        #expect(Strings.Pomodoro.sessionEndModeMenuBarCaption(.english)
            == "No window opens — the prompt appears once you click the menu bar icon.")

        // Combined FocusMate buffer value
        #expect(Strings.Pomodoro.focusMateBufferValue(.german, minutes: 0, seconds: 40) == "0 Min. 40 Sek.")
        #expect(Strings.Pomodoro.focusMateBufferValue(.english, minutes: 2, seconds: 10) == "2 min 10 sec")
    }

    @Test("AI error strings for new error cases")
    func aiErrorStrings() {
        #expect(Strings.Errors.networkError(.german, message: "timeout").contains("Netzwerk"))
        #expect(Strings.Errors.networkError(.english, message: "timeout").contains("Network"))
        #expect(Strings.Errors.authenticationFailed(.german).contains("API"))
        #expect(Strings.Errors.authenticationFailed(.english).contains("API"))
        #expect(Strings.Errors.invalidResponse(.german, detail: "test detail").contains("Antwort"))
        #expect(Strings.Errors.invalidResponse(.german, detail: "test detail").contains("test detail"))
        #expect(Strings.Errors.invalidResponse(.english, detail: "test detail").contains("response"))
        #expect(Strings.Errors.invalidResponse(.english, detail: "test detail").contains("test detail"))
    }

    @Test("Keyboard shortcut hint strings")
    func keyboardShortcutHints() {
        #expect(Strings.General.saveHint(.german) == "Sichern (⌘↩)")
        #expect(Strings.General.saveHint(.english) == "Save (⌘↩)")
        #expect(Strings.Projects.newProjectHint(.german) == "Neues Projekt (⌘N)")
        #expect(Strings.Projects.newProjectHint(.english) == "New Project (⌘N)")
        #expect(Strings.Status.updateStatusHint(.german) == "Status aktualisieren (⌘U)")
        #expect(Strings.Status.updateStatusHint(.english) == "Update Status (⌘U)")
        #expect(Strings.Pomodoro.saveAndBreakHint(.german) == "Speichern & Pause (⌘↩)")
        #expect(Strings.Pomodoro.saveAndBreakHint(.english) == "Save & Break (⌘↩)")
        #expect(Strings.Pomodoro.saveAndDoneHint(.german) == "Speichern & Fertig (⌘↩)")
        #expect(Strings.Pomodoro.saveAndDoneHint(.english) == "Save & Done (⌘↩)")
        #expect(Strings.Pomodoro.saveAndStop(.german) == "Speichern & Stopp")
        #expect(Strings.Pomodoro.saveAndStop(.english) == "Save & Stop")
        #expect(Strings.Pomodoro.saveAndStopHint(.german) == "Speichern & Stopp (⌘↩)")
        #expect(Strings.Pomodoro.saveAndStopHint(.english) == "Save & Stop (⌘↩)")
    }

    @Test("Edit status strings return correct translations")
    func editStatusStrings() {
        #expect(Strings.Status.editStatus(.german) == "Status bearbeiten")
        #expect(Strings.Status.editStatus(.english) == "Edit Status")
    }

    @Test("Dictation strings return correct translations")
    func dictationStrings() {
        #expect(Strings.Dictation.buttonLabel(.german) == "Diktat")
        #expect(Strings.Dictation.buttonLabel(.english) == "Dictation")
        #expect(Strings.Dictation.permissionRequired(.german) == "Mikrofonzugriff erforderlich")
        #expect(Strings.Dictation.permissionRequired(.english) == "Microphone access required")
    }
}
