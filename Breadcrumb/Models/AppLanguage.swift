enum AppLanguage: String, CaseIterable {
    case german = "de"
    case english = "en"

    var displayName: String {
        switch self {
        case .german: "Deutsch"
        case .english: "English"
        }
    }
}
