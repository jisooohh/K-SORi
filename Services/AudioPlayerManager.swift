import AVFoundation
import SwiftUI

/// AudioPlayerManager - Handles quantized loop playback for pads
@MainActor
class AudioPlayerManager: ObservableObject {
    // MARK: - Properties

    private let engineManager = AudioEngineManager.shared
    private var playerNodes: [Int: AVAudioPlayerNode] = [:]
    private var audioBuffers: [Int: AVAudioPCMBuffer] = [:]
    private var pendingPads: Set<Int> = [] // Pads waiting for quantization

    @Published var currentAmplitudes: [Float] = Array(repeating: 0.0, count: Constants.totalPads)
    @Published var globalAmplitude: Float = 0.0
    @Published var frequencyBands: [Float] = Array(repeating: 0.0, count: 8)

    // BeatEngine reference
    private weak var beatEngine: BeatEngine?

    // MARK: - Initialization

    init() {
        engineManager.startEngineIfNeeded()
    }

    func setBeatEngine(_ engine: BeatEngine) {
        self.beatEngine = engine
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

    // MARK: - One-Shot Playback (Voice category)

    /// Play sound exactly once (no loop). Returns actual audio duration in seconds.
    func playSoundOnce(_ sound: Sound) -> TimeInterval {
        var soundURL: URL?
        soundURL = Bundle.main.url(forResource: sound.fileName, withExtension: "wav", subdirectory: "Resources")
        if soundURL == nil {
            soundURL = Bundle.main.url(forResource: sound.fileName, withExtension: "wav")
        }
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
            return 0
        }

        do {
            let file = try AVAudioFile(forReading: finalURL)
            let format = file.processingFormat
            let frameCount = AVAudioFrameCount(file.length)
            let duration = Double(file.length) / format.sampleRate

            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return 0 }
            buffer.frameLength = 0
            try file.read(into: buffer)

            let node = AVAudioPlayerNode()
            engineManager.engine.attach(node)
            engineManager.engine.connect(node, to: engineManager.mainMixer, format: format)
            engineManager.startEngineIfNeeded()

            node.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
            node.play()

            playerNodes[sound.position] = node
            print("🎵 Playing once: \(sound.fileName) (\(String(format: "%.2f", duration))s)")
            return duration
        } catch {
            print("❌ Playback failed: \(error.localizedDescription)")
            return 0
        }
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
            let file = try AVAudioFile(forReading: finalURL)
            let format = file.processingFormat
            let frameCount = AVAudioFrameCount(file.length)

            let buffer: AVAudioPCMBuffer
            if let cached = audioBuffers[sound.position],
               cached.frameCapacity >= frameCount,
               cached.format.sampleRate == format.sampleRate,
               cached.format.channelCount == format.channelCount {
                buffer = cached
            } else {
                guard let newBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
                    print("❌ Failed to create PCM buffer: \(sound.fileName)")
                    return
                }
                audioBuffers[sound.position] = newBuffer
                buffer = newBuffer
            }

            buffer.frameLength = 0
            try file.read(into: buffer)

            let node = AVAudioPlayerNode()
            engineManager.engine.attach(node)
            engineManager.engine.connect(node, to: engineManager.mainMixer, format: format)
            engineManager.startEngineIfNeeded()

            node.scheduleBuffer(buffer, at: nil, options: [.loops], completionHandler: nil)
            node.play()

            playerNodes[sound.position] = node
            print("🎵 Playing: \(sound.fileName) (Loop: ♾️)")
        } catch {
            print("❌ Playback failed: \(error.localizedDescription)")
        }
    }

    func stopSound(at position: Int) {
        if let node = playerNodes[position] {
            node.stop()
            engineManager.engine.detach(node)
            print("⏹️ Stopped: Position \(position)")
        }
        playerNodes.removeValue(forKey: position)
        currentAmplitudes[position] = 0.0

        // Remove from pending if was waiting
        pendingPads.remove(position)
    }

    func stopAllSounds() {
        for node in playerNodes.values {
            node.stop()
            engineManager.engine.detach(node)
        }
        playerNodes.removeAll()
        pendingPads.removeAll()
        currentAmplitudes = Array(repeating: 0.0, count: Constants.totalPads)
        globalAmplitude = 0.0
        print("⏹️ All sounds stopped")
    }

    func isPlaying(at position: Int) -> Bool {
        playerNodes[position]?.isPlaying ?? false
    }

    func isPending(at position: Int) -> Bool {
        return pendingPads.contains(position)
    }

    // MARK: - Metering

    private func updateAllAmplitudes() {}
    private func updateFrequencyBands() {}
}
