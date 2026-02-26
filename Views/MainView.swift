import SwiftUI
import UIKit
import AVFoundation

// MARK: - Last Recording Player

@MainActor
final class LastRecordingPlayer: NSObject, ObservableObject {
    @Published var music: RecordedMusic?
    @Published var isPlaying: Bool = false
    @Published var remainingTime: TimeInterval = 0

    private var player: AVAudioPlayer?
    private var countdownTimer: Timer?

    func setMusic(_ newMusic: RecordedMusic) {
        stop()
        music = newMusic
        remainingTime = newMusic.duration
    }

    func toggle() {
        isPlaying ? pause() : play()
    }

    func play() {
        guard let music = music else { return }
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(music.fileName)

        do {
            if player == nil {
                let p = try AVAudioPlayer(contentsOf: url)
                p.delegate = self
                p.prepareToPlay()
                player = p
            }
            player?.play()
            isPlaying = true
            startCountdown()
        } catch {
            print("❌ LastRecordingPlayer play: \(error)")
        }
    }

    func pause() {
        if let player {
            remainingTime = max(0, player.duration - player.currentTime)
            player.pause()
        }
        isPlaying = false
        stopCountdown()
    }

    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
        stopCountdown()
        remainingTime = music?.duration ?? 0
    }

    private func startCountdown() {
        stopCountdown()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, let player = self.player, player.isPlaying else { return }
                self.remainingTime = max(0, player.duration - player.currentTime)
            }
        }
    }

    private func stopCountdown() {
        countdownTimer?.invalidate()
        countdownTimer = nil
    }

    fileprivate func handlePlaybackFinished() {
        isPlaying = false
        stopCountdown()
        player = nil
        remainingTime = music?.duration ?? 0
    }
}

extension LastRecordingPlayer: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.handlePlaybackFinished()
        }
    }
}

// MARK: - Main View

