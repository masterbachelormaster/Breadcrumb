import Testing
import Foundation
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
}
