import Foundation

/// Decoded from Resources/AudioManifest.json (produced by preprocess_audio.py).
/// Contains per-sound timing metadata used to trim loop buffers and compute bar boundaries.
struct SoundManifest: Decodable {

    struct SoundMeta: Decodable {
        let originalBpm: Double
        let originalLengthSec: Double
        let speedRatio: Double
        let stretchedLengthSec: Double
        let targetBars: Int
        let targetTotalSec: Double
        let extraPadSec: Double
        let startOffsetSec: Double
    }

    let globalBPM: Double
    let barDurationSec: Double
    let sounds: [String: SoundMeta]

    // Returns UInt32 (AVAudioFrameCount typealias) — Foundation-only; no AVFoundation needed.
    func loopFrameCount(for name: String, sampleRate: Double) -> UInt32? {
        guard let meta = sounds[name] else { return nil }
        return UInt32((meta.targetTotalSec * sampleRate).rounded())
    }

    func loopDuration(for name: String) -> Double {
        sounds[name]?.targetTotalSec ?? 2.0
    }

    func bars(for name: String) -> Int {
        sounds[name]?.targetBars ?? 4
    }
}

extension SoundManifest {
    static func loadFromBundle() -> SoundManifest? {
        let candidates: [URL?] = [
            Bundle.main.url(forResource: "AudioManifest", withExtension: "json", subdirectory: "Resources"),
            Bundle.main.url(forResource: "AudioManifest", withExtension: "json")
        ]
        guard let url = candidates.compactMap({ $0 }).first else {
            print("⚠️ AudioManifest.json not found — using default timing")
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(SoundManifest.self, from: data)
        } catch {
            print("⚠️ Failed to decode AudioManifest.json: \(error)")
            return nil
        }
    }
}
