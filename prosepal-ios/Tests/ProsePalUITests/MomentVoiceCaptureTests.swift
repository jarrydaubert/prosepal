import ProsePalUI
import Testing

@Test
@MainActor
func voiceCaptureStartsRecordingAndSurfacesTranscript() async throws {
    let transcriber = StubMomentVoiceCaptureTranscriber(
        authorization: .authorized,
        transcripts: ["I miss our Sunday calls."]
    )
    let capture = MomentVoiceCaptureModel(transcriber: transcriber)

    await capture.start()

    #expect(capture.state == .recording)
    #expect(capture.transcript == "I miss our Sunday calls.")
    #expect(capture.canUseTranscript)
    #expect(transcriber.startCallCount == 1)

    capture.stop()

    #expect(capture.state == .finished)
    #expect(transcriber.stopCallCount == 1)
}

@Test
@MainActor
func voiceCaptureDeniedPermissionDoesNotStartRecording() async throws {
    let transcriber = StubMomentVoiceCaptureTranscriber(
        authorization: .denied("Allow Microphone access in Settings to use voice input.")
    )
    let capture = MomentVoiceCaptureModel(transcriber: transcriber)

    await capture.start()

    #expect(capture.state == .unavailable("Allow Microphone access in Settings to use voice input."))
    #expect(capture.transcript == "")
    #expect(!capture.canUseTranscript)
    #expect(transcriber.startCallCount == 0)
}

@Test
@MainActor
func voiceCaptureStartFailureShowsUserSafeMessage() async throws {
    let transcriber = StubMomentVoiceCaptureTranscriber(
        authorization: .authorized,
        startError: MomentVoiceCaptureError.unavailable("Voice input is not available right now.")
    )
    let capture = MomentVoiceCaptureModel(transcriber: transcriber)

    await capture.start()

    #expect(capture.state == .failed("Voice input is not available right now."))
    #expect(capture.transcript == "")
    #expect(transcriber.startCallCount == 1)
}

@Test
@MainActor
func voiceCaptureResetClearsTranscriptAndStopsTranscriber() async throws {
    let transcriber = StubMomentVoiceCaptureTranscriber(
        authorization: .authorized,
        transcripts: ["Please tell Mira I am sorry."]
    )
    let capture = MomentVoiceCaptureModel(transcriber: transcriber)

    await capture.start()
    capture.reset()

    #expect(capture.state == .idle)
    #expect(capture.transcript == "")
    #expect(!capture.canUseTranscript)
    #expect(transcriber.stopCallCount == 1)
}

@MainActor
private final class StubMomentVoiceCaptureTranscriber: MomentVoiceCaptureTranscribing {
    private let authorization: MomentVoiceCaptureAuthorization
    private let transcripts: [String]
    private let startError: Error?

    private(set) var startCallCount = 0
    private(set) var stopCallCount = 0

    init(
        authorization: MomentVoiceCaptureAuthorization,
        transcripts: [String] = [],
        startError: Error? = nil
    ) {
        self.authorization = authorization
        self.transcripts = transcripts
        self.startError = startError
    }

    func requestAuthorization() async -> MomentVoiceCaptureAuthorization {
        authorization
    }

    func start(onTranscript: @escaping @MainActor (String) -> Void) async throws {
        startCallCount += 1

        if let startError {
            throw startError
        }

        for transcript in transcripts {
            onTranscript(transcript)
        }
    }

    func stop() {
        stopCallCount += 1
    }
}
