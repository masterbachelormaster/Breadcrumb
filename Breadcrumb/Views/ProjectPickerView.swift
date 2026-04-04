import SwiftUI
import SwiftData

struct ProjectPickerView: View {
    @Environment(LanguageManager.self) private var languageManager
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
                        Text(Strings.General.back(languageManager.language))
                    }
                    .font(.body)
                }
                .buttonStyle(ToolbarButtonStyle())

                Spacer()

                Text(Strings.Projects.chooseProject(languageManager.language))
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
                        Text(Strings.Projects.withoutProject(languageManager.language))
                            .font(.headline)
                    }
                    .padding(.vertical, 2)
                }
                .buttonStyle(ListRowButtonStyle())

                ForEach(activeProjects) { project in
                    Button(action: { onSelect(project) }) {
                        ProjectRowView(project: project)
                    }
                    .buttonStyle(ListRowButtonStyle())
                }
            }
        }
    }
}
