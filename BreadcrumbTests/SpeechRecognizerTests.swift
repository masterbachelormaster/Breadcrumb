import Testing
@testable import Breadcrumb

@Suite("SpeechRecognizer Tests")
@MainActor
struct SpeechRecognizerTests {

    @Test("Initial state is not listening")
    func initialState() {
        let recognizer = SpeechRecognizer()
        #expect(recognizer.isListening == false)
        #expect(recognizer.error == nil)
    }

    @Test("stopListening when not listening is safe")
    func stopWhenNotListening() {
        let recognizer = SpeechRecognizer()
        recognizer.stopListening()
        #expect(recognizer.isListening == false)
    }
}
