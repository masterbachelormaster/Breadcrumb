import Foundation

/// Strips AI-generated filler phrases like "leer", "nichts unklar",
/// "nothing planned" from extracted status fields. The local FoundationModels
/// model and remote LLMs both occasionally produce these instead of an
/// empty string when a field has no real content.
enum AIFillerStripper {

    /// Strips filler from a single line / value. Returns "" if the entire
    /// input is filler, otherwise returns the trimmed real content.
    static func clean(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: ".-–—"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let lowered = trimmed.lowercased()

        // Exact matches
        let fillerPhrases: Set<String> = [
            // === GENERAL (applies to any field) ===
            "leer", "leere", "leerer string", "leeres feld", "leerfeld",
            "nichts", "nein", "klar", "n/a", "na",
            "entfaellt", "entfällt",
            "keine", "keins", "keines",
            "nicht vorhanden", "nicht bekannt", "nicht zutreffend",
            "nicht angegeben", "nicht verfuegbar", "nicht verfügbar",
            "nicht relevant", "nicht noetig", "nicht nötig",
            "keine angaben", "keine angabe",
            "null", "leer lassen", "feld leer",
            "hier nichts", "hier leer", "hier keine angabe",
            "empty", "empty string", "empty field",
            "none", "nothing", "no", "clear",
            "not applicable", "not available", "not specified", "not relevant",
            "ok", "okay", "alles gut", "all good",
            "...", "…", "-", "--", "---", "–", "—",
            "[]", "()", "\"\"", "''",

            // === LAST ACTION / COMPLETED TASKS ===
            // German
            "nichts erledigt", "nichts abgeschlossen", "nichts gemacht",
            "nichts getan", "nichts passiert", "nichts fertig",
            "noch nichts", "noch nichts erledigt", "noch nichts gemacht",
            "noch nichts abgeschlossen", "noch nichts passiert",
            "noch nichts getan", "noch nichts fertig",
            "bisher nichts erledigt", "bisher nichts gemacht",
            "bisher nichts abgeschlossen", "bisher nichts passiert",
            "keine erledigten aufgaben", "keine abgeschlossenen aufgaben",
            "keine vorherigen aktionen", "keine vorherige aktion",
            "keine bisherigen aktionen", "keine bisherige aktion",
            "keine letzten aktionen", "keine letzte aktion",
            "kein letzter schritt", "keine letzten schritte",
            "keine erledigten schritte", "keine erledigten punkte",
            "keine aktion", "keine aktionen",
            "keine fortschritte", "kein fortschritt",
            "noch nicht begonnen", "nicht begonnen", "nicht gestartet",
            "noch nicht angefangen", "nicht angefangen",
            "es wurde nichts erledigt", "es wurde nichts gemacht",
            "es wurde nichts abgeschlossen",
            "bisher wurde nichts erledigt", "bisher wurde nichts gemacht",
            "hierzu nichts erledigt", "hierzu nichts abgeschlossen",
            "bislang nichts erledigt", "bislang nichts passiert",
            "keine aufgaben erledigt", "keine aufgaben abgeschlossen",
            "keine schritte abgeschlossen", "keine schritte erledigt",
            "keine arbeit erledigt", "keine arbeit gemacht",
            "es gibt nichts erledigtes", "es gibt keine erledigten aufgaben",
            "aktuell nichts erledigt", "derzeit nichts erledigt",
            "momentan nichts erledigt", "nichts erledigt bisher",
            // English
            "nothing done", "nothing completed", "nothing finished",
            "nothing accomplished", "nothing happened",
            "not started", "not yet started", "not begun", "not yet begun",
            "no completed tasks", "no tasks completed",
            "no previous actions", "no previous action",
            "no last action", "no last actions",
            "no completed steps", "no steps completed",
            "no progress", "no progress made", "no progress yet",
            "no action taken", "no actions taken",
            "no actions", "no action",
            "nothing happened yet", "nothing has happened",
            "nothing has been done", "nothing was completed",
            "nothing was done", "nothing has been completed",
            "no work done", "no work completed",
            "nothing has been accomplished",
            "haven't started", "hasn't started",
            "not yet completed", "nothing yet",
            "currently nothing done", "currently nothing completed",
            "no tasks done", "no items completed",

            // === NEXT STEPS / PLANNED TASKS ===
            // German
            "nichts geplant", "nichts weiter", "nichts weiteres",
            "nichts vorgesehen", "nichts anstehend",
            "keine naechsten schritte", "keine nächsten schritte",
            "kein naechster schritt", "kein nächster schritt",
            "keine weiteren schritte", "keine weiteren aufgaben",
            "keine geplanten schritte", "keine geplanten aufgaben",
            "keine planung", "keine geplanten aktionen",
            "keine aufgaben", "keine schritte",
            "keine weiteren aktionen", "keine weiteren punkte",
            "keine naechste aktion", "keine nächste aktion",
            "keine todos", "keine to-dos",
            "keine offenen aufgaben",
            "momentan nichts geplant", "aktuell nichts geplant",
            "derzeit nichts geplant", "bisher nichts geplant",
            "zur zeit nichts geplant", "im moment nichts geplant",
            "es gibt keine naechsten schritte",
            "es gibt keine nächsten schritte",
            "es gibt keine weiteren schritte",
            "es gibt keine geplanten aufgaben",
            "es sind keine schritte geplant",
            "es ist nichts geplant", "es ist nichts weiter geplant",
            "wird noch festgelegt", "noch festzulegen",
            "noch zu bestimmen", "noch offen", "steht noch aus",
            "noch unklar", "muss noch geklaert werden",
            "muss noch geklärt werden", "muss noch entschieden werden",
            "keine naechsten aufgaben", "keine nächsten aufgaben",
            "hierzu nichts geplant", "dazu nichts geplant",
            "soweit nichts geplant", "bislang nichts geplant",
            // English
            "nothing planned", "nothing further", "nothing next",
            "nothing scheduled", "nothing upcoming",
            "no next steps", "no next step",
            "no further steps", "no further actions", "no further tasks",
            "no planned tasks", "no planned steps", "no planned actions",
            "no tasks", "no steps", "no actions planned",
            "no upcoming tasks", "no upcoming steps",
            "no todos", "no to-dos",
            "nothing to do", "nothing to do next",
            "no action needed", "no actions needed",
            "no action required", "no actions required",
            "currently nothing planned", "nothing currently planned",
            "no tasks planned", "no steps planned",
            "there are no next steps", "there are no further steps",
            "there are no planned tasks",
            "no next steps identified", "no further steps identified",
            "to be determined", "tbd", "to be decided",
            "still open", "still pending", "pending",
            "not yet determined", "not yet decided",
            "no next steps at this time",
            "no further actions needed", "no further actions required",
        ]

        if fillerPhrases.contains(lowered) {
            return ""
        }

        // Prefix patterns: catch variations we didn't list exactly
        let fillerPrefixes = [
            // Last action / completed
            "keine erledigten", "keine abgeschlossenen", "keine bisherigen",
            "keine vorherigen", "keine letzten",
            "es wurde nichts", "es gibt nichts erledigt",
            "no completed", "no previous",
            // Next steps / planned
            "keine naechsten", "keine nächsten", "keine weiteren schritte",
            "keine geplanten", "keine weiteren aufgaben",
            "es gibt keine naechsten", "es gibt keine nächsten",
            "es gibt keine weiteren", "es gibt keine geplanten",
            "es ist nichts", "es sind keine",
            "no next step", "no further step", "no planned",
            "no upcoming", "there are no next", "there are no planned",
        ]
        for prefix in fillerPrefixes {
            if lowered.hasPrefix(prefix) {
                return ""
            }
        }

        return trimmed
    }

    /// Multi-line variant: splits on newlines, runs `clean` on each line,
    /// drops empty results, and rejoins survivors with `\n`. Used for the
    /// new bullet-list AI extraction output where each line is one bullet.
    static func cleanLines(_ text: String) -> String {
        text
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { clean(String($0)) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }
}
