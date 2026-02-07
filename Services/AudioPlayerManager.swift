import AVFoundation
import SwiftUI

/// AudioPlayerManager - Handles quantized loop playback for pads
@MainActor
class AudioPlayerManager: ObservableObject {
    // MARK: - Properties

    private var audioPlayers: [Int: AVAudioPlayer] = [:]
    private var pendingPads: Set<Int> = [] // Pads waiting for quantization
    private var meteringTimer: Timer?

    @Published var currentAmplitudes: [Float] = Array(repeating: 0.0, count: Constants.totalPads)
    @Published var globalAmplitude: Float = 0.0
    @Published var frequencyBands: [Float] = Array(repeating: 0.0, count: 8)

    // BeatEngine reference
    private weak var beatEngine: BeatEngine?

    // MARK: - Initialization

    init() {
        setupAudioSession()
        startMetering()
    }

    func setBeatEngine(_ engine: BeatEngine) {
        self.beatEngine = engine
    }

    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("❌ Audio session setup failed: \(error.localizedDescription)")
        }
    }

    private func startMetering() {
        meteringTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateAllAmplitudes()
            }
        }
    }

    // MARK: - Quantized Toggle

    /// Toggle sound with quantization
    func toggleSoundQuantized(_ sound: Sound) {
        if isPlaying(at: sound.position) {
            // Stop immediately (no quantization needed for stopping)
            stopSound(at: sound.position)
        } else {
            // Start with quantization
            startSoundQuantized(sound)
        }
    }

    private func startSoundQuantized(_ sound: Sound) {
        guard let beatEngine = beatEngine, beatEngine.isRunning else {
            // If beat engine not running, start immediately
            playSound(sound)
            return
        }

        // Mark as pending
        pendingPads.insert(sound.position)

        // Schedule on next beat (or measure for stronger sync)
        beatEngine.scheduleOnNextBeat { [weak self] in
            guard let self = self else { return }
            Task { @MainActor in
                // Only play if still pending (user didn't cancel)
                if self.pendingPads.contains(sound.position) {
                    self.pendingPads.remove(sound.position)
                    self.playSound(sound)
                }
            }
        }

        print("⏳ Pad \(sound.position) scheduled for next beat")
    }

    // MARK: - Playback Control

    private func playSound(_ sound: Sound) {
        // Find sound file with multiple fallback methods
        var soundURL: URL?

        // Method 1: Bundle.main with Resources subdirectory
        soundURL = Bundle.main.url(forResource: sound.fileName, withExtension: "wav", subdirectory: "Resources")

        // Method 2: Bundle.main direct
        if soundURL == nil {
            soundURL = Bundle.main.url(forResource: sound.fileName, withExtension: "wav")
        }

        // Method 3: Direct file path search
        if soundURL == nil {
            if let resourcePath = Bundle.main.resourcePath {
                let paths = [
                    (resourcePath as NSString).appendingPathComponent("Resources/\(sound.fileName).wav"),
                    (resourcePath as NSString).appendingPathComponent("\(sound.fileName).wav")
                ]

                for path in paths {
                    if FileManager.default.fileExists(atPath: path) {
                        soundURL = URL(fileURLWithPath: path)
                        break
                    }
                }
            }
        }

        guard let finalURL = soundURL else {
            print("❌ Sound file not found: \(sound.fileName).wav")
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: finalURL)
            player.isMeteringEnabled = true
            player.numberOfLoops = -1 // Infinite loop
            player.prepareToPlay()
            player.volume = 1.0
            player.play()

            audioPlayers[sound.position] = player
            print("🎵 Playing: \(sound.fileName) (Loop: ♾️)")
        } catch {
            print("❌ Playback failed: \(error.localizedDescription)")
        }
    }

    func stopSound(at position: Int) {
        if let player = audioPlayers[position] {
            player.stop()
            print("⏹️ Stopped: Position \(position)")
        }
        audioPlayers.removeValue(forKey: position)
        currentAmplitudes[position] = 0.0

        // Remove from pending if was waiting
        pendingPads.remove(position)
    }

    func stopAllSounds() {
        audioPlayers.values.forEach { $0.stop() }
        audioPlayers.removeAll()
        pendingPads.removeAll()
        currentAmplitudes = Array(repeating: 0.0, count: Constants.totalPads)
        globalAmplitude = 0.0
        print("⏹️ All sounds stopped")
    }

    func isPlaying(at position: Int) -> Bool {
        if let player = audioPlayers[position] {
            return player.isPlaying
        }
        return false
    }

    func isPending(at position: Int) -> Bool {
        return pendingPads.contains(position)
    }

    // MARK: - Metering

    private func updateAllAmplitudes() {
        var maxAmplitude: Float = 0.0

        for (position, player) in audioPlayers where player.isPlaying {
            player.updateMeters()

            let avgPower = player.averagePower(forChannel: 0)
            let peakPower = player.peakPower(forChannel: 0)

            let normalizedAvg = pow(10, avgPower / 20)
            let normalizedPeak = pow(10, peakPower / 20)

            let amplitude = (normalizedAvg * 0.6 + normalizedPeak * 0.4)
            currentAmplitudes[position] = max(0.0, min(1.0, amplitude))
            maxAmplitude = max(maxAmplitude, amplitude)
        }

        // Smooth global amplitude
        let targetGlobal = maxAmplitude
        globalAmplitude = globalAmplitude * 0.85 + targetGlobal * 0.15

        // Update frequency bands
        updateFrequencyBands()
    }

    private func updateFrequencyBands() {
        let activeCount = audioPlayers.values.filter { $0.isPlaying }.count

        if activeCount > 0 {
            for i in 0..<frequencyBands.count {
                let baseAmplitude = globalAmplitude
                let variation = Float.random(in: -0.2...0.2)
                let bandAmplitude = baseAmplitude + variation

                let targetValue = max(0.0, min(1.0, bandAmplitude))
                frequencyBands[i] = frequencyBands[i] * 0.7 + targetValue * 0.3
            }
        } else {
            for i in 0..<frequencyBands.count {
                frequencyBands[i] *= 0.85
            }
        }
    }

    deinit {
        meteringTimer?.invalidate()
    }
}
