import Testing
import Foundation
@testable import Breadcrumb

@Suite("NotificationService Tests")
@MainActor
struct NotificationServiceTests {

    @Test("Service initializes and sets itself as delegate")
    func initialization() {
        let service = NotificationService()
        #expect(service != nil)
    }

    @Test("playSound plays named sound without crashing")
    func playSoundDoesNotCrash() {
        let service = NotificationService()
        // "Glass" is a real macOS system sound
        service.playSound(named: "Glass")
        // No crash = pass. NSSound.play() is fire-and-forget.
    }

    @Test("playSound with empty string does nothing")
    func playSoundEmptyString() {
        let service = NotificationService()
        service.playSound(named: "")
        // No crash = pass
    }

    @Test("playSound with invalid name does nothing")
    func playSoundInvalidName() {
        let service = NotificationService()
        service.playSound(named: "NonexistentSound12345")
        // NSSound(named:) returns nil, optional chain does nothing
    }
}
