import Testing
@testable import Breadcrumb

@Suite("Strings Tests")
struct StringsTests {

    @Test("General strings return German for .german")
    func generalGerman() {
        let l = AppLanguage.german
        #expect(Strings.General.back(l) == "Zurück")
        #expect(Strings.General.settings(l) == "Einstellungen")
        #expect(Strings.General.save(l) == "Speichern")
        #expect(Strings.General.cancel(l) == "Abbrechen")
    }

    @Test("General strings return English for .english")
    func generalEnglish() {
        let l = AppLanguage.english
        #expect(Strings.General.back(l) == "Back")
        #expect(Strings.General.settings(l) == "Settings")
        #expect(Strings.General.save(l) == "Save")
        #expect(Strings.General.cancel(l) == "Cancel")
    }

    @Test("Pomodoro strings return correct translations")
    func pomodoroStrings() {
        #expect(Strings.Pomodoro.focusTime(.german) == "Fokuszeit")
        #expect(Strings.Pomodoro.focusTime(.english) == "Focus Time")
        #expect(Strings.Pomodoro.shortBreak(.german) == "Kurze Pause")
        #expect(Strings.Pomodoro.shortBreak(.english) == "Short Break")
    }

    @Test("AI extraction instructions exist for both languages")
    func aiInstructions() {
        let de = Strings.AIExtraction.instructions(.german)
        let en = Strings.AIExtraction.instructions(.english)
        #expect(de.contains("extrahierst"))
        #expect(en.contains("extract"))
    }

    @Test("Documents strings return correct translations")
    func documentsStrings() {
        #expect(Strings.Documents.documents(.german) == "Dokumente")
        #expect(Strings.Documents.documents(.english) == "Documents")
        #expect(Strings.Documents.addFile(.german) == "Datei hinzufügen…")
        #expect(Strings.Documents.addFile(.english) == "Add File…")
        #expect(Strings.Documents.addURL(.german) == "Link hinzufügen…")
        #expect(Strings.Documents.addURL(.english) == "Add URL…")
        #expect(Strings.Documents.fileNotFound(.german) == "Datei nicht gefunden")
        #expect(Strings.Documents.fileNotFound(.english) == "File not found")
        #expect(Strings.Documents.editLabel(.german) == "Bezeichnung bearbeiten")
        #expect(Strings.Documents.editLabel(.english) == "Edit Label")
        #expect(Strings.Documents.urlPlaceholder(.german) == "URL eingeben")
        #expect(Strings.Documents.urlPlaceholder(.english) == "Enter URL")
        #expect(Strings.Documents.labelPlaceholder(.german) == "Bezeichnung (optional)")
        #expect(Strings.Documents.labelPlaceholder(.english) == "Label (optional)")
    }
}