struct MainView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var tutorialManager: TutorialManager
    @StateObject private var beatEngine          = BeatEngine(bpm: 120.0)
    @StateObject private var audioPlayerManager  = AudioPlayerManager()
    @StateObject private var hapticManager       = HapticManager()
    @StateObject private var recordingManager    = RecordingManager()
    @StateObject private var lastRecordingPlayer = LastRecordingPlayer()

    @State private var activePads:      Set<Int> = []
    @State private var pendingPads:     Set<Int> = []
    @State private var pendingStopPads: Set<Int> = []

    @Environment(\.horizontalSizeClass) private var hSizeClass
    private var isCompact: Bool { hSizeClass == .compact }

    private var categoryActiveCounts: [Constants.SoundCategory: Int] {
        var counts: [Constants.SoundCategory: Int] = [:]
        for position in activePads {
            if let sound = appState.soundPad.sounds.first(where: { $0.position == position }) {
                counts[sound.category, default: 0] += 1
            }
        }
        return counts
    }

    var body: some View {
        ZStack {
            GugakDesign.Colors.darkNight.ignoresSafeArea()

            VStack(spacing: isCompact ? GugakDesign.Spacing.sm : GugakDesign.Spacing.md) {
                topControlBar
                    .padding(.horizontal, GugakDesign.Spacing.md)
                    .padding(.top, isCompact ? GugakDesign.Spacing.sm : GugakDesign.Spacing.md)

                InstrumentDisplayView(categoryActiveCounts: categoryActiveCounts)
                    .padding(.horizontal, GugakDesign.Spacing.md)

                KSORiPadGrid(
                    sounds: appState.soundPad.sounds,
                    activePads: $activePads,
                    pendingPads: $pendingPads,
                    onPadTapped: handlePadTapped
                )
                .padding(.horizontal, isCompact ? GugakDesign.Spacing.md : GugakDesign.Spacing.sm)

                Spacer(minLength: GugakDesign.Spacing.sm)
            }
        }
        .onAppear {
            audioPlayerManager.setBeatEngine(beatEngine)
            if !beatEngine.isRunning { beatEngine.start() }
            if !tutorialManager.hasBeenShown {
                Task {
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    tutorialManager.start(sounds: appState.soundPad.sounds)
                }
            }
        }
        .onReceive(recordingManager.$lastSavedMusic) { music in
            if let music = music {
                lastRecordingPlayer.setMusic(music)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .appStopAllAudio)) { _ in
            stopAllForNavigation()
        }
    }

    // MARK: - Top Control Bar

    private var timerValue: TimeInterval {
        if recordingManager.isRecording {
            return recordingManager.recordingDuration
        } else if lastRecordingPlayer.music != nil {
            return lastRecordingPlayer.remainingTime
        } else {
            return 0
        }
    }

    private var timerColor: Color {
        if recordingManager.isRecording {
            return Color.red.opacity(0.9)
        } else if lastRecordingPlayer.isPlaying {
            return Color.green.opacity(0.9)
        } else {
            return Color.white.opacity(0.8)
        }
    }

    private var showPlayButton: Bool {
        lastRecordingPlayer.music != nil && !recordingManager.isRecording
    }

    private var topControlBar: some View {
        HStack(spacing: GugakDesign.Spacing.md) {
            Button(action: { appState.navigateTo(.intro) }) {
                Image(systemName: "info.circle")
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.white.opacity(0.1)))
            }

            Button(action: {
                appState.navigateTo(.musicList)
                if tutorialManager.isActive && tutorialManager.step == .fileButton {
                    tutorialManager.advance()
                }
            }) {
                Text("File")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.1)))
            }
            .tutorialFrame("file")

            Spacer()

            HStack(spacing: 12) {
                // Record button
                Button(action: toggleRecording) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 32, height: 32)
                        .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
                        .shadow(
                            color: recordingManager.isRecording ? Color.red.opacity(0.8) : .clear,
                            radius: recordingManager.isRecording ? 12 : 0
                        )
                        .opacity(recordingManager.isRecording ? 1.0 : 0.6)
                }
                .tutorialFrame("record")

                // Stop button
                Button(action: stopAll) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.6))
                        .frame(width: 28, height: 28)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                }
                .tutorialFrame("stop")

                // Play button — appears after a recording is saved
                if showPlayButton {
                    Button(action: { lastRecordingPlayer.toggle() }) {
                        Image(systemName: lastRecordingPlayer.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(Color(red: 0.09, green: 0.45, blue: 0.21))
                            .frame(width: 32, height: 32)
                    }
                    .transition(.scale(scale: 0.5).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showPlayButton)

            Spacer()

            Text(formatDuration(timerValue))
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(timerColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.1)))
                .animation(.easeInOut(duration: 0.2), value: timerColor == Color.green.opacity(0.9))
        }
        .padding(isCompact ? GugakDesign.Spacing.sm : GugakDesign.Spacing.md)
        .glassmorphism()
    }

    // MARK: - Pad Tap Handler

    private func handlePadTapped(_ sound: Sound) {
        let pos = sound.position

        // V (Voice): 1회 재생, 재탭 시 즉시 정지, 재생 종료 시 자동 비활성화
        if sound.category == .voice {
            if activePads.contains(pos) || pendingPads.contains(pos) {
                audioPlayerManager.stopSound(at: pos)
                activePads.remove(pos)
                pendingPads.remove(pos)
            } else {
                let duration = audioPlayerManager.playSoundOnce(sound)
                hapticManager.playHaptic(for: sound.category)
                pendingPads.insert(pos)
                pollForActivation(sound)
                tutorialManager.handlePadTap(sound)
                if duration > 0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                        audioPlayerManager.stopSound(at: pos)
                        activePads.remove(pos)
                    }
                }
            }
            return
        }

        if pendingStopPads.contains(pos) {
            pendingStopPads.remove(pos)

        } else if activePads.contains(pos) {
            pendingStopPads.insert(pos)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                guard pendingStopPads.contains(pos) else { return }
                audioPlayerManager.stopSound(at: pos)
                activePads.remove(pos)
                pendingStopPads.remove(pos)
            }

        } else if pendingPads.contains(pos) {
            audioPlayerManager.stopSound(at: pos)
            pendingPads.remove(pos)

        } else {
            audioPlayerManager.toggleSoundQuantized(sound)
            hapticManager.playHaptic(for: sound.category)
            pendingPads.insert(pos)
            pollForActivation(sound)
            tutorialManager.handlePadTap(sound)
        }
    }

    private func pollForActivation(_ sound: Sound, attempt: Int = 0) {
        guard attempt < 8 else { pendingPads.remove(sound.position); return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            if audioPlayerManager.isPlaying(at: sound.position) {
                activePads.insert(sound.position)
                pendingPads.remove(sound.position)
            } else if pendingPads.contains(sound.position) {
                pollForActivation(sound, attempt: attempt + 1)
            }
        }
    }

    private func toggleRecording() {
        if recordingManager.isRecording {
            if let music = recordingManager.stopRecording() { appState.addRecordedMusic(music) }
        } else {
            lastRecordingPlayer.stop()
            _ = recordingManager.startRecording()
            if tutorialManager.isActive && tutorialManager.step == .recordButton {
                tutorialManager.advance()
            }
        }
        hapticManager.playSimpleHaptic()
    }

    private func stopAll() {
        if recordingManager.isRecording {
            if let music = recordingManager.stopRecording() { appState.addRecordedMusic(music) }
        }
        audioPlayerManager.stopAllSounds()
        activePads.removeAll()
        pendingPads.removeAll()
        pendingStopPads.removeAll()
        hapticManager.playSimpleHaptic()
        if tutorialManager.isActive && tutorialManager.step == .stopButton {
            tutorialManager.advance()
        }
    }

    private func stopAllForNavigation() {
        if recordingManager.isRecording {
            if let music = recordingManager.stopRecording() { appState.addRecordedMusic(music) }
        }
        audioPlayerManager.stopAllSounds()
        activePads.removeAll()
        pendingPads.removeAll()
        pendingStopPads.removeAll()
        lastRecordingPlayer.stop()
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        String(format: "%02d:%02d:%02d", Int(duration)/3600, (Int(duration)%3600)/60, Int(duration)%60)
    }
}

