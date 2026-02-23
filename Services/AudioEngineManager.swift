import AVFoundation

@MainActor
final class AudioEngineManager {
    static let shared = AudioEngineManager()

    let engine: AVAudioEngine
    let mainMixer: AVAudioMixerNode

    private init() {
        engine = AVAudioEngine()
        mainMixer = engine.mainMixerNode
        configureSession()
        startEngineIfNeeded()
    }

    private func configureSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("❌ Audio session setup failed: \(error.localizedDescription)")
        }
    }

    func startEngineIfNeeded() {
        guard !engine.isRunning else { return }
        do {
            try engine.start()
        } catch {
            print("❌ Audio engine start failed: \(error.localizedDescription)")
        }
    }
}
