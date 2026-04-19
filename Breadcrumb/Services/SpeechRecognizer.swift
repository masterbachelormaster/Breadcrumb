import Speech
import AVFoundation
import SwiftUI

@Observable
@MainActor
final class SpeechRecognizer {
    var isListening = false
    var error: String?

    private var audioEngine: AVAudioEngine?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var speechRecognizer: SFSpeechRecognizer?

    private var currentBinding: Binding<String>?
    private var textBeforeListening = ""

    func startListening(into binding: Binding<String>, language: AppLanguage) {
        if isListening {
            stopListening()
        }

        let locale = language == .german ? Locale(identifier: "de-DE") : Locale(identifier: "en-US")
        guard let recognizer = SFSpeechRecognizer(locale: locale), recognizer.isAvailable else {
            error = "Speech recognition not available"
            return
        }

        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            Task { @MainActor in
                guard let self else { return }
                switch status {
                case .authorized:
                    self.beginRecognition(into: binding, recognizer: recognizer)
                default:
                    self.error = "Permission denied"
                }
            }
        }
    }

    func stopListening() {
        recognitionTask?.cancel()
        recognitionTask = nil
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil
        speechRecognizer = nil
        currentBinding = nil
        isListening = false
    }

    private func beginRecognition(into binding: Binding<String>, recognizer: SFSpeechRecognizer) {
        speechRecognizer = recognizer
        currentBinding = binding
        textBeforeListening = binding.wrappedValue

        let engine = AVAudioEngine()
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.addsPunctuation = true

        let inputNode = engine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }

        do {
            engine.prepare()
            try engine.start()
        } catch {
            self.error = "Audio engine failed to start"
            return
        }

        self.audioEngine = engine

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }
                if let result {
                    let transcription = result.bestTranscription.formattedString
                    let prefix = self.textBeforeListening
                    if prefix.isEmpty {
                        self.currentBinding?.wrappedValue = transcription
                    } else {
                        self.currentBinding?.wrappedValue = prefix + " " + transcription
                    }
                }
                if error != nil || (result?.isFinal ?? false) {
                    self.stopListening()
                }
            }
        }

        isListening = true
    }
}
