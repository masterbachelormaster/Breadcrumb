import SwiftUI
import SwiftData

struct DocumentListView: View {
    let project: Project
    var onAddURL: () -> Void
    var onEditLabel: (LinkedDocument) -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(LanguageManager.self) private var languageManager

    @State private var documentToDelete: LinkedDocument?
    @State private var isExpanded = false

    private var sortedDocuments: [LinkedDocument] {
        project.linkedDocuments.sorted { $0.createdAt < $1.createdAt }
    }

    var body: some View {
        let l = languageManager.language

        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
                UserDefaults.standard.set(isExpanded, forKey: "section.documents.\(project.id)")
            } label: {
                HStack {
                    Text(Strings.Documents.documents(l))
                        .font(.headline)
                    if !sortedDocuments.isEmpty {
                        Text("\(sortedDocuments.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.quaternary, in: Capsule())
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
            }
            .buttonStyle(ToolbarButtonStyle())
            .onAppear {
                isExpanded = UserDefaults.standard.bool(forKey: "section.documents.\(project.id)")
            }

            if isExpanded {
                HStack {
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
        if documentToDelete == doc {
            HStack(spacing: 6) {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
                Text(doc.displayName)
                    .lineLimit(1)
                    .foregroundStyle(.secondary)
                Spacer()
                Button(Strings.General.cancel(l)) {
                    documentToDelete = nil
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                Button(Strings.General.delete(l)) {
                    modelContext.delete(doc)
                    modelContext.saveWithLogging()
                    documentToDelete = nil
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .controlSize(.small)
            }
            .padding(.vertical, 2)
        } else {
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
            .buttonStyle(ListRowButtonStyle())
            .contextMenu {
                Button(Strings.Documents.editLabel(l)) {
                    onEditLabel(doc)
                }
                Button(Strings.General.delete(l), role: .destructive) {
                    documentToDelete = doc
                }
            }
        }
    }

    // MARK: - Add Menu

    private func addMenu(language l: AppLanguage) -> some View {
        AddDocumentMenu(language: l, onAddFile: { addFileViaPanel() }, onAddURL: onAddURL)
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

            if isStale, let newData = try? url.bookmarkData() {
                doc.bookmarkData = newData
                modelContext.saveWithLogging()
            }
            NSWorkspace.shared.open(url)
        case .url:
            guard let urlString = doc.urlString else { return }
            let normalized = urlString.contains("://") ? urlString : "https://\(urlString)"
            guard let url = URL(string: normalized) else { return }
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Add File via NSOpenPanel

    private func addFileViaPanel() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        NSApp.keyWindow?.orderOut(nil)
        NSApp.activate()
        let response = panel.runModal()
        guard response == .OK, let url = panel.url else { return }

        guard let bookmarkData = try? url.bookmarkData() else { return }

        let doc = LinkedDocument(
            type: .file,
            originalFilename: url.lastPathComponent,
            bookmarkData: bookmarkData
        )
        doc.project = project
        modelContext.insert(doc)
        modelContext.saveWithLogging()
    }
}

// MARK: - Add Document Menu

private struct AddDocumentMenu: View {
    let language: AppLanguage
    var onAddFile: () -> Void
    var onAddURL: () -> Void

    @State private var isHovered = false

    var body: some View {
        Menu {
            Button(Strings.Documents.addFile(language)) { onAddFile() }
            Button(Strings.Documents.addURL(language)) { onAddURL() }
        } label: {
            Label(Strings.Documents.documents(language), systemImage: "plus.circle")
                .font(.body)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .frame(minWidth: 28, minHeight: 28)
                .contentShape(Rectangle())
        }
        .menuStyle(.borderlessButton)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(isHovered ? Color.primary.opacity(0.06) : .clear)
        )
        .onHover { isHovered = $0 }
    }
}
