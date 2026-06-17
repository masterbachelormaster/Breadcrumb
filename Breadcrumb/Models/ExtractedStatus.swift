#if canImport(FoundationModels)
import FoundationModels

@available(macOS 26, *)
@Generable(description: "Completed work extracted from a project status update")
struct LastActionExtraction {
    @Guide(description: "What is already done, one item per line. Empty if nothing is finished.")
    var completedWork: String
}

@available(macOS 26, *)
@Generable(description: "Planned next steps extracted from a project status update")
struct NextStepExtraction {
    @Guide(description: "What is planned next, one item per line. Empty if nothing is planned.")
    var plannedNext: String
}

#endif
