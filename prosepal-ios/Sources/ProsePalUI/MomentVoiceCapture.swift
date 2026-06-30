import Foundation
import Observation

#if os(iOS) && canImport(AVFoundation) && canImport(Speech)
import AVFoundation
import Speech
#endif

public enum MomentVoiceCaptureAuthorization: Equatable, Sendable {
    case authorized
    case unavailable(String)
    case denied(String)

    var denialMessage: String? {
        switch self {
        case .authorized:
            nil
        case .unavailable(let message), .denied(let message):
            message
        }
    }
}

public enum MomentVoiceCaptureState: Equatable, Sendable {
    case idle
    case requestingPermission
    case recording
    case finished
    case unavailable(String)
    case failed(String)
}

public enum MomentVoiceCaptureError: Error, Equatable, Sendable {
    case unavailable(String)
    case failed(String)

    var userMessage: String {
        switch self {
        case .unavailable(let message), .failed(let message):
            message
        }
    }
}

@MainActor
public protocol MomentVoiceCaptureTranscribing: AnyObject {
    func requestAuthorization() async -> MomentVoiceCaptureAuthorization
    func start(onTranscript: @escaping @MainActor (String) -> Void) async throws
    func stop()
}

@MainActor
@Observable
public final class MomentVoiceCaptureModel {
    public private(set) var transcript = ""
    public private(set) var state: MomentVoiceCaptureState = .idle

    @ObservationIgnored private let transcriber: any MomentVoiceCaptureTranscribing

    public init(transcriber: any MomentVoiceCaptureTranscribing = MomentVoiceCaptureTranscriberFactory.live()) {
        self.transcriber = transcriber
    }

    public var canUseTranscript: Bool {
        !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public var isRecording: Bool {
        state == .recording
    }

    public var isRequestingPermission: Bool {
        state == .requestingPermission
    }

    public var statusText: String {
        switch state {
        case .idle:
            "Ready to listen when you are."
        case .requestingPermission:
            "Checking microphone access."
        case .recording:
            "Listening..."
        case .finished:
            canUseTranscript ? "Review the captured words." : "No words captured yet."
        case .unavailable(let message), .failed(let message):
            message
        }
    }

    public func start() async {
        if isRecording {
            stop()
        }

        state = .requestingPermission
        let authorization = await transcriber.requestAuthorization()
        guard authorization == .authorized else {
            state = .unavailable(
                authorization.denialMessage ?? "Voice input is not available on this device."
            )
            return
        }

        transcript = ""

        do {
            try await transcriber.start { [weak self] nextTranscript in
                self?.transcript = nextTranscript
            }
            state = .recording
        } catch let error as MomentVoiceCaptureError {
            state = .failed(error.userMessage)
        } catch {
            state = .failed("Voice input stopped before ProsePal could capture words.")
        }
    }

    public func stop() {
        transcriber.stop()

        switch state {
        case .recording, .requestingPermission:
            state = .finished
        case .idle, .finished, .unavailable, .failed:
            break
        }
    }

    public func reset() {
        transcriber.stop()
        transcript = ""
        state = .idle
    }
}

public enum MomentVoiceCaptureTranscriberFactory {
    @MainActor
    public static func live() -> any MomentVoiceCaptureTranscribing {
        #if os(iOS) && canImport(AVFoundation) && canImport(Speech)
        AppleSpeechMomentVoiceTranscriber()
        #else
        UnavailableMomentVoiceCaptureTranscriber(
            message: "Voice input is available on iPhone and iPad."
        )
        #endif
    }
}

@MainActor
private final class UnavailableMomentVoiceCaptureTranscriber: MomentVoiceCaptureTranscribing {
    private let message: String

    init(message: String) {
        self.message = message
    }

    func requestAuthorization() async -> MomentVoiceCaptureAuthorization {
        .unavailable(message)
    }

    func start(onTranscript: @escaping @MainActor (String) -> Void) async throws {
        throw MomentVoiceCaptureError.unavailable(message)
    }

    func stop() {}
}

#if os(iOS) && canImport(AVFoundation) && canImport(Speech)
@MainActor
private final class AppleSpeechMomentVoiceTranscriber: NSObject, MomentVoiceCaptureTranscribing {
    private let speechRecognizer = SFSpeechRecognizer()
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var onTranscript: (@MainActor (String) -> Void)?

    func requestAuthorization() async -> MomentVoiceCaptureAuthorization {
        guard let speechRecognizer else {
            return .unavailable("Voice input is not available for this locale.")
        }

        guard speechRecognizer.supportsOnDeviceRecognition else {
            return .unavailable("On-device voice input is not available for this locale.")
        }

        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        guard speechStatus == .authorized else {
            return .denied("Allow Speech Recognition in Settings to use voice input.")
        }

        let microphoneGranted = await requestMicrophonePermission()
        guard microphoneGranted else {
            return .denied("Allow Microphone access in Settings to use voice input.")
        }

        return .authorized
    }

    func start(onTranscript: @escaping @MainActor (String) -> Void) async throws {
        stop()

        guard let speechRecognizer, speechRecognizer.supportsOnDeviceRecognition else {
            throw MomentVoiceCaptureError.unavailable("On-device voice input is not available for this locale.")
        }

        guard speechRecognizer.isAvailable else {
            throw MomentVoiceCaptureError.unavailable("Voice input is not available right now.")
        }

        self.onTranscript = onTranscript

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: [.duckOthers])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = true
        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1_024, format: recordingFormat) { [weak request] buffer, _ in
            request?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                if let result {
                    self?.onTranscript?(result.bestTranscription.formattedString)
                }

                if error != nil || result?.isFinal == true {
                    self?.stop()
                }
            }
        }
    }

    func stop() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        recognitionRequest?.endAudio()
        recognitionTask?.finish()
        recognitionRequest = nil
        recognitionTask = nil
        onTranscript = nil

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { isGranted in
                continuation.resume(returning: isGranted)
            }
        }
    }
}
#endif
