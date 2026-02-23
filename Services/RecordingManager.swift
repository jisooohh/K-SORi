import AVFoundation
import SwiftUI

/// Records only the app's internal audio output (no microphone) using AVAudioEngine.
@MainActor
class RecordingManager: ObservableObject {

    // MARK: - Published State

    @Published var isRecording: Bool = false
    @Published var recordingDuration: TimeInterval = 0
    /// Set (non-nil) once finishWriting completes — safe to play back at this point
    @Published var lastSavedMusic: RecordedMusic?

    // MARK: - Private

    private let engineManager = AudioEngineManager.shared
    private var recordingFile: AVAudioFile?
    private var recordingFormat: AVAudioFormat?
    private var tapInstalled = false
    private var currentURL: URL?
    private var recordingStartTime: Date?
    private var recordingTimer: Timer?

    // MARK: - Start

    func startRecording() -> Bool {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = docs.appendingPathComponent("recording_\(UUID().uuidString).caf")
        currentURL = url
        engineManager.startEngineIfNeeded()

        let format = engineManager.mainMixer.outputFormat(forBus: 0)
        recordingFormat = format

        do {
            recordingFile = try AVAudioFile(forWriting: url, settings: format.settings)
        } catch {
            print("❌ RecordingManager file setup failed: \(error)")
            return false
        }

        if !tapInstalled {
            engineManager.mainMixer.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
                guard let self, let file = self.recordingFile else { return }
                do {
                    try file.write(from: buffer)
                } catch {
                    print("❌ RecordingManager write failed: \(error)")
                }
            }
            tapInstalled = true
        }

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

    // MARK: - Stop

    func stopRecording() -> RecordedMusic? {
        guard isRecording, let url = currentURL else { return nil }

        isRecording = false
        let duration = recordingDuration
        recordingDuration = 0
        recordingStartTime = nil

        recordingTimer?.invalidate()
        recordingTimer = nil

        let fileName = url.lastPathComponent
        if tapInstalled {
            engineManager.mainMixer.removeTap(onBus: 0)
            tapInstalled = false
        }
        recordingFile = nil
        recordingFormat = nil

        // Return immediately for appState.addRecordedMusic (file will be ready shortly)
        let music = RecordedMusic(
            name: "My Music \(DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short))",
            duration: duration,
            fileName: fileName
        )

        lastSavedMusic = music
        return music
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
