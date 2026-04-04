import SwiftUI
import SwiftData
import AppKit

struct DocumentListView: View {
    let project: Project
    var onAddURL: () -> Void
    var onEditLabel: (LinkedDocument) -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(LanguageManager.self) private var languageManager

    private var sortedDocuments: [LinkedDocument] {
        project.linkedDocuments.sorted { $0.createdAt < $1.createdAt }
    }

    var body: some View {
        let l = languageManager.language

        if sortedDocuments.isEmpty {
            addMenu(language: l)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(Strings.Documents.documents(l))
                        .font(.headline)
                    Spacer()
                    addMenu(language: l)
                }

                ForEach(sortedDocuments) { doc in
                    documentRow(doc, language: l)
                }
            }
        }
    }

    // MARK: - Document Row

    @ViewBuilder
    private func documentRow(_ doc: LinkedDocument, language l: AppLanguage) -> some View {
        Button {
            openDocument(doc)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: doc.type == .file ? "doc.fill" : "link")
                    .foregroundStyle(.secondary)

                if doc.type == .file && resolveBookmark(doc) == nil {
                    Text(Strings.Documents.fileNotFound(l))
                        .foregroundStyle(.red)
                        .lineLimit(1)
                } else {
                    Text(doc.displayName)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(Strings.Documents.editLabel(l)) {
                onEditLabel(doc)
            }
            Button(Strings.General.delete(l), role: .destructive) {
                modelContext.delete(doc)
            }
        }
    }

    // MARK: - Add Menu

    private func addMenu(language l: AppLanguage) -> some View {
        Menu {
            Button(Strings.Documents.addFile(l)) {
                addFileViaPanel()
            }
            Button(Strings.Documents.addURL(l)) {
                onAddURL()
            }
        } label: {
            Label(Strings.Documents.documents(l), systemImage: "plus.circle")
                .font(.body)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Bookmark Resolution

    private func resolveBookmark(_ doc: LinkedDocument) -> URL? {
        guard doc.type == .file, let bookmarkData = doc.bookmarkData else {
            return nil
        }

        var isStale = false
        guard let url = try? URL(
            resolvingBookmarkData: bookmarkData,
            options: [],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ) else {
            return nil
        }

        return url
    }

    // MARK: - Open Document

    private func openDocument(_ doc: LinkedDocument) {
        switch doc.type {
        case .file:
            guard let data = doc.bookmarkData else { return }
            var isStale = false
            guard let url = try? URL(
                resolvingBookmarkData: data,
                options: [],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            ) else { return }

            if isStale {
                doc.bookmarkData = try? url.bookmarkData()
            }
            NSWorkspace.shared.open(url)
        case .url:
            guard let urlString = doc.urlString,
                  let url = URL(string: urlString) else { return }
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Add File via NSOpenPanel

    private func addFileViaPanel() {
        let container = modelContext.container
        let projectID = project.persistentModelID

        Task { @MainActor in
            let panel = NSOpenPanel()
            panel.allowsMultipleSelection = false
            panel.canChooseDirectories = false

            let response = await panel.begin()
            guard response == .OK, let url = panel.url else { return }

            let newContext = ModelContext(container)
            guard let projectInContext = newContext.model(for: projectID) as? Project else { return }
            guard let bookmarkData = try? url.bookmarkData() else { return }

            let doc = LinkedDocument(
                type: .file,
                originalFilename: url.lastPathComponent,
                bookmarkData: bookmarkData
            )
            doc.project = projectInContext
            newContext.insert(doc)
            try? newContext.save()
        }
    }
}
