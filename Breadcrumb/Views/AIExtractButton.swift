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
    @State private var extractionTask: Task<Void, Never>?
    @State private var errorDismissTask: Task<Void, Never>?

    var body: some View {
        #if canImport(FoundationModels)
        if #available(macOS 26, *) {
            extractionContent
                .onDisappear {
                    extractionTask?.cancel()
                    errorDismissTask?.cancel()
                }
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
                    extractionTask = Task { await extract() }
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
                        .font(.caption)
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
        } catch is CancellationError {
            // Normal lifecycle event (view disappeared, task cancelled) — ignore.
        } catch {
            errorMessage = error.localizedDescription
            errorDismissTask = Task {
                try? await Task.sleep(for: .seconds(4))
                errorMessage = nil
            }
        }
    }

    private func applyResult(lastAction: String, nextStep: String, openQuestions: String) {
        if !lastAction.isEmpty {
            self.lastAction = cleanFiller(lastAction)
        }
        if !nextStep.isEmpty {
            self.nextStep = cleanFiller(nextStep)
        }
        if !openQuestions.isEmpty {
            self.openQuestions = cleanFiller(openQuestions)
        }
    }

    /// The on-device model sometimes generates filler text like "Leer" or "Nichts unklar"
    /// instead of an actual empty string. Strip these to prevent garbage in the UI.
    private func cleanFiller(_ text: String) -> String {
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

            // === OPEN QUESTIONS / UNCERTAINTIES ===
            // German
            "nichts unklar", "nichts offen", "alles klar", "alles soweit klar",
            "soweit alles klar", "alles verstanden", "passt", "passt soweit",
            "keine fragen", "keine offenen fragen", "keine fragen offen",
            "keine offenen fragen vorhanden", "keine fragen vorhanden",
            "keine unsicherheiten", "keine unsicherheit",
            "keine offenen unsicherheiten", "keine unsicherheiten vorhanden",
            "keine aktuellen fragen", "keine aktuellen unsicherheiten",
            "keine offenen punkte", "keine offenen themen",
            "keine weiteren fragen", "keine anmerkungen", "keine probleme",
            "keine bedenken", "keine zweifel", "keine unklarheiten",
            "keine unklarheit", "keine offene frage",
            "keine unklaren punkte",
            "es gibt keine offenen fragen", "es gibt keine unsicherheiten",
            "es gibt nichts unklares", "es gibt keine unklarheiten",
            "keine offenen fragen oder unsicherheiten",
            "momentan keine fragen", "aktuell keine fragen",
            "aktuell keine unsicherheiten", "derzeit keine fragen",
            "derzeit keine unsicherheiten", "zur zeit keine fragen",
            "bisher keine fragen", "im moment keine fragen",
            "soweit keine fragen", "keine fragen im moment",
            "keine fragen aktuell", "keine fragen derzeit",
            "momentan keine unsicherheiten", "bisher keine unsicherheiten",
            "im moment keine unsicherheiten",
            "es sind keine fragen offen", "es bestehen keine unsicherheiten",
            "es bestehen keine fragen", "es bestehen keine offenen fragen",
            "hierzu keine fragen", "dazu keine fragen",
            "keine offenen fragen identifiziert",
            "keine offenen fragen festgestellt",
            "alles wurde geklaert", "alles geklaert", "alles geklärt",
            // English
            "nothing unclear", "nothing open", "all clear", "all understood",
            "everything is clear", "everything clear",
            "no questions", "no open questions", "no questions open",
            "no open questions at this time", "no open questions right now",
            "no uncertainties", "no uncertainty",
            "no open issues", "no open items", "no open topics",
            "no further questions", "no comments", "no problems", "no concerns",
            "no doubts", "no unclear points", "no ambiguity",
            "no open questions or uncertainties",
            "no questions identified", "no open questions identified",
            "no open questions identified at this time",
            "there are no open questions", "there are no uncertainties",
            "nothing is unclear", "nothing remains unclear",
            "currently no questions", "currently no uncertainties",
            "no questions at the moment", "no questions currently",
            "no questions right now", "no questions at this time",
            "no uncertainties at the moment", "no uncertainties right now",
            "everything has been clarified", "all clarified",
            "no issues identified", "no concerns identified",

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
            "momentan nichts erledigt",
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
            // Questions/uncertainties
            "keine offenen fragen", "keine weiteren fragen", "keine aktuellen fragen",
            "keine offenen unsicherheit", "keine weiteren unsicherheit",
            "keine unklaren",
            "es gibt keine offenen", "es gibt keine weiteren",
            "es bestehen keine", "hierzu keine",
            "no open question", "no further question", "no uncertaint",
            "there are no open", "there are no further",
            // Last action / completed
            "nichts erledigt", "nichts abgeschlossen", "noch nichts",
            "bisher nichts", "bislang nichts",
            "keine erledigten", "keine abgeschlossenen", "keine bisherigen",
            "keine vorherigen", "keine letzten",
            "es wurde nichts", "es gibt nichts erledigt",
            "nothing done", "nothing completed", "nothing finished",
            "no completed", "no previous", "no progress",
            "nothing has been", "nothing was",
            // Next steps / planned
            "nichts geplant", "nichts weiter",
            "keine naechsten", "keine nächsten", "keine weiteren schritte",
            "keine geplanten", "keine weiteren aufgaben",
            "es gibt keine naechsten", "es gibt keine nächsten",
            "es gibt keine weiteren", "es gibt keine geplanten",
            "es ist nichts", "es sind keine",
            "nothing planned", "nothing further",
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
    #endif
}
