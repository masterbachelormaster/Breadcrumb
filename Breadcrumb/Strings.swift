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
    }
}
