import SwiftUI

// MARK: - Tutorial Step

enum TutorialStep: Int, CaseIterable {
    case recordButton  = 0
    case padBase       = 1
    case padRhythm     = 2
    case padMelody     = 3
    case padPercussion = 4
    case padVoice      = 5
    case stopButton    = 6
    case fileButton    = 7
    case playButton    = 8
    case complete      = 9

    var title: String {
        switch self {
        case .recordButton:  return "Start Recording"
        case .padBase:       return "Bass · Geomungo"
        case .padRhythm:     return "Rhythm · Janggu"
        case .padMelody:     return "Melody · Haegeum"
        case .padPercussion: return "Percussion · Soribuk"
        case .padVoice:      return "Voice · Buchae"
        case .stopButton:    return "Stop Recording"
        case .fileButton:    return "Open File List"
        case .playButton:    return "Play Your Recording"
        case .complete:      return "All Done!"
        }
    }

    var message: String {
        switch self {
        case .recordButton:
            return "Tap the red circle to begin recording."
        case .padBase:
            return "Tap any Base (B) pad to layer in a bass line."
        case .padRhythm:
            return "Tap any Rhythm (R) pad to add a rhythmic pulse."
        case .padMelody:
            return "Tap any Melody (M) pad to weave in a melody."
        case .padPercussion:
            return "Tap any Percussion (P) pad to add a beat."
        case .padVoice:
            return "Tap any Voice (V) pad to add a vocal texture."
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

    /// The pad category targeted at this step (nil if not a pad step)
    var targetCategory: Constants.SoundCategory? {
        switch self {
        case .padBase:       return .base
        case .padRhythm:     return .rhythm
        case .padMelody:     return .melody
        case .padPercussion: return .percussion
        case .padVoice:      return .voice
        default:             return nil
        }
    }

    var next: TutorialStep? { TutorialStep(rawValue: rawValue + 1) }

    /// Static frame key for non-pad steps; pad steps use "pad_{position}" dynamically
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

    private(set) var targetPadPositions: [Constants.SoundCategory: Int] = [:]
    var frames: [String: CGRect] = [:]

    private let tutorialShownKey = "tutorialHasBeenShown"

    /// True after `start()` has been called at least once (persisted in UserDefaults)
    var hasBeenShown: Bool {
        UserDefaults.standard.bool(forKey: tutorialShownKey)
    }

    // MARK: Public API

    func start(sounds: [Sound]) {
        guard !isActive else { return }
        targetPadPositions = [:]
        for category in [Constants.SoundCategory.base, .rhythm, .melody, .percussion, .voice] {
            let pads = sounds.filter { $0.category == category }
            if let pick = pads.randomElement() {
                targetPadPositions[category] = pick.position
            }
        }
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

    /// Returns the screen-space CGRect for the current tutorial target, or nil if not yet available
    func currentTargetFrame() -> CGRect? {
        if let key = step.frameKey {
            return frames[key]
        }
        if let category = step.targetCategory,
           let position = targetPadPositions[category] {
            return frames["pad_\(position)"]
        }
        return nil
    }

    /// Call on every pad tap — advances when the correct pad is tapped
    func handlePadTap(_ sound: Sound) {
        guard isActive,
              let category = step.targetCategory,
              sound.category == category,
              let targetPos = targetPadPositions[category],
              sound.position == targetPos
        else { return }
        advance()
    }
}
