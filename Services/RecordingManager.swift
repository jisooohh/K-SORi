import AVFoundation
import ReplayKit
import SwiftUI

/// Records only the app's internal audio output (no microphone) using ReplayKit.
@MainActor
class RecordingManager: ObservableObject {

    // MARK: - Published State

    @Published var isRecording: Bool = false
    @Published var recordingDuration: TimeInterval = 0
    /// Set (non-nil) once finishWriting completes — safe to play back at this point
    @Published var lastSavedMusic: RecordedMusic?

    // MARK: - Private

    private var assetWriter: AVAssetWriter?
    private var audioWriterInput: AVAssetWriterInput?
    private var sessionStarted = false
    private var currentURL: URL?
    private var recordingStartTime: Date?
    private var recordingTimer: Timer?

    // MARK: - Start

    func startRecording() -> Bool {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = docs.appendingPathComponent("recording_\(UUID().uuidString).m4a")
        currentURL = url
        sessionStarted = false

        // Configure AVAssetWriter for AAC output
        do {
            let writer = try AVAssetWriter(outputURL: url, fileType: .m4a)
            let audioSettings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            let input = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
            input.expectsMediaDataInRealTime = true
            writer.add(input)
            writer.startWriting()
            assetWriter = writer
            audioWriterInput = input
        } catch {
            print("❌ RecordingManager AssetWriter setup: \(error)")
            return false
        }

        // Start ReplayKit capture — mic OFF, app audio only
        let rp = RPScreenRecorder.shared()
        rp.isMicrophoneEnabled = false
        rp.startCapture(handler: { [weak self] sampleBuffer, bufferType, error in
            guard error == nil, bufferType == .audioApp else { return }
            Task { @MainActor [weak self] in
                self?.handleAudioBuffer(sampleBuffer)
            }
        }, completionHandler: { [weak self] error in
            if let error {
                print("❌ ReplayKit startCapture: \(error)")
                Task { @MainActor [weak self] in
                    self?.isRecording = false
                }
            }
        })

        isRecording = true
        recordingStartTime = Date()
        recordingDuration = 0

        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self, let start = self.recordingStartTime else { return }
            Task { @MainActor in
                self.recordingDuration = Date().timeIntervalSince(start)
            }
        }
        return true
    }

    // MARK: - Handle Audio Buffers (called on Main Actor)

    private func handleAudioBuffer(_ buffer: CMSampleBuffer) {
        guard let writer = assetWriter,
              let input = audioWriterInput,
              writer.status == .writing else { return }

        if !sessionStarted {
            let pts = CMSampleBufferGetPresentationTimeStamp(buffer)
            writer.startSession(atSourceTime: pts)
            sessionStarted = true
        }

        if input.isReadyForMoreMediaData {
            input.append(buffer)
        }
    }

    // MARK: - Stop

    func stopRecording() -> RecordedMusic? {
        guard isRecording, let url = currentURL else { return nil }

        isRecording = false
        let duration = recordingDuration
        recordingDuration = 0
        recordingStartTime = nil

        recordingTimer?.invalidate()
        recordingTimer = nil

        // Stop ReplayKit
        RPScreenRecorder.shared().stopCapture { error in
            if let error { print("❌ stopCapture: \(error)") }
        }

        // Finish writing — notify via lastSavedMusic when done
        let capturedInput = audioWriterInput
        let capturedWriter = assetWriter
        let fileName = url.lastPathComponent

        capturedInput?.markAsFinished()
        capturedWriter?.finishWriting { [weak self] in
            let music = RecordedMusic(
                name: "My Music \(DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short))",
                duration: duration,
                fileName: fileName
            )
            Task { @MainActor [weak self] in
                self?.lastSavedMusic = music
            }
        }

        assetWriter = nil
        audioWriterInput = nil
        sessionStarted = false

        // Return immediately for appState.addRecordedMusic (file will be ready shortly)
        return RecordedMusic(
            name: "My Music \(DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short))",
            duration: duration,
            fileName: fileName
        )
    }

    // MARK: - Helpers

    func getRecordingURL(for fileName: String) -> URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }

    func deleteRecording(fileName: String) {
        guard let url = getRecordingURL(for: fileName) else { return }
        try? FileManager.default.removeItem(at: url)
    }
}
