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
            nextStep: "Add data section"
        )
        #expect(entry.freeText == "Working on chapter 3")
        #expect(entry.lastAction == "Wrote intro")
        #expect(entry.nextStep == "Add data section")
    }

    @Test("StatusEntry optional fields default to nil")
    func statusEntryOptionalDefaults() {
        let entry = StatusEntry(freeText: "Quick note")
        #expect(entry.lastAction == nil)
        #expect(entry.nextStep == nil)
    }

    @Test("StatusEntry AI extraction fields default to not requested")
    func statusEntryAIExtractionDefaults() {
        let entry = StatusEntry(freeText: "Quick note")
        #expect(entry.aiExtractionState == .notRequested)
        #expect(entry.aiExtractionAttemptCount == 0)
        #expect(entry.aiExtractionNextRetryAt == nil)
        #expect(entry.aiExtractionLastError == nil)
        #expect(entry.aiExtractionSourceText == nil)
        #expect(entry.aiExtractionLanguageRawValue == nil)
    }

    @Test("AI extraction fills only blank optional fields")
    @MainActor
    func aiExtractionFillsOnlyBlankFields() {
        let entry = StatusEntry(
            freeText: "Finished draft and need to edit references",
            lastAction: "User typed work"
        )

        let didApply = AIExtractionCoordinator.applyResult(
            ExtractedStatus(lastAction: "AI work", nextStep: "Edit references"),
            to: entry,
            sourceText: "Finished draft and need to edit references"
        )

        #expect(didApply == true)
        #expect(entry.lastAction == "User typed work")
        #expect(entry.nextStep == "Edit references")
        #expect(entry.aiExtractionState == .completed)
        #expect(entry.aiExtractionSourceText == nil)
    }

    @Test("AI extraction ignores stale source text")
    @MainActor
    func aiExtractionIgnoresStaleSourceText() {
        let entry = StatusEntry(
            freeText: "Edited status text",
            aiExtractionState: .extracting,
            aiExtractionAttemptCount: 1,
            aiExtractionSourceText: "Original status text"
        )

        let didApply = AIExtractionCoordinator.applyResult(
            ExtractedStatus(lastAction: "Old work", nextStep: "Old next step"),
            to: entry,
            sourceText: "Original status text"
        )

        #expect(didApply == false)
        #expect(entry.lastAction == nil)
        #expect(entry.nextStep == nil)
        #expect(entry.aiExtractionState == .notRequested)
        #expect(entry.aiExtractionAttemptCount == 0)
    }

    @Test("AI extraction retry policy fails after final attempt")
    @MainActor
    func aiExtractionRetryPolicy() {
        #expect(AIExtractionCoordinator.stateAfterFailure(attemptCount: 1, maxAttempts: 6) == .retrying)
        #expect(AIExtractionCoordinator.stateAfterFailure(attemptCount: 5, maxAttempts: 6) == .retrying)
        #expect(AIExtractionCoordinator.stateAfterFailure(attemptCount: 6, maxAttempts: 6) == .failed)
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

    @Test("LinkedDocument isValid requires urlString for URL type")
    func isValidURL() {
        let valid = LinkedDocument(type: .url, originalFilename: "example.com", urlString: "https://example.com")
        #expect(valid.isValid == true)
        let invalid = LinkedDocument(type: .url, originalFilename: "example.com")
        #expect(invalid.isValid == false)
    }

    @Test("LinkedDocument isValid requires bookmarkData for file type")
    func isValidFile() {
        let valid = LinkedDocument(type: .file, originalFilename: "doc.pdf", bookmarkData: Data([0x01]))
        #expect(valid.isValid == true)
        let invalid = LinkedDocument(type: .file, originalFilename: "doc.pdf")
        #expect(invalid.isValid == false)
    }

    @Test("LinkedDocument.url factory returns nil for empty string")
    func urlFactoryRejectsEmpty() {
        #expect(LinkedDocument.url(string: "") == nil)
    }

    @Test("LinkedDocument.url factory creates valid document")
    func urlFactoryValid() {
        let doc = LinkedDocument.url(string: "https://example.com/path", label: "My Link")
        #expect(doc != nil)
        #expect(doc?.type == .url)
        #expect(doc?.urlString == "https://example.com/path")
        #expect(doc?.label == "My Link")
    }

    @Test("LinkedDocument.file factory returns nil for empty data")
    func fileFactoryRejectsEmpty() {
        #expect(LinkedDocument.file(bookmark: Data(), originalFilename: "test.pdf") == nil)
    }
}
