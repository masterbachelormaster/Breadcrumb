import SwiftData

extension ModelContext {
    func saveWithLogging() {
        do {
            try save()
        } catch {
            print("SwiftData save failed: \(error)")
        }
    }
}
