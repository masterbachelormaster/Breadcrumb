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
        static func addBullet(_ l: AppLanguage) -> String {
            l == .german ? "Aufzählungspunkt hinzufügen" : "Add bullet"
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
            l == .german ? "Gesamtsitzungen: \(count)" : "Total Sessions: \(count)"
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
        static func saveAndDone(_ l: AppLanguage) -> String {
            l == .german ? "Speichern & Fertig" : "Save & Done"
        }
        static func snooze5(_ l: AppLanguage) -> String {
            l == .german ? "+5 Min." : "+5 min"
        }
        static func snooze10(_ l: AppLanguage) -> String {
            l == .german ? "+10 Min." : "+10 min"
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
        static func overtimeNotificationBody(_ l: AppLanguage) -> String {
            l == .german ? "Timer abgelaufen — Überstunden gestartet" : "Timer complete — overtime started"
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
        static func soundWorkDone(_ l: AppLanguage) -> String {
            l == .german ? "Ton bei Arbeitsende" : "Work done sound"
        }
        static func soundBreakDone(_ l: AppLanguage) -> String {
            l == .german ? "Ton bei Pausenende" : "Break done sound"
        }
        static func soundOvertime(_ l: AppLanguage) -> String {
            l == .german ? "Ton bei Überstunden" : "Overtime sound"
        }
        static func showBannerNotification(_ l: AppLanguage) -> String {
            l == .german ? "Bannerbenachrichtigung anzeigen" : "Show banner notification"
        }
        static func autoOpenPopover(_ l: AppLanguage) -> String {
            l == .german ? "Popover automatisch öffnen" : "Auto-open popover"
        }
        static func previewSound(_ l: AppLanguage) -> String {
            l == .german ? "Vorschau" : "Preview"
        }
        static func noSound(_ l: AppLanguage) -> String {
            l == .german ? "Kein Ton" : "None"
        }
        static func aiProvider(_ l: AppLanguage) -> String {
            l == .german ? "KI-Anbieter" : "AI Provider"
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
        static func modelHelp(_ l: AppLanguage) -> String {
            l == .german ? "Beliebige OpenRouter Modell-ID eingeben" : "Enter any OpenRouter model ID"
        }
        static func aiReady(_ l: AppLanguage) -> String {
            l == .german ? "Bereit" : "Ready"
        }
        static func aiNotConfigured(_ l: AppLanguage) -> String {
            l == .german ? "Nicht konfiguriert" : "Not configured"
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
                    Du bist ein Experte fuer Projekt-Status-Analyse. Extrahiere aus der Statusmeldung was erledigt ist, was als naechstes geplant ist und was unklar ist.

                    Liste jeden genannten Punkt auf. Trenne mehrere Punkte mit Zeilenumbruch (ein Punkt pro Zeile). Verwende kurze Stichpunkte ohne Pronomen. Bleib nah an den Originalworten.

                    Wenn nichts erledigt ist, lass lastAction leer. Wenn nichts unklar ist, lass openQuestions leer.
                    """
            case .english:
                return """
                    You are an expert project status parser. Extract what is done, what is planned next, and what is uncertain from the person's status update.

                    List every item mentioned. Separate multiple items with newlines (one item per line). Use short phrases without pronouns. Stay close to the original words.

                    If nothing is done, leave lastAction empty. If nothing is uncertain, leave openQuestions empty.
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
