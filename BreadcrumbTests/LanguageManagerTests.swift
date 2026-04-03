import Testing
import Foundation
@testable import Breadcrumb

@Suite("AppLanguage Tests")
struct AppLanguageTests {

    @Test("AppLanguage has correct raw values")
    func rawValues() {
        #expect(AppLanguage.german.rawValue == "de")
        #expect(AppLanguage.english.rawValue == "en")
    }

    @Test("AppLanguage displayName is native language name")
    func displayNames() {
        #expect(AppLanguage.german.displayName == "Deutsch")
        #expect(AppLanguage.english.displayName == "English")
    }

    @Test("AppLanguage conforms to CaseIterable")
    func caseIterable() {
        #expect(AppLanguage.allCases.count == 2)
    }
}

@Suite("LanguageManager Tests")
@MainActor
struct LanguageManagerTests {

    @Test("Defaults to German when no stored value")
    func defaultLanguage() {
        UserDefaults.standard.removeObject(forKey: "app.language")
        let manager = LanguageManager()
        #expect(manager.language == .german)
    }

    @Test("Reads stored language from UserDefaults")
    func readsStoredLanguage() {
        UserDefaults.standard.set("en", forKey: "app.language")
        let manager = LanguageManager()
        #expect(manager.language == .english)
        // Cleanup
        UserDefaults.standard.removeObject(forKey: "app.language")
    }

    @Test("Persists language change to UserDefaults")
    func persistsChange() {
        UserDefaults.standard.removeObject(forKey: "app.language")
        let manager = LanguageManager()
        manager.language = .english
        #expect(UserDefaults.standard.string(forKey: "app.language") == "en")
        // Cleanup
        UserDefaults.standard.removeObject(forKey: "app.language")
    }

    @Test("Falls back to German for invalid stored value")
    func invalidStoredValue() {
        UserDefaults.standard.set("fr", forKey: "app.language")
        let manager = LanguageManager()
        #expect(manager.language == .german)
        // Cleanup
        UserDefaults.standard.removeObject(forKey: "app.language")
    }
}
