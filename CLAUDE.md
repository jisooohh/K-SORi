# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**KSORi** is a Korean traditional music sound pad app built as a Swift Playground (`.swiftpm`). It is developed in **Swift Playgrounds on iPad** and targets iOS 18.1+. There is no Xcode project file — `Package.swift` is auto-generated and should not be manually edited.

## Build & Run

This project runs exclusively in **Swift Playgrounds** on iPad or the Swift Playgrounds Mac app. There are no terminal build commands. To test:
1. Open `KSORi.swiftpm` in Swift Playgrounds
2. Press the Run button

If sounds are not found at runtime, clean derived data from Swift Playgrounds settings (see `REBUILD_INSTRUCTIONS.md`).

## Architecture

### Screen Flow
```
IntroView → MainView → MusicListView
```
Routing is managed by `AppState.currentScreen: AppScreen` (enum). `ContentView` switches views based on this. `MusicListView` is presented as a sheet/navigation push from `MainView`.

### Key State Objects
- **`AppState`** (`@EnvironmentObject`) — global state: current screen, sound pad configuration, recorded music list. Persists to `UserDefaults`.
- **`TutorialManager`** (`@EnvironmentObject`) — tutorial step tracking, target frame collection via `TutorialFrameKey: PreferenceKey`. `frames` must be `@Published` so `TutorialOverlayView` re-renders when frames arrive after screen transitions.

### Audio System
Two audio managers exist; only `AudioPlayerManager` is active for pad playback:

| Class | Role | Status |
|---|---|---|
| `AudioPlayerManager` | Pad sound playback (quantized, looping/one-shot) | **Active** |
| `AudioEngineManager` | Singleton `AVAudioEngine` shared across the app | **Active** |
| `BeatEngine` | BPM clock, schedules callbacks on next beat | **Active** |
| `AudioManager` | Legacy `AVAudioPlayer`-based manager | **Unused** |

**Playback flow:** `handlePadTapped` → `AudioPlayerManager.toggleSoundQuantized` → `BeatEngine.scheduleOnNextBeat` → `AVAudioPlayerNode` schedules buffer on `AVAudioEngine`.

**Voice (V) category** is special: plays once via `playSoundOnce()` (no `.loops` flag), auto-deactivates via `DispatchQueue.main.asyncAfter(deadline: .now() + duration)`.

**Volume overrides:**
- Rhythm (R): `node.volume = 1.5`
- Voice (V): `node.volume = 2.0`
- All others: `node.volume = 1.0`

### Sound Pad Layout (5×5 grid, 25 pads)
```
Row 0: M1  M2  M3  M4  M5   ← Melody / 해금
Row 1: P1  P2  P3  P4  P5   ← Percussion / 소리북
Row 2: R1  R2  R3  R4  R5   ← Rhythm / 장구
Row 3: V1  V2  M6  V3  V4   ← Voice / 부채 (M6 borrowed at col 2)
Row 4: B1  B2  B3  B4  R6   ← Base / 거문고 (R6 borrowed at col 4)
```
Sound definitions live in `SoundPad.createDefaultSounds()`. Category colors and metadata are in `Constants.SoundCategory`.

### Pad Tap State Machine (MainView)
- `activePads: Set<Int>` — currently looping
- `pendingPads: Set<Int>` — scheduled but not yet confirmed playing
- `pendingStopPads: Set<Int>` — queued to stop on next beat boundary
- `pollForActivation()` polls `isPlaying(at:)` every 0.25s (up to 8 attempts) to confirm playback started

### Resource Loading
Audio files are WAV in `Resources/` (named `M1.wav`, `R3.wav`, etc.). `AudioPlayerManager.playSound` tries 3 fallback paths (Resources subdirectory → Bundle.main direct → file path search) because Swift Playgrounds bundle structure varies.

### Tutorial System
- `TutorialManager.frames: [String: CGRect]` collects button frames via SwiftUI `PreferenceKey`
- `TutorialOverlayView` draws a cutout highlight + speech bubble over the target frame
- A UIKit `TutorialBlocker: UIView` absorbs touches outside the highlighted area
- Tutorial step advances via `TutorialManager.handlePadTap(_:)` and `advance()`

### Recording
`RecordingManager` installs an `AVAudioEngine` output tap on `mainMixer` to capture all pad audio. Output is saved as `.caf` in the app's Documents directory. Recordings are stored in `AppState.recordedMusics` and persisted via `UserDefaults` (Codable).

## Important Patterns & Constraints

- **No asset catalog** — all images and audio are in `Resources/` folder, loaded via `Bundle.main.url(forResource:withExtension:)` with fallbacks.
- **Image processing** — `InstrumentImage` view uses a static cache and `UIImage.removingWhiteBackground()` (flood fill from edges stopping at dark pixels, threshold 0.18) to clean up instrument PNGs.
- **`@Published` requirement** — any `ObservableObject` property that drives view updates from async callbacks (e.g., `TutorialManager.frames`) must be `@Published`.
- **`confirmationDialog` placement** — must be attached directly to the triggering `Button`, not to an ancestor `ZStack` or `List`, or it will be intercepted.
- **IntroView centering** — uses `GeometryReader` + `frame(minHeight: geo.size.height)` on the inner VStack to center content consistently across device sizes.
- **Swift Playgrounds compiler limits** — avoid large `@ViewBuilder` closures and complex type inference chains; the playground compiler can timeout on them.
