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
}