// MARK: - Bundle Image Loader

/// Resources 폴더에서 PNG를 안정적으로 로드하는 헬퍼 뷰 (흰 배경 자동 제거)
struct InstrumentImage: View {
    let name: String

    private static var imageCache: [String: UIImage] = [:]

    private var uiImage: UIImage? {
        if let cached = InstrumentImage.imageCache[name] { return cached }
        let processed = loadRaw()?.removingWhiteBackground()
        InstrumentImage.imageCache[name] = processed
        return processed
    }

    private func loadRaw() -> UIImage? {
        if let img = UIImage(named: name) { return img }
        if let url = Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "Resources"),
           let img = UIImage(contentsOfFile: url.path) { return img }
        if let url = Bundle.main.url(forResource: name, withExtension: "png"),
           let img = UIImage(contentsOfFile: url.path) { return img }
        if let base = Bundle.main.resourcePath {
            for suffix in ["Resources/\(name).png", "\(name).png"] {
                let path = (base as NSString).appendingPathComponent(suffix)
                if let img = UIImage(contentsOfFile: path) { return img }
            }
        }
        return nil
    }

    var body: some View {
        if let img = uiImage {
            Image(uiImage: img).resizable()
        } else {
            Image(systemName: "music.note").resizable()
        }
    }
}

// MARK: - UIImage White Background Removal

extension UIImage {
    /// 경계에서 flood fill: 어두운 픽셀(악기 아웃라인)이 나타나기 직전까지 모든 픽셀 제거
    func removingWhiteBackground() -> UIImage {
        guard let cgImage = self.cgImage else { return self }
        let W = cgImage.width, H = cgImage.height
        let bpr = 4 * W
        var px = [UInt8](repeating: 0, count: H * bpr)
        guard let ctx = CGContext(
            data: &px, width: W, height: H,
            bitsPerComponent: 8, bytesPerRow: bpr,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return self }
        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: W, height: H))

        // max(R,G,B) < 0.18 → 어두운 픽셀 = 악기 아웃라인 → flood fill 중단
        func isDark(_ i: Int) -> Bool {
            let p = i * 4
            let r = Float(px[p]) / 255
            let g = Float(px[p+1]) / 255
            let b = Float(px[p+2]) / 255
            return max(r, max(g, b)) < 0.18
        }

        // 4변 경계에서 flood fill: 어둡지 않으면 제거, 어두우면 중단
        var toRemove = [Bool](repeating: false, count: W * H)
        var visited  = [Bool](repeating: false, count: W * H)
        var stack    = [Int]()
        stack.reserveCapacity(W * 2 + H * 2)

        for x in 0..<W {
            stack.append(x)
            stack.append((H - 1) * W + x)
        }
        for y in 0..<H {
            stack.append(y * W)
            stack.append(y * W + W - 1)
        }

        while let idx = stack.popLast() {
            if visited[idx] { continue }
            visited[idx] = true
            if isDark(idx) { continue }   // 어두운 픽셀 = 아웃라인 → 중단, 보존
            toRemove[idx] = true
            let x = idx % W, y = idx / W
            if x > 0   { stack.append(idx - 1) }
            if x < W-1 { stack.append(idx + 1) }
            if y > 0   { stack.append(idx - W) }
            if y < H-1 { stack.append(idx + W) }
        }

        // 제거 대상 픽셀 → 완전 투명
        for idx in 0..<(W * H) where toRemove[idx] {
            px[idx * 4 + 3] = 0
        }

        guard let newCG = ctx.makeImage() else { return self }
        return UIImage(cgImage: newCG, scale: scale, orientation: imageOrientation)
    }
}

// MARK: - Instrument Display

struct InstrumentDisplayView: View {
    let categoryActiveCounts: [Constants.SoundCategory: Int]

    private let orderedCategories: [Constants.SoundCategory] = [
        .melody, .percussion, .rhythm, .voice, .base
    ]

    @Environment(\.horizontalSizeClass) private var hSizeClass
    private var isCompact: Bool { hSizeClass == .compact }
    private var displayHeight: CGFloat { isCompact ? 100 : 180 }

