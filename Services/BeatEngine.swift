import Foundation
import AVFoundation

/// BeatEngine - Metronome and Quantization System
/// Provides BPM-based timing for synchronized pad playback
@MainActor
class BeatEngine: ObservableObject {
    // MARK: - Properties

    @Published var bpm: Double = 120.0 // Default 120 BPM (can be adjusted for Gugak)
    @Published var isRunning: Bool = false
    @Published var currentBeat: Int = 0
    @Published var beatsPerMeasure: Int = 4 // 4/4 time signature

    private var timer: Timer?
    private var startTime: Date?
    private var beatDuration: TimeInterval {
        60.0 / bpm // Duration of one beat in seconds
    }

    // Callbacks for beat events
    var onBeat: ((Int) -> Void)?
    var onMeasure: ((Int) -> Void)?

    // MARK: - Initialization

    init(bpm: Double = 120.0) {
        self.bpm = bpm
    }

    // MARK: - Engine Control

    func start() {
        guard !isRunning else { return }

        isRunning = true
        startTime = Date()
        currentBeat = 0

        // Use high-precision timer
        timer = Timer.scheduledTimer(withTimeInterval: beatDuration, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }

        // Fire first beat immediately
        tick()

        print("🎵 BeatEngine started at \(bpm) BPM")
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        currentBeat = 0

        print("⏹️ BeatEngine stopped")
    }

    private func tick() {
        currentBeat += 1

        // Fire beat callback
        onBeat?(currentBeat)

        // Fire measure callback (every beatsPerMeasure beats)
        if currentBeat % beatsPerMeasure == 0 {
            onMeasure?(currentBeat / beatsPerMeasure)
        }

        print("🎶 Beat: \(currentBeat) (Measure: \(currentBeat / beatsPerMeasure + 1))")
    }

    // MARK: - Quantization

    /// Calculate time until next beat (for quantization)
    func timeUntilNextBeat() -> TimeInterval {
        guard let startTime = startTime else { return 0 }

        let elapsed = Date().timeIntervalSince(startTime)
        let beatsPassed = elapsed / beatDuration
        let nextBeat = ceil(beatsPassed)
        let timeToNextBeat = (nextBeat * beatDuration) - elapsed

        return max(0, timeToNextBeat)
    }

    /// Calculate time until next measure (for stronger quantization)
    func timeUntilNextMeasure() -> TimeInterval {
        guard let startTime = startTime else { return 0 }

        let elapsed = Date().timeIntervalSince(startTime)
        let measuresPassed = elapsed / (beatDuration * Double(beatsPerMeasure))
        let nextMeasure = ceil(measuresPassed)
        let timeToNextMeasure = (nextMeasure * beatDuration * Double(beatsPerMeasure)) - elapsed

        return max(0, timeToNextMeasure)
    }

    /// Schedule action on next beat (Quantization)
    func scheduleOnNextBeat(action: @escaping () -> Void) {
        let delay = timeUntilNextBeat()

        if delay == 0 {
            action()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                action()
            }
            print("⏱️ Scheduled action in \(String(format: "%.3f", delay))s (next beat)")
        }
    }

    /// Schedule action on next measure (Stronger quantization)
    func scheduleOnNextMeasure(action: @escaping () -> Void) {
        let delay = timeUntilNextMeasure()

        if delay == 0 {
            action()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                action()
            }
            print("⏱️ Scheduled action in \(String(format: "%.3f", delay))s (next measure)")
        }
    }

    // MARK: - BPM Control

    func setBPM(_ newBPM: Double) {
        let wasRunning = isRunning

        if wasRunning {
            stop()
        }

        bpm = max(40, min(240, newBPM)) // Clamp between 40-240 BPM

        if wasRunning {
            start()
        }

        print("🎚️ BPM set to \(bpm)")
    }
}
