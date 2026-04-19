@preconcurrency import Speech
@preconcurrency import AVFoundation
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

        currentBinding = binding
        textBeforeListening = binding.wrappedValue

        let locale = language == .german ? Locale(identifier: "de-DE") : Locale(identifier: "en-US")
        guard let recognizer = SFSpeechRecognizer(locale: locale), recognizer.isAvailable else {
            error = "Speech recognition not available"
            currentBinding = nil
            return
        }

        Task {
            let micGranted = await requestMicrophonePermission()
            guard micGranted else {
                error = "Permission denied"
                currentBinding = nil
                return
            }

            let speechGranted = await requestSpeechPermission()
            guard speechGranted else {
                error = "Permission denied"
                currentBinding = nil
                return
            }

            await beginRecognition(recognizer: recognizer)
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

    private func requestMicrophonePermission() async -> Bool {
        if AVAudioApplication.shared.recordPermission == .granted {
            return true
        }
        return await AVAudioApplication.requestRecordPermission()
    }

    private func requestSpeechPermission() async -> Bool {
        let status = SFSpeechRecognizer.authorizationStatus()
        if status == .authorized { return true }
        return await withCheckedContinuation { continuation in
            Self.requestAuth { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    // nonisolated static so the closure has no inherited @MainActor isolation
    private nonisolated static func requestAuth(
        handler: @escaping @Sendable (SFSpeechRecognizerAuthorizationStatus) -> Void
    ) {
        SFSpeechRecognizer.requestAuthorization(handler)
    }

    private func beginRecognition(recognizer: SFSpeechRecognizer) async {
        speechRecognizer = recognizer

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.addsPunctuation = true

        let engine: AVAudioEngine
        do {
            engine = try await Self.prepareAudioEngine(request: request)
        } catch {
            self.error = "Audio engine failed to start"
            return
        }

        self.audioEngine = engine

        let task = Self.startRecognitionTask(
            recognizer: recognizer, request: request
        ) { [weak self] result, error in
            let transcription = result?.bestTranscription.formattedString
            let isFinal = result?.isFinal ?? false
            let hasError = error != nil
            Task { @MainActor in
                guard let self else { return }
                if let transcription {
                    let prefix = self.textBeforeListening
                    if prefix.isEmpty {
                        self.currentBinding?.wrappedValue = transcription
                    } else {
                        self.currentBinding?.wrappedValue = prefix + " " + transcription
                    }
                }
                if hasError || isFinal {
                    self.stopListening()
                }
            }
        }
        self.recognitionTask = task

        isListening = true
    }

    // Run audio engine setup off the main thread —
    // AVAudioEngine.inputNode triggers HAL init with queue assertions
    // incompatible with MainActor
    private static func prepareAudioEngine(
        request: SFSpeechAudioBufferRecognitionRequest
    ) async throws -> AVAudioEngine {
        nonisolated(unsafe) let sendableRequest = request
        let engine = try await Task.detached { () -> AVAudioEngine in
            let engine = AVAudioEngine()
            let inputNode = engine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)

            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                sendableRequest.append(buffer)
            }

            engine.prepare()
            try engine.start()
            return engine
        }.value
        return engine
    }

    // nonisolated static so the closure has no inherited @MainActor isolation
    private nonisolated static func startRecognitionTask(
        recognizer: SFSpeechRecognizer,
        request: SFSpeechAudioBufferRecognitionRequest,
        handler: @escaping @Sendable (SFSpeechRecognitionResult?, (any Error)?) -> Void
    ) -> SFSpeechRecognitionTask {
        recognizer.recognitionTask(with: request, resultHandler: handler)
    }
}
