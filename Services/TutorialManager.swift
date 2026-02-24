import SwiftUI

// MARK: - Tutorial Step

enum TutorialStep: Int, CaseIterable {
    case recordButton    = 0
    case padPercussion1  = 1   // P3
    case padPercussion2  = 2   // P4
    case padMelody       = 3   // M3
    case padVoice        = 4   // V3
    case padBase         = 5   // B4
    case stopButton      = 6
    case fileButton      = 7
    case playButton      = 8
    case complete        = 9

    /// Fixed pad position for each pad step (nil for non-pad steps).
    /// Positions based on SoundPad layout:
    ///   Row 0 (0-4): M1 M2 M3 M4 M5
    ///   Row 1 (5-9): P1 P2 P3 P4 P5
    ///   Row 3 (15-19): V1 V2 M6 V3 V4
    ///   Row 4 (20-24): B1 B2 B3 B4 R6
    static let fixedPadPositions: [TutorialStep: Int] = [
        .padPercussion1: 7,   // P3
        .padPercussion2: 8,   // P4
        .padMelody:      2,   // M3
        .padVoice:       18,  // V3
        .padBase:        23   // B4
    ]

    var title: String {
        switch self {
        case .recordButton:   return "Start Recording"
        case .padPercussion1: return "Percussion · Soribuk"
        case .padPercussion2: return "Percussion · Soribuk"
        case .padMelody:      return "Melody · Haegeum"
        case .padVoice:       return "Voice · Buchae"
        case .padBase:        return "Bass · Geomungo"
        case .stopButton:     return "Stop Recording"
        case .fileButton:     return "Open File List"
        case .playButton:     return "Play Your Recording"
        case .complete:       return "All Done!"
        }
    }

    var message: String {
        switch self {
        case .recordButton:
            return "Tap the red circle to begin recording."
        case .padPercussion1:
            return "Tap the P3 pad to start the beat."
        case .padPercussion2:
            return "Now tap the P4 pad to layer another beat."
        case .padMelody:
            return "Tap the M3 pad to weave in a melody."
        case .padVoice:
            return "Tap the V3 pad to add a vocal texture."
        case .padBase:
            return "Tap the B4 pad to add a bass line."
        case .stopButton:
            return "Tap the square to stop and save your recording."
        case .fileButton:
            return "Tap File to open your saved recordings."
        case .playButton:
            return "Tap the play button on your recording to listen back."
        case .complete:
            return "You're all set — enjoy making music!"
        }
    }

    var next: TutorialStep? { TutorialStep(rawValue: rawValue + 1) }

    /// Static frame key for non-pad steps; pad steps use fixedPadPositions.
    var frameKey: String? {
        switch self {
        case .recordButton: return "record"
        case .stopButton:   return "stop"
        case .fileButton:   return "file"
        case .playButton:   return "play_first"
        default:            return nil
        }
    }
}

// MARK: - Tutorial Manager

@MainActor
class TutorialManager: ObservableObject {
    @Published var isActive: Bool = false
    @Published var step: TutorialStep = .recordButton

    /// @Published so TutorialOverlayView re-renders when frames are registered.
    @Published var frames: [String: CGRect] = [:]

    private let tutorialShownKey = "tutorialHasBeenShown"

    var hasBeenShown: Bool {
        UserDefaults.standard.bool(forKey: tutorialShownKey)
    }

    // MARK: Public API

    /// `sounds` parameter kept for call-site compatibility; fixed positions are used internally.
    func start(sounds: [Sound]) {
        guard !isActive else { return }
        step = .recordButton
        isActive = true
        UserDefaults.standard.set(true, forKey: tutorialShownKey)
    }

    func skip() {
        isActive = false
    }

    func advance() {
        guard let next = step.next else { return }
        if next == .complete {
            step = .complete
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                isActive = false
            }
        } else {
            step = next
        }
    }

    /// Returns the screen-space CGRect for the current tutorial target, or nil if not yet available.
    func currentTargetFrame() -> CGRect? {
        if let key = step.frameKey {
            return frames[key]
        }
        if let pos = TutorialStep.fixedPadPositions[step] {
            return frames["pad_\(pos)"]
        }
        return nil
    }

    /// Call on every pad tap — advances when the correct fixed pad is tapped.
    func handlePadTap(_ sound: Sound) {
        guard isActive,
              let targetPos = TutorialStep.fixedPadPositions[step],
              sound.position == targetPos
        else { return }
        advance()
    }
}
