import AVFoundation
import SwiftUI

/// AudioPlayerManager - Handles quantized loop playback for pads
@MainActor
class AudioPlayerManager: ObservableObject {
    // MARK: - Properties

    private let engineManager = AudioEngineManager.shared
    private var playerNodes: [Int: AVAudioPlayerNode] = [:]
    private var audioBuffers: [Int: AVAudioPCMBuffer] = [:]

    @Published var currentAmplitudes: [Float] = Array(repeating: 0.0, count: Constants.totalPads)
    @Published var globalAmplitude: Float = 0.0
    @Published var frequencyBands: [Float] = Array(repeating: 0.0, count: 8)

    private weak var beatEngine: BeatEngine?
    private var manifest: SoundManifest?

    // MARK: - Initialization

    init() {
        engineManager.startEngineIfNeeded()
        manifest = SoundManifest.loadFromBundle()
    }

    func setBeatEngine(_ engine: BeatEngine) {
        self.beatEngine = engine
    }

    // MARK: - Loop Duration

    /// Total loop length in seconds for a given file name.
    /// Falls back to 2.0 s (one bar at 120 BPM) when no manifest is present.
    func loopDuration(for fileName: String) -> Double {
        manifest?.loopDuration(for: fileName) ?? 2.0
    }

    // MARK: - Quantized Toggle

    func toggleSoundQuantized(_ sound: Sound) {
        if isPlaying(at: sound.position) {
            stopSound(at: sound.position)
        } else {
            startSoundQuantized(sound)
        }
    }

    private func startSoundQuantized(_ sound: Sound) {
        guard let beatEngine = beatEngine, beatEngine.isRunning else {
            playSound(sound, at: nil)
            return
        }

        if beatEngine.epochMachTime == 0 {
            // First sound ever: play immediately then stamp the epoch
            playSound(sound, at: nil)
            beatEngine.setEpochToNow()
        } else {
            // Align to the next bar boundary of the running transport
            let schedTime = beatEngine.nextBarBoundaryAVAudioTime()
            playSound(sound, at: schedTime)
        }
    }

    // MARK: - One-Shot Playback (Voice category)

    /// Play sound exactly once (no loop). Returns actual audio duration in seconds.
    func playSoundOnce(_ sound: Sound) -> TimeInterval {
        guard let finalURL = resolveURL(for: sound.fileName) else {
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
            applyFade(to: buffer, fadeSamples: min(Int(format.sampleRate * 0.01), Int(frameCount)))

            let node = makeNode(format: format)
            node.volume = 2.0
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

    // MARK: - Playback Core

    private func playSound(_ sound: Sound, at scheduleTime: AVAudioTime?) {
        guard let finalURL = resolveURL(for: sound.fileName) else {
            print("❌ Sound file not found: \(sound.fileName).wav")
            return
        }

        do {
            let file = try AVAudioFile(forReading: finalURL)
            let format = file.processingFormat
            let sampleRate = format.sampleRate

            // Determine how many frames to read (trimmed to exact loop length when manifest is available)
            let totalFrames = AVAudioFrameCount(file.length)
            let loopFrames: AVAudioFrameCount
            if let fc = manifest?.loopFrameCount(for: sound.fileName, sampleRate: sampleRate) {
                loopFrames = min(fc, totalFrames)
            } else {
                loopFrames = totalFrames
            }

            // Reuse cached buffer when possible
            let buffer: AVAudioPCMBuffer
            if let cached = audioBuffers[sound.position],
               cached.frameCapacity >= loopFrames,
               cached.format.sampleRate == sampleRate,
               cached.format.channelCount == format.channelCount {
                buffer = cached
            } else {
                guard let newBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: loopFrames) else {
                    print("❌ Failed to create PCM buffer: \(sound.fileName)")
                    return
                }
                audioBuffers[sound.position] = newBuffer
                buffer = newBuffer
            }

            buffer.frameLength = 0
            try file.read(into: buffer, frameCount: loopFrames)

            // 10 ms linear fade in/out to prevent clicks at loop points
            let fadeSamples = min(Int(sampleRate * 0.01), Int(loopFrames))
            applyFade(to: buffer, fadeSamples: fadeSamples)

            let node = makeNode(format: format)
            let volume: Float
            if sound.category == .rhythm {
                volume = 1.5
            } else if ["B1", "B2", "B3"].contains(sound.fileName) {
                volume = 0.8
            } else {
                volume = 1.0
            }
            node.volume = volume

            node.scheduleBuffer(buffer, at: scheduleTime, options: [.loops], completionHandler: nil)
            node.play()

            playerNodes[sound.position] = node

            let timeStr = scheduleTime == nil ? "immediately" : "at next bar"
            print("🎵 Playing: \(sound.fileName) (Loop ♾, \(timeStr))")
        } catch {
            print("❌ Playback failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Stop

    func stopSound(at position: Int) {
        if let node = playerNodes[position] {
            node.stop()
            engineManager.engine.detach(node)
            print("⏹️ Stopped: Position \(position)")
        }
        playerNodes.removeValue(forKey: position)
        currentAmplitudes[position] = 0.0
    }

    func stopAllSounds() {
        for node in playerNodes.values {
            node.stop()
            engineManager.engine.detach(node)
        }
        playerNodes.removeAll()
        currentAmplitudes = Array(repeating: 0.0, count: Constants.totalPads)
        globalAmplitude = 0.0
        beatEngine?.resetEpoch()
        print("⏹️ All sounds stopped")
    }

    // MARK: - State

    func isPlaying(at position: Int) -> Bool {
        playerNodes[position]?.isPlaying ?? false
    }

    // MARK: - Helpers

    private func resolveURL(for fileName: String) -> URL? {
        if let url = Bundle.main.url(forResource: fileName, withExtension: "wav", subdirectory: "Resources") { return url }
        if let url = Bundle.main.url(forResource: fileName, withExtension: "wav") { return url }
        if let base = Bundle.main.resourcePath {
            for suffix in ["Resources/\(fileName).wav", "\(fileName).wav"] {
                let path = (base as NSString).appendingPathComponent(suffix)
                if FileManager.default.fileExists(atPath: path) {
                    return URL(fileURLWithPath: path)
                }
            }
        }
        return nil
    }

    private func makeNode(format: AVAudioFormat) -> AVAudioPlayerNode {
        let node = AVAudioPlayerNode()
        engineManager.engine.attach(node)
        engineManager.engine.connect(node, to: engineManager.mainMixer, format: format)
        engineManager.startEngineIfNeeded()
        return node
    }

    /// Linear 10 ms fade-in at start and fade-out at end of buffer to prevent clicks.
    private func applyFade(to buffer: AVAudioPCMBuffer, fadeSamples: Int) {
        guard fadeSamples > 0,
              let channelData = buffer.floatChannelData else { return }
        let frameLength = Int(buffer.frameLength)
        let channelCount = Int(buffer.format.channelCount)
        for ch in 0..<channelCount {
            let data = channelData[ch]
            // Fade in
            for i in 0..<min(fadeSamples, frameLength) {
                data[i] *= Float(i) / Float(fadeSamples)
            }
            // Fade out
            let fadeOutStart = max(0, frameLength - fadeSamples)
            for i in fadeOutStart..<frameLength {
                let ramp = Float(frameLength - i) / Float(fadeSamples)
                data[i] *= ramp
            }
        }
    }

    // MARK: - Metering (stub)
    private func updateAllAmplitudes() {}
    private func updateFrequencyBands() {}
}
