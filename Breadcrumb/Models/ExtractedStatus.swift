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
