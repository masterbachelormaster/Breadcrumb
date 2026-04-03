import Foundation
import Observation

@Observable
@MainActor
final class LanguageManager {
    private static let storageKey = "app.language"

    var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: Self.storageKey)
        }
    }

    init() {
        let stored = UserDefaults.standard.string(forKey: Self.storageKey) ?? "de"
        language = AppLanguage(rawValue: stored) ?? .german
    }
}
