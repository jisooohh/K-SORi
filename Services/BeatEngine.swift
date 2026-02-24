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
        60.0 / bpm
    }

    var onBeat: ((Int) -> Void)?
    var onMeasure: ((Int) -> Void)?

    // ── Transport epoch ───────────────────────────────────────────────────────
    /// Hardware timestamp (mach_absolute_time) when the first sound was triggered.
    /// Zero = no transport running.
    private(set) var epochMachTime: UInt64 = 0
    /// Wall-clock date matching epochMachTime (used for SwiftUI phase animation).
    private(set) var epochDate: Date?

    private var timebase: mach_timebase_info_data_t = {
        var i = mach_timebase_info_data_t(); mach_timebase_info(&i); return i
    }()
    private func machToSec(_ t: UInt64) -> Double {
        Double(t) * Double(timebase.numer) / Double(timebase.denom) / 1_000_000_000
    }
    private func secToMach(_ s: Double) -> UInt64 {
        UInt64(s * 1_000_000_000 * Double(timebase.denom) / Double(timebase.numer))
    }

    // MARK: - Transport Epoch API

    /// Capture the current moment as the transport origin (no-op if already set).
    func setEpochToNow() {
        guard epochMachTime == 0 else { return }
        epochMachTime = mach_absolute_time()
        epochDate = Date()
        print("⏱ Transport epoch set")
    }

    /// Clear the epoch so the next sound starts fresh.
    func resetEpoch() {
        epochMachTime = 0
        epochDate = nil
        print("⏱ Transport epoch cleared")
    }

    /// Returns the mach_absolute_time of the next bar boundary (≥60 ms from now).
    func nextBarBoundaryMachTime() -> UInt64 {
        guard epochMachTime > 0 else { return mach_absolute_time() }
        let now = mach_absolute_time()
        let elapsedSec = machToSec(now - epochMachTime)
        let barDur = (60.0 / bpm) * Double(beatsPerMeasure)  // 2.0 s at 120 BPM / 4 beats
        let lookahead = 0.06                                   // 60 ms scheduling window
        let rawBar = Int(elapsedSec / barDur)
        var nextBarSec = Double(rawBar + 1) * barDur
        // If we're already too close to that bar, jump one further
        if nextBarSec - elapsedSec < lookahead {
            nextBarSec = Double(rawBar + 2) * barDur
        }
        return epochMachTime + secToMach(nextBarSec)
    }

    /// Wraps nextBarBoundaryMachTime() as an AVAudioTime for hardware-accurate scheduling.
    func nextBarBoundaryAVAudioTime() -> AVAudioTime {
        AVAudioTime(hostTime: nextBarBoundaryMachTime())
    }

    /// 0…1 phase within `loopDuration` using the wall-clock Date.
    /// Call from TimelineView using context.date for smooth, display-synced animation.
    func transportPhase(for loopDuration: Double, at date: Date) -> Double {
        guard let epochDate = epochDate, loopDuration > 0 else { return 0 }
        let elapsed = date.timeIntervalSince(epochDate)
        return elapsed.truncatingRemainder(dividingBy: loopDuration) / loopDuration
    }

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
        resetEpoch()

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
