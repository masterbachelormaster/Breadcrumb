import SwiftUI
import SwiftData

struct ProjectPickerView: View {
    @Query(filter: #Predicate<Project> { $0.isActive })
    private var activeProjects: [Project]

    var onSelect: (Project?) -> Void
    var onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Zurück")
                    }
                    .font(.body)
                }
                .buttonStyle(.plain)

                Spacer()

                Text("Projekt wählen")
                    .font(.headline)

                Spacer()

                Color.clear.frame(width: 60, height: 1)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            // Content
            List {
                Button(action: { onSelect(nil) }) {
                    HStack(spacing: 10) {
                        Image(systemName: "timer")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .frame(width: 24)
                        Text("Ohne Projekt")
                            .font(.headline)
                    }
                    .padding(.vertical, 2)
                }
                .buttonStyle(.plain)

                ForEach(activeProjects) { project in
                    Button(action: { onSelect(project) }) {
                        ProjectRowView(project: project)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
