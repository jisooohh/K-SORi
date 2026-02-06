import AVFoundation
import SwiftUI

@MainActor
class RecordingManager: ObservableObject {
    private var audioRecorder: AVAudioRecorder?
    private var recordingStartTime: Date?
    @Published var isRecording: Bool = false
    @Published var recordingDuration: TimeInterval = 0

    private var recordingTimer: Timer?

    func startRecording() -> Bool {
        let audioSession = AVAudioSession.sharedInstance()

        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try audioSession.setActive(true)

            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioFilename = documentsPath.appendingPathComponent("recording_\(UUID().uuidString).m4a")

            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.record()

            isRecording = true
            recordingStartTime = Date()
            recordingDuration = 0

            // 타이머 시작
            recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                guard let self = self, let startTime = self.recordingStartTime else { return }
                Task { @MainActor in
                    self.recordingDuration = Date().timeIntervalSince(startTime)
                }
            }

            return true
        } catch {
            print("녹음 시작 실패: \(error.localizedDescription)")
            return false
        }
    }

    func stopRecording() -> RecordedMusic? {
        guard let recorder = audioRecorder, isRecording else { return nil }

        recorder.stop()
        recordingTimer?.invalidate()
        recordingTimer = nil

        let duration = recordingDuration
        let fileName = recorder.url.lastPathComponent

        isRecording = false
        recordingStartTime = nil
        recordingDuration = 0

        let music = RecordedMusic(
            name: "제작 음악 \(DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short))",
            duration: duration,
            fileName: fileName
        )

        return music
    }

    func getRecordingURL(for fileName: String) -> URL? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent(fileName)
    }

    func deleteRecording(fileName: String) {
        guard let url = getRecordingURL(for: fileName) else { return }
        try? FileManager.default.removeItem(at: url)
    }
}
