import SwiftUI

struct HistoryEntryRow: View {
    @Environment(LanguageManager.self) private var languageManager
    let entry: StatusEntry
    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 8) {
                Text(entry.freeText)
                    .font(.body)

                if let lastAction = entry.lastAction, !lastAction.isEmpty {
                    BulletDetailField(label: Strings.Status.lastStep(languageManager.language), value: lastAction)
                }
                if let nextStep = entry.nextStep, !nextStep.isEmpty {
                    BulletDetailField(label: Strings.Status.nextStep(languageManager.language), value: nextStep)
                }

                AIExtractionStatusView(entry: entry)
            }
            .padding(.vertical, 4)
            .textSelection(.enabled)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    SmartTimestampView(date: entry.timestamp)
                    Text(entry.freeText)
                        .font(.subheadline)
                        .lineLimit(1)
                }
                Spacer()
            }
        }
    }
}

struct AIExtractionStatusView: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(AIExtractionCoordinator.self) private var aiExtractionCoordinator

    let entry: StatusEntry

    var body: some View {
        if entry.aiExtractionState.showsInlineStatus {
            HStack(spacing: 6) {
                statusIcon
                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(statusStyle)
                Spacer(minLength: 0)
                if entry.aiExtractionState == .failed {
                    Button(Strings.AIExtraction.retryExtraction(languageManager.language), systemImage: "arrow.clockwise") {
                        aiExtractionCoordinator.retryExtraction(for: entry, language: languageManager.language)
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderless)
                    .help(Strings.AIExtraction.retryExtraction(languageManager.language))
                }
            }
            .help(entry.aiExtractionLastError ?? statusText)
        }
    }

    @ViewBuilder
    private var statusIcon: some View {
        if entry.aiExtractionState == .failed {
            Image(systemName: "exclamationmark.triangle")
                .font(.caption)
                .foregroundStyle(.orange)
        } else {
            ProgressView()
                .controlSize(.small)
        }
    }

    private var statusText: String {
        let l = languageManager.language
        switch entry.aiExtractionState {
        case .extracting:
            return Strings.AIExtraction.extractionRunning(l)
        case .retrying:
            return Strings.AIExtraction.extractionRetrying(l)
        case .failed:
            return Strings.AIExtraction.extractionFailed(l)
        case .notRequested, .completed:
            return ""
        }
    }

    private var statusStyle: AnyShapeStyle {
        entry.aiExtractionState == .failed ? AnyShapeStyle(.orange) : AnyShapeStyle(.secondary)
    }
}
