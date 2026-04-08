#if canImport(FoundationModels)
import FoundationModels

@available(macOS 26, *)
@Generable
struct ExtractedStatusDE {
    @Guide(description: "Kurze Ueberlegung: Was wurde gesagt? Was ist erledigt, geplant, unklar?")
    var reasoning: String

    @Guide(description: "Was schon erledigt oder abgeschlossen ist. Mehrere Punkte mit Zeilenumbruch trennen (ein Punkt pro Zeile). Leer lassen wenn nichts fertig.")
    var lastAction: String

    @Guide(description: "Alle geplanten Schritte und Ideen. Mehrere Punkte mit Zeilenumbruch trennen (ein Punkt pro Zeile).")
    var nextStep: String

    @Guide(description: "Nur echte Unsicherheiten oder offene Fragen. Mehrere Punkte mit Zeilenumbruch trennen (ein Punkt pro Zeile). Leer lassen wenn nichts unklar.")
    var openQuestions: String
}

@available(macOS 26, *)
@Generable
struct ExtractedStatusEN {
    @Guide(description: "Brief reasoning: What was said? What is done, planned, unclear?")
    var reasoning: String

    @Guide(description: "What is already done or completed. Separate multiple items with newlines (one per line). Leave empty if nothing is finished.")
    var lastAction: String

    @Guide(description: "All planned steps and ideas. Separate multiple items with newlines (one per line).")
    var nextStep: String

    @Guide(description: "Only genuine uncertainties or open questions. Separate multiple items with newlines (one per line). Leave empty if nothing is unclear.")
    var openQuestions: String
}
#endif
