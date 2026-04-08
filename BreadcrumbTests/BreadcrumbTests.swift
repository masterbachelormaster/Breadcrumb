import Testing
import Foundation
import SwiftData
@testable import Breadcrumb

@Suite("Model Tests")
struct ModelTests {

    @Test("Project initializes with correct defaults")
    func projectDefaults() {
        let project = Project(name: "Thesis")
        #expect(project.name == "Thesis")
        #expect(project.icon == "doc.text")
        #expect(project.isActive == true)
        #expect(project.entries.isEmpty)
        #expect(project.latestEntry == nil)
    }

    @Test("StatusEntry initializes with required and optional fields")
    func statusEntryInit() {
        let entry = StatusEntry(
            freeText: "Working on chapter 3",
            lastAction: "Wrote intro",
            nextStep: "Add data section",
            openQuestions: "Which dataset?"
        )
        #expect(entry.freeText == "Working on chapter 3")
        #expect(entry.lastAction == "Wrote intro")
        #expect(entry.nextStep == "Add data section")
        #expect(entry.openQuestions == "Which dataset?")
    }

    @Test("StatusEntry optional fields default to nil")
    func statusEntryOptionalDefaults() {
        let entry = StatusEntry(freeText: "Quick note")
        #expect(entry.lastAction == nil)
        #expect(entry.nextStep == nil)
        #expect(entry.openQuestions == nil)
    }

    @Test("Project latestEntry returns most recent")
    func latestEntry() {
        let project = Project(name: "Test")
        let older = StatusEntry(freeText: "old")
        older.timestamp = Date.distantPast
        let newer = StatusEntry(freeText: "new")
        newer.timestamp = Date()
        project.entries = [older, newer]
        #expect(project.latestEntry?.freeText == "new")
    }

    @Test("StatusEntry preserves newline-separated nextStep across save and fetch")
    @MainActor
    func nextStepNewlinesRoundTrip() throws {
        let container = try ModelContainer(
            for: Project.self, StatusEntry.self, PomodoroSession.self, LinkedDocument.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)

        let project = Project(name: "Test")
        context.insert(project)

        let entry = StatusEntry(
            freeText: "test entry",
            nextStep: "first step\nsecond step\nthird step"
        )
        entry.project = project
        project.entries.append(entry)
        context.insert(entry)

        try context.save()

        let fetched = try context.fetch(FetchDescriptor<StatusEntry>())

        #expect(fetched.count == 1)
        #expect(fetched.first?.nextStep == "first step\nsecond step\nthird step")
    }
}

@Suite("LinkedDocument Tests")
struct LinkedDocumentTests {

    @Test("LinkedDocument file initializes with correct defaults")
    func fileDefaults() {
        let doc = LinkedDocument(
            type: .file,
            originalFilename: "report.docx",
            bookmarkData: Data([0x01, 0x02])
        )
        #expect(doc.type == .file)
        #expect(doc.originalFilename == "report.docx")
        #expect(doc.bookmarkData == Data([0x01, 0x02]))
        #expect(doc.urlString == nil)
        #expect(doc.label == nil)
        #expect(doc.project == nil)
    }

    @Test("LinkedDocument URL initializes with correct defaults")
    func urlDefaults() {
        let doc = LinkedDocument(
            type: .url,
            originalFilename: "example.com",
            urlString: "https://example.com/doc"
        )
        #expect(doc.type == .url)
        #expect(doc.originalFilename == "example.com")
        #expect(doc.urlString == "https://example.com/doc")
        #expect(doc.bookmarkData == nil)
        #expect(doc.label == nil)
    }

    @Test("LinkedDocument displayName prefers label over filename")
    func displayName() {
        let doc = LinkedDocument(
            type: .file,
            originalFilename: "report_v3_final.docx",
            bookmarkData: Data()
        )
        #expect(doc.displayName == "report_v3_final.docx")
        doc.label = "Project Brief"
        #expect(doc.displayName == "Project Brief")
    }

    @Test("LinkedDocument displayName falls back when label is empty string")
    func displayNameEmptyLabel() {
        let doc = LinkedDocument(type: .file, originalFilename: "report.docx", bookmarkData: Data())
        doc.label = ""
        #expect(doc.displayName == "report.docx")
    }

    @Test("Project linkedDocuments defaults to empty")
    func projectLinkedDocumentsEmpty() {
        let project = Project(name: "Test")
        #expect(project.linkedDocuments.isEmpty)
    }
}