    var body: some View {
        HStack(spacing: 6) {
            ForEach(orderedCategories, id: \.self) { category in
                InstrumentColumn(
                    category: category,
                    activeCount: categoryActiveCounts[category] ?? 0
                )
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: displayHeight)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .glassmorphism()
    }
}

struct InstrumentColumn: View {
    let category: Constants.SoundCategory
    let activeCount: Int

    @Environment(\.horizontalSizeClass) private var hSizeClass
    private var isCompact: Bool { hSizeClass == .compact }
    private var containerH: CGFloat     { isCompact ? 90 : 162 }
    private var instrumentH: CGFloat    { isCompact ? 85 : 155 }
    private var inactiveOffset: CGFloat { isCompact ? 18 : 35 }

    private var level: Int    { min(activeCount, 6) }
    private var isActive: Bool { activeCount > 0 }

    // level 0 = nearly natural (-0.05 brightness, 0.65 saturation)
    // level 6 = bright glow   (+0.70 brightness, 1.25 saturation)
    private var brightnessAdj: Double { Double(level) * 0.125 - 0.05 }
    private var saturationAdj: Double { 0.65 + Double(level) * 0.1 }
    private var glowRadius: CGFloat   { level >= 4 ? CGFloat(level - 3) * 6 : 0 }

    var body: some View {
        ZStack {
            InstrumentImage(name: category.instrumentImageName)
                .scaledToFit()
                .frame(height: instrumentH)
                .brightness(brightnessAdj)
                .saturation(saturationAdj)
                .shadow(
                    color: level >= 4 ? Color.white.opacity(0.75) : .clear,
                    radius: glowRadius
                )
                .offset(y: isActive ? 0 : inactiveOffset)
                .animation(.spring(response: 0.45, dampingFraction: 0.72), value: isActive)
                .animation(.easeInOut(duration: 0.2), value: level)
        }
        .frame(maxWidth: .infinity)
        .frame(height: containerH)
        .clipped()
    }
}

// MARK: - KSORi Pad Grid

struct KSORiPadGrid: View {
    let sounds: [Sound]
    @Binding var activePads:  Set<Int>
    @Binding var pendingPads: Set<Int>
    let onPadTapped: (Sound) -> Void
    @EnvironmentObject var tutorialManager: TutorialManager

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(sounds) { sound in
                KSORiPadButton(
                    sound: sound,
                    isActive:  activePads.contains(sound.position),
                    isPending: pendingPads.contains(sound.position),
                    onTap: { onPadTapped(sound) }
                )
                .tutorialFrame("pad_\(sound.position)")
            }
        }
    }
}

// MARK: - KSORi Pad Button

struct KSORiPadButton: View {
    let sound: Sound
    let isActive:  Bool
    let isPending: Bool
    let onTap: () -> Void

    @State private var pulseAnimation = false

    private var categoryColor: Color { sound.category.color }

    private var activeDisplayColor: Color {
        sound.category == .base
            ? Color(red: 0.42, green: 0.42, blue: 0.46)
            : categoryColor
    }

    var body: some View {
        GeometryReader { geo in
            let size = geo.size.width

            Button(action: onTap) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isActive
                              ? activeDisplayColor.opacity(0.88)
                              : categoryColor.opacity(0.30))

                    if isActive {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(activeDisplayColor.opacity(0.50))
                            .blur(radius: 12)
                            .scaleEffect(1.10)
                    }

                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            activeDisplayColor.opacity(isActive ? 0.90 : 0.38),
                            lineWidth: isActive ? 2 : 1
                        )

                    InstrumentImage(name: sound.category.instrumentImageName)
                        .scaledToFit()
                        .frame(width: size * 0.78, height: size * 0.78)
                        .brightness(isActive ? 0.12 : -0.18)
                        .saturation(isActive ? 1.25 : 0.55)
                        .shadow(
                            color: isActive ? activeDisplayColor.opacity(0.85) : .clear,
                            radius: isActive ? 10 : 0
                        )

                    if isPending {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.yellow.opacity(0.9), lineWidth: 2.5)
                            .scaleEffect(pulseAnimation ? 1.05 : 0.96)
                            .opacity(pulseAnimation ? 0.45 : 1.0)
                    }
                }
            }
            .buttonStyle(KSORiButtonStyle())
            .frame(width: size, height: size)
        }
        .aspectRatio(1, contentMode: .fit)
        .onAppear { if isPending { startPulse() } }
        .onChange(of: isPending) { newVal in
            if newVal { startPulse() } else { pulseAnimation = false }
        }
    }

    private func startPulse() {
        withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) {
            pulseAnimation = true
        }
    }
}

struct KSORiButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
