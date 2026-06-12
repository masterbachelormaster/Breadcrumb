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
        static func today(_ l: AppLanguage) -> String {
            l == .german ? "Heute" : "Today"
        }
        static func moreOptions(_ l: AppLanguage) -> String {
            l == .german ? "Weitere Optionen" : "More Options"
        }
        static func hoursAbbrev(_ l: AppLanguage) -> String {
            l == .german ? "Std." : "hrs"
        }
        static func minutesAbbrev(_ l: AppLanguage) -> String {
            l == .german ? "Min." : "min"
        }
        static func saveHint(_ l: AppLanguage) -> String {
            l == .german ? "Sichern (⌘↩)" : "Save (⌘↩)"
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
        static func newProjectHint(_ l: AppLanguage) -> String {
            l == .german ? "Neues Projekt (⌘N)" : "New Project (⌘N)"
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
        static func noEntries(_ l: AppLanguage) -> String {
            l == .german ? "Keine Einträge" : "No Entries"
        }
        static func noEntriesDescription(_ l: AppLanguage) -> String {
            l == .german ? "Noch keine Status-Einträge vorhanden" : "No status entries yet"
        }
        static func history(_ l: AppLanguage) -> String {
            l == .german ? "Historie" : "History"
        }
        static func updateStatusHint(_ l: AppLanguage) -> String {
            l == .german ? "Status aktualisieren (⌘U)" : "Update Status (⌘U)"
        }
        static func editStatus(_ l: AppLanguage) -> String {
            l == .german ? "Status bearbeiten" : "Edit Status"
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
        static func stopWithoutSaving(_ l: AppLanguage) -> String {
            l == .german ? "Aufhören ohne Speichern" : "Stop Without Saving"
        }
        static func saveAndBreak(_ l: AppLanguage) -> String {
            l == .german ? "Speichern & Pause" : "Save & Break"
        }
        static func saveAndBreakHint(_ l: AppLanguage) -> String {
            l == .german ? "Speichern & Pause (⌘↩)" : "Save & Break (⌘↩)"
        }
        static func saveAndStop(_ l: AppLanguage) -> String {
            l == .german ? "Speichern & Stopp" : "Save & Stop"
        }
        static func saveAndStopHint(_ l: AppLanguage) -> String {
            l == .german ? "Speichern & Stopp (⌘↩)" : "Save & Stop (⌘↩)"
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
            l == .german ? "Lange Pause nach: \(count) Sitzungen" : "Long break after: \(count) sessions"
        }
        static func overtimeSession(_ l: AppLanguage, number: Int) -> String {
            l == .german ? "Überstunden · Sitzung \(number)" : "Overtime · Session \(number)"
        }
        static func focusTimeSession(_ l: AppLanguage, number: Int, total: Int) -> String {
            l == .german ? "Fokuszeit · Sitzung \(number) von \(total)" : "Focus Time · Session \(number) of \(total)"
        }
        static func done(_ l: AppLanguage) -> String {
            l == .german ? "Fertig!" : "Done!"
        }
        static func configureSession(_ l: AppLanguage) -> String {
            l == .german ? "Sitzung konfigurieren" : "Configure Session"
        }
        static func startSession(_ l: AppLanguage) -> String {
            l == .german ? "Sitzung starten" : "Start Session"
        }
        static func totalSessionsLabel(_ l: AppLanguage, count: Int) -> String {
            l == .german ? "Fokus-Sitzungen: \(count)" : "Focus sessions: \(count)"
        }
        static func allSessionsComplete(_ l: AppLanguage) -> String {
            l == .german ? "Alle Sitzungen abgeschlossen!" : "All Sessions Complete!"
        }
        static func pomodoroMode(_ l: AppLanguage) -> String {
            "Pomodoro"
        }
        static func focusMateMode(_ l: AppLanguage) -> String {
            "FocusMate"
        }
        static func focusMateLength(_ l: AppLanguage) -> String {
            l == .german ? "Sitzungslänge" : "Session Length"
        }
        static func focusMateMinutesOption(_ l: AppLanguage, minutes: Int) -> String {
            l == .german ? "\(minutes) Min." : "\(minutes) min"
        }
        static func focusMateSessionStart(_ l: AppLanguage) -> String {
            l == .german ? "Sitzungsbeginn" : "Session Start"
        }
        static func focusMateEndsAt(_ l: AppLanguage, time: String) -> String {
            l == .german ? "Endet um \(time)" : "Ends at \(time)"
        }
        static func focusMatePhaseLabel(_ l: AppLanguage, time: String) -> String {
            l == .german ? "FocusMate · endet um \(time)" : "FocusMate · ends at \(time)"
        }
        static func focusMateComplete(_ l: AppLanguage) -> String {
            l == .german ? "👥 FocusMate-Sitzung beendet!" : "👥 FocusMate Session Complete!"
        }
        static func focusMateEndEarlyHeader(_ l: AppLanguage) -> String {
            l == .german ? "Timer früher beenden" : "End the timer early"
        }
        static func focusMateBufferCaption(_ l: AppLanguage) -> String {
            l == .german
                ? "So bleibt dir Zeit, deinen Stand festzuhalten, bevor die Sitzung vorbei ist."
                : "Leaves you time to note down where you stand before the session is over."
        }
        static func focusMateSectionFooter(_ l: AppLanguage) -> String {
            l == .german
                ? "FocusMate-Sitzungen laufen bis zu einer festen Endzeit, z. B. für Video-Co-Working auf focusmate.com."
                : "FocusMate sessions run to a fixed end time, e.g. for video co-working on focusmate.com."
        }
        static func cycleSummary(_ l: AppLanguage, sessions: Int, workMinutes: Int, totalMinutes: Int) -> String {
            if sessions == 1 {
                return l == .german
                    ? "Dein Durchgang: 1 Fokus-Sitzung à \(workMinutes) Min."
                    : "Your cycle: one \(workMinutes) min focus session."
            }
            let duration = formatDuration(l, totalMinutes: totalMinutes)
            return l == .german
                ? "Dein Durchgang: \(sessions) × \(workMinutes) Min. Fokus mit Pausen — insgesamt ca. \(duration)."
                : "Your cycle: \(sessions) × \(workMinutes) min focus with breaks — about \(duration) total."
        }
        private static func formatDuration(_ l: AppLanguage, totalMinutes: Int) -> String {
            let hours = totalMinutes / 60
            let minutes = totalMinutes % 60
            let hoursUnit = l == .german ? "Std." : "h"
            let minutesUnit = l == .german ? "Min." : "min"
            var parts: [String] = []
            if hours > 0 {
                parts.append("\(hours) \(hoursUnit)")
            }
            if minutes > 0 || hours == 0 {
                parts.append("\(minutes) \(minutesUnit)")
            }
            return parts.joined(separator: " ")
        }
        static func sessionEndAppears(_ l: AppLanguage) -> String {
            l == .german ? "Abfrage erscheint" : "Prompt appears"
        }
        static func sessionEndModeWindow(_ l: AppLanguage) -> String {
            l == .german ? "Automatisch im Fenster" : "Automatically in a window"
        }
        static func sessionEndModeMenuBar(_ l: AppLanguage) -> String {
            l == .german ? "In der Menüleiste" : "In the menu bar"
        }
        static func sessionEndModeWindowCaption(_ l: AppLanguage) -> String {
            l == .german
                ? "Wenn die Sitzung endet, öffnet sich die Abfrage von selbst in einem eigenen Fenster."
                : "When the session ends, the prompt opens by itself in its own window."
        }
        static func sessionEndModeMenuBarCaption(_ l: AppLanguage) -> String {
            l == .german
                ? "Kein Fenster öffnet sich — die Abfrage erscheint erst, wenn du das Menüleisten-Symbol anklickst."
                : "No window opens — the prompt appears once you click the menu bar icon."
        }
        static func focusMateBufferValue(_ l: AppLanguage, minutes: Int, seconds: Int) -> String {
            l == .german ? "\(minutes) Min. \(seconds) Sek." : "\(minutes) min \(seconds) sec"
        }
        static func sessionEndedOpenPromptTitle(_ l: AppLanguage) -> String {
            l == .german ? "Sitzung beendet" : "Session ended"
        }
        static func sessionEndedOpenPromptMessage(_ l: AppLanguage) -> String {
            l == .german ? "Speichere oder wähle, was als Nächstes passiert." : "Save or choose what happens next."
        }
        static func openSessionEndPrompt(_ l: AppLanguage) -> String {
            l == .german ? "Dialog öffnen" : "Open Prompt"
        }
        static func wrapUpBuffer(_ l: AppLanguage, seconds: Int) -> String {
            let m = seconds / 60
            let s = seconds % 60
            let t = "\(m):\(s.formatted(.number.precision(.integerLength(2))))"
            return l == .german ? "Endet \(t) früher" : "Ends \(t) early"
        }
        static func saveAndDone(_ l: AppLanguage) -> String {
            l == .german ? "Speichern & Fertig" : "Save & Done"
        }
        static func saveAndDoneHint(_ l: AppLanguage) -> String {
            l == .german ? "Speichern & Fertig (⌘↩)" : "Save & Done (⌘↩)"
        }
        static func snooze5(_ l: AppLanguage) -> String {
            l == .german ? "+5 Min." : "+5 min"
        }
        static func snooze10(_ l: AppLanguage) -> String {
            l == .german ? "+10 Min." : "+10 min"
        }
        static func collapseToBanner(_ l: AppLanguage) -> String {
            l == .german ? "Timer einklappen" : "Collapse timer"
        }
        static func showTimer(_ l: AppLanguage) -> String {
            l == .german ? "Timer anzeigen" : "Show timer"
        }
    }

    // MARK: - Notifications

    enum Notifications {
        static func pomodoroFinishedTitle(_ l: AppLanguage) -> String {
            l == .german ? "Pomodoro beendet!" : "Pomodoro Finished!"
        }
        static func pomodoroFinishedBody(_ l: AppLanguage) -> String {
            l == .german ? "Zeit für eine Pause" : "Time for a break"
        }
        static func sessionCompleteBody(_ l: AppLanguage) -> String {
            l == .german ? "Sitzung abgeschlossen" : "Session complete"
        }
        static func allSessionsCompleteBody(_ l: AppLanguage) -> String {
            l == .german ? "Alle Sitzungen abgeschlossen" : "All sessions complete"
        }
        static func focusMateFinishedTitle(_ l: AppLanguage) -> String {
            l == .german ? "FocusMate beendet!" : "FocusMate Finished!"
        }
        static func breakOverTitle(_ l: AppLanguage) -> String {
            l == .german ? "Pause vorbei!" : "Break Over!"
        }
        static func breakOverBody(_ l: AppLanguage) -> String {
            l == .german ? "Bereit für die nächste Sitzung?" : "Ready for the next session?"
        }
        static func actionStartBreak(_ l: AppLanguage) -> String {
            l == .german ? "Pause starten" : "Start Break"
        }
        static func actionNextSession(_ l: AppLanguage) -> String {
            l == .german ? "Nächste Sitzung" : "Next Session"
        }
        static func actionContinueWorking(_ l: AppLanguage) -> String {
            l == .german ? "Weiterarbeiten" : "Continue working"
        }
        static func actionStop(_ l: AppLanguage) -> String {
            l == .german ? "Stopp" : "Stop"
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
        static func dictation(_ l: AppLanguage) -> String {
            l == .german ? "Diktat (Experimentell)" : "Dictation (Experimental)"
        }
        static func dictationCaption(_ l: AppLanguage) -> String {
            l == .german
                ? "Zeigt eine Mikrofon-Taste in Status-Formularen, um Text zu diktieren statt zu tippen."
                : "Adds a microphone button to status forms so you can dictate instead of type."
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
        static func soundWorkDone(_ l: AppLanguage) -> String {
            l == .german ? "Ton bei Sitzungsende" : "Sound when focus ends"
        }
        static func soundBreakDone(_ l: AppLanguage) -> String {
            l == .german ? "Ton bei Pausenende" : "Sound when break ends"
        }
        static func showBannerNotification(_ l: AppLanguage) -> String {
            l == .german ? "Bannerbenachrichtigung anzeigen" : "Show banner notification"
        }
        static func showBannerCaption(_ l: AppLanguage) -> String {
            l == .german
                ? "Zeigt eine macOS-Mitteilung, wenn eine Sitzung oder Pause endet – auch wenn du gerade in einer anderen App bist."
                : "Shows a macOS notification when a session or break ends — even while you're in another app."
        }
        static func sessionEndSection(_ l: AppLanguage) -> String {
            l == .german ? "Sitzungsende" : "Session End"
        }
        static func aiSection(_ l: AppLanguage) -> String {
            l == .german ? "KI" : "AI"
        }
        static func aiIntro(_ l: AppLanguage) -> String {
            l == .german
                ? "Die KI liest deinen Statustext und füllt „Letzter Schritt“ und „Nächster Schritt“ automatisch aus."
                : "AI reads your status text and fills in “Last Step” and “Next Step” for you."
        }
        static func aiProviderLocalCaption(_ l: AppLanguage) -> String {
            l == .german
                ? "Läuft komplett auf diesem Mac mit Apple Intelligence. Dein Text verlässt dein Gerät nicht."
                : "Runs entirely on this Mac using Apple Intelligence. Your text never leaves your device."
        }
        static func aiProviderOpenRouterCaption(_ l: AppLanguage) -> String {
            l == .german
                ? "Sendet deinen Text an ein Cloud-KI-Modell deiner Wahl. Benötigt einen OpenRouter-Account und API-Schlüssel (openrouter.ai)."
                : "Sends your text to a cloud AI model of your choice. Requires an OpenRouter account and API key (openrouter.ai)."
        }
        static func previewSound(_ l: AppLanguage) -> String {
            l == .german ? "Vorschau" : "Preview"
        }
        static func noSound(_ l: AppLanguage) -> String {
            l == .german ? "Kein Ton" : "None"
        }
        static func aiProvider(_ l: AppLanguage) -> String {
            l == .german ? "Anbieter" : "Provider"
        }
        static func aiProviderLocal(_ l: AppLanguage) -> String {
            l == .german ? "Apple KI" : "Apple AI"
        }
        static func aiProviderOpenRouter(_ l: AppLanguage) -> String {
            "OpenRouter"
        }
        static func apiKey(_ l: AppLanguage) -> String {
            l == .german ? "API-Schlüssel" : "API Key"
        }
        static func model(_ l: AppLanguage) -> String {
            l == .german ? "Modell" : "Model"
        }
        static func apiKeyPlaceholder(_ l: AppLanguage) -> String {
            l == .german ? "OpenRouter API-Schlüssel eingeben" : "Enter OpenRouter API key"
        }
        static func modelPlaceholder(_ l: AppLanguage) -> String {
            l == .german ? "z. B. anthropic/claude-sonnet-4" : "e.g. anthropic/claude-sonnet-4"
        }
        static func apiKeyHelp(_ l: AppLanguage) -> String {
            l == .german ? "API-Schlüssel von openrouter.ai" : "Get your API key at openrouter.ai"
        }
        static func apiKeySaveFailed(_ l: AppLanguage) -> String {
            l == .german ? "API-Schlüssel konnte nicht gespeichert werden." : "Could not save API key."
        }
        static func modelHelp(_ l: AppLanguage) -> String {
            l == .german ? "Modell-ID von openrouter.ai/models eingeben" : "Enter a model ID from openrouter.ai/models"
        }
        static func aiReady(_ l: AppLanguage) -> String {
            l == .german ? "Bereit" : "Ready"
        }
        static func aiNotConfigured(_ l: AppLanguage) -> String {
            l == .german ? "Nicht konfiguriert" : "Not configured"
        }
        static func systemPrompt(_ l: AppLanguage) -> String {
            l == .german ? "KI-Anweisungen (Erweitert)" : "AI Instructions (Advanced)"
        }
        static func systemPromptHelp(_ l: AppLanguage) -> String {
            l == .german
                ? "Diese Anweisungen steuern, wie die KI deinen Text auswertet. Nur ändern, wenn du weißt, was du tust."
                : "These instructions control how the AI interprets your text. Only change this if you know what you're doing."
        }
        static func resetToDefault(_ l: AppLanguage) -> String {
            l == .german ? "Auf Standard zurücksetzen" : "Reset to Default"
        }
        static func focusMateUser(_ l: AppLanguage) -> String {
            l == .german ? "FocusMate-Modus" : "FocusMate mode"
        }
        static func focusMateUserCaption(_ l: AppLanguage) -> String {
            l == .german
                ? "Zeigt im Pomodoro-Dialog eine FocusMate-Option: einen Timer für FocusMate-Video-Sitzungen. Aktiviere dies, wenn du FocusMate nutzt."
                : "Shows a FocusMate option in the Pomodoro dialog: a timer for FocusMate video sessions. Turn this on if you use FocusMate."
        }
        static func focusMateLink(_ l: AppLanguage) -> String {
            l == .german ? "focusmate.com besuchen" : "Visit focusmate.com"
        }
        static func timerTab(_ l: AppLanguage) -> String {
            "Timer"
        }
        static func notificationsTab(_ l: AppLanguage) -> String {
            l == .german ? "Mitteilungen" : "Notifications"
        }
        static func soundsGroup(_ l: AppLanguage) -> String {
            l == .german ? "Töne" : "Sounds"
        }
        static func bannerGroup(_ l: AppLanguage) -> String {
            "Banner"
        }
        static func aiStatus(_ l: AppLanguage) -> String {
            "Status"
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

    // MARK: - FocusMate Question

    enum FocusMateQuestion {
        static func title(_ l: AppLanguage) -> String {
            l == .german ? "Nutzt du FocusMate?" : "Are you a FocusMate user?"
        }
        static func explanation(_ l: AppLanguage) -> String {
            l == .german
                ? "Breadcrumb hat einen FocusMate-Modus: einen Timer, der parallel zu deinen FocusMate-Video-Sitzungen läuft. Wenn du FocusMate nutzt, blenden wir diese Option ein. Du kannst das später in den Einstellungen ändern."
                : "Breadcrumb has a FocusMate mode: a timer that runs alongside your FocusMate video coworking sessions. If you use FocusMate, we'll show this option. You can change this later in Settings."
        }
        static func linkLabel(_ l: AppLanguage) -> String {
            l == .german ? "Mehr über FocusMate" : "Learn more about FocusMate"
        }
        static func yes(_ l: AppLanguage) -> String {
            l == .german ? "Ja" : "Yes"
        }
        static func no(_ l: AppLanguage) -> String {
            l == .german ? "Nein" : "No"
        }
    }

    // MARK: - About

    enum About {
        static func version(_ l: AppLanguage) -> String {
            "Version"
        }
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
                    Du bist ein Experte fuer Projekt-Status-Analyse. Extrahiere aus der Statusmeldung was erledigt ist und was als naechstes geplant ist.

                    Liste jeden genannten Punkt auf. Trenne mehrere Punkte mit Zeilenumbruch (ein Punkt pro Zeile). Verwende kurze Stichpunkte ohne Pronomen. Bleib nah an den Originalworten.

                    Wenn nichts erledigt ist, lass lastAction leer.
                    """
            case .english:
                return """
                    You are an expert project status parser. Extract what is done and what is planned next from the person's status update.

                    List every item mentioned. Separate multiple items with newlines (one item per line). Use short phrases without pronouns. Stay close to the original words.

                    If nothing is done, leave lastAction empty.
                    """
            }
        }
        static func lastActionInstructions(_ l: AppLanguage) -> String {
            let locale = l == .german ? "\nThe person's locale is de_DE." : ""
            return """
            You are a project status parser. Extract only finished work from the person's update.

            List every completed task. Separate items with ". ". \
            Use a few words per item, stay close to the original wording. \
            Words like "will", "should", "muss noch", "next", "als nächstes" signal future plans — skip those entirely. \
            If nothing is finished, produce an empty string.

            Extract only finished work.\(locale)
            """
        }
        static func nextStepInstructions(_ l: AppLanguage) -> String {
            let locale = l == .german ? "\nThe person's locale is de_DE." : ""
            return """
            You are a project status parser. Extract only planned or future tasks from the person's update.

            List every planned task. Separate items with ". ". \
            Use a few words per item, stay close to the original wording. \
            Words like "fertig", "erledigt", "done", "finished", "geschrieben" signal completed work — skip those entirely. \
            If nothing is planned, produce an empty string.

            Extract only planned tasks.\(locale)
            """
        }
    }

    // MARK: - Dictation

    enum Dictation {
        static func buttonLabel(_ l: AppLanguage) -> String {
            l == .german ? "Diktat" : "Dictation"
        }
        static func permissionRequired(_ l: AppLanguage) -> String {
            l == .german ? "Mikrofonzugriff erforderlich" : "Microphone access required"
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
        static func networkError(_ l: AppLanguage, message: String) -> String {
            l == .german ? "Netzwerkfehler: \(message)" : "Network error: \(message)"
        }
        static func authenticationFailed(_ l: AppLanguage) -> String {
            l == .german ? "Ungültiger API-Schlüssel" : "Invalid API key"
        }
        static func invalidResponse(_ l: AppLanguage, detail: String) -> String {
            l == .german ? "Ungültige Antwort vom Modell: \(detail)" : "Invalid response from model: \(detail)"
        }
    }

    // MARK: - Confirmation Dialogs

    enum Confirm {
        static func deleteProjectTitle(_ l: AppLanguage) -> String {
            l == .german ? "Projekt löschen?" : "Delete Project?"
        }
        static func deleteProjectMessage(_ l: AppLanguage, name: String) -> String {
            l == .german
                ? "\u{201E}\(name)\u{201C} und alle zugehörigen Einträge und Sitzungen werden unwiderruflich gelöscht."
                : "\u{201C}\(name)\u{201D} and all its entries and sessions will be permanently deleted."
        }
        static func deleteEntryTitle(_ l: AppLanguage) -> String {
            l == .german ? "Eintrag löschen?" : "Delete Entry?"
        }
        static func deleteEntryMessage(_ l: AppLanguage) -> String {
            l == .german
                ? "Dieser Status-Eintrag wird unwiderruflich gelöscht."
                : "This status entry will be permanently deleted."
        }
        static func deleteDocumentTitle(_ l: AppLanguage) -> String {
            l == .german ? "Dokument entfernen?" : "Remove Document?"
        }
        static func deleteDocumentMessage(_ l: AppLanguage) -> String {
            l == .german
                ? "Das verknüpfte Dokument wird entfernt."
                : "The linked document will be removed."
        }
    }

    // MARK: - Documents

    enum Documents {
        static func documents(_ l: AppLanguage) -> String {
            l == .german ? "Dokumente" : "Documents"
        }
        static func addFile(_ l: AppLanguage) -> String {
            l == .german ? "Datei hinzufügen…" : "Add File…"
        }
        static func addURL(_ l: AppLanguage) -> String {
            l == .german ? "Link hinzufügen…" : "Add URL…"
        }
        static func fileNotFound(_ l: AppLanguage) -> String {
            l == .german ? "Datei nicht gefunden" : "File not found"
        }
        static func editLabel(_ l: AppLanguage) -> String {
            l == .german ? "Bezeichnung bearbeiten" : "Edit Label"
        }
        static func urlPlaceholder(_ l: AppLanguage) -> String {
            l == .german ? "URL eingeben" : "Enter URL"
        }
        static func labelPlaceholder(_ l: AppLanguage) -> String {
            l == .german ? "Bezeichnung (optional)" : "Label (optional)"
        }
        static func invalidURL(_ l: AppLanguage) -> String {
            l == .german ? "Bitte eine gültige URL eingeben (z. B. example.com)" : "Please enter a valid URL (e.g. example.com)"
        }
    }
}
