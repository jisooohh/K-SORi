import SwiftUI
import UIKit

struct MainView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var beatEngine       = BeatEngine(bpm: 120.0)
    @StateObject private var audioPlayerManager = AudioPlayerManager()
    @StateObject private var hapticManager    = HapticManager()
    @StateObject private var recordingManager = RecordingManager()

    @State private var activePads:      Set<Int> = []
    @State private var pendingPads:     Set<Int> = []
    @State private var pendingStopPads: Set<Int> = []

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

            VStack(spacing: GugakDesign.Spacing.md) {
                topControlBar
                    .padding(.horizontal, GugakDesign.Spacing.md)
                    .padding(.top, GugakDesign.Spacing.md)

                InstrumentDisplayView(categoryActiveCounts: categoryActiveCounts)
                    .padding(.horizontal, GugakDesign.Spacing.md)

                KSORiPadGrid(
                    sounds: appState.soundPad.sounds,
                    activePads: $activePads,
                    pendingPads: $pendingPads,
                    onPadTapped: handlePadTapped
                )
                .padding(.horizontal, GugakDesign.Spacing.sm)

                Spacer(minLength: GugakDesign.Spacing.md)
            }
        }
        .onAppear {
            audioPlayerManager.setBeatEngine(beatEngine)
            if !beatEngine.isRunning { beatEngine.start() }
        }
    }

    // MARK: - Top Control Bar

    private var topControlBar: some View {
        HStack(spacing: GugakDesign.Spacing.md) {
            Button(action: { appState.navigateTo(.intro) }) {
                Image(systemName: "info.circle")
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.white.opacity(0.1)))
            }

            Button(action: { appState.navigateTo(.musicList) }) {
                Text("File")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.1)))
            }

            Spacer()

            HStack(spacing: 12) {
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

                Button(action: stopAll) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.6))
                        .frame(width: 28, height: 28)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                }
            }

            Spacer()

            Text(formatDuration(recordingManager.isRecording ? recordingManager.recordingDuration : 0))
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.1)))
        }
        .padding(GugakDesign.Spacing.md)
        .glassmorphism()
    }

    // MARK: - Pad Tap Handler

    private func handlePadTapped(_ sound: Sound) {
        let pos = sound.position

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
            _ = recordingManager.startRecording()
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
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        String(format: "%02d:%02d:%02d", Int(duration)/3600, (Int(duration)%3600)/60, Int(duration)%60)
    }
}

// MARK: - Bundle Image Loader

/// Resources 폴더에서 PNG를 안정적으로 로드하는 헬퍼 뷰
struct InstrumentImage: View {
    let name: String

    private var uiImage: UIImage? {
        // 방법 1: UIImage(named:)
        if let img = UIImage(named: name) { return img }

        // 방법 2: Bundle Resources 서브디렉토리
        if let url = Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "Resources"),
           let img = UIImage(contentsOfFile: url.path) { return img }

        // 방법 3: Bundle 직접
        if let url = Bundle.main.url(forResource: name, withExtension: "png"),
           let img = UIImage(contentsOfFile: url.path) { return img }

        // 방법 4: resourcePath 경로 순회
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

// MARK: - Instrument Display

/// 5가지 악기 이미지 행
/// - 비활성: 하단 ~20% 클리핑, 어두운 금색
/// - 활성: 중앙으로 상승 + 밝기/채도 증가 (6단계)
struct InstrumentDisplayView: View {
    let categoryActiveCounts: [Constants.SoundCategory: Int]

    private let orderedCategories: [Constants.SoundCategory] = [
        .melody, .percussion, .rhythm, .voice, .base
    ]

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
        .frame(height: 150)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .glassmorphism()
    }
}

struct InstrumentColumn: View {
    let category: Constants.SoundCategory
    let activeCount: Int

    // 컨테이너 128pt / 악기 이미지 90pt
    // 비활성: offset +37 → 하단 ~20% 클리핑
    // 활성:   offset  0  → 중앙 배치
    private let containerH: CGFloat    = 128
    private let instrumentH: CGFloat   = 90
    private let inactiveOffset: CGFloat = 37

    private var level: Int  { min(activeCount, 6) }
    private var isActive: Bool { activeCount > 0 }

    // level 0 = 어두운 금색(-0.3 brightness), level 6 = 밝은 흰빛(+0.45)
    private var brightnessAdj: Double { Double(level) * 0.125 - 0.3 }
    private var saturationAdj: Double { 0.25 + Double(level) * 0.125 }
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

    var body: some View {
        GeometryReader { geo in
            let size = geo.size.width

            Button(action: onTap) {
                ZStack {
                    // 배경
                    RoundedRectangle(cornerRadius: 12)
                        .fill(categoryColor.opacity(isActive ? 0.88 : 0.30))

                    // 외부 글로우 (활성 시)
                    if isActive {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(categoryColor.opacity(0.5))
                            .blur(radius: 10)
                            .scaleEffect(1.08)
                    }

                    // 테두리
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            categoryColor.opacity(isActive ? 0.95 : 0.38),
                            lineWidth: isActive ? 2 : 1
                        )

                    // 악기 실제 이미지
                    InstrumentImage(name: sound.category.instrumentImageName)
                        .scaledToFit()
                        .frame(width: size * 0.78, height: size * 0.78)
                        .brightness(isActive ? 0.12 : -0.18)
                        .saturation(isActive ? 1.25 : 0.55)
                        .shadow(
                            color: isActive ? categoryColor.opacity(0.85) : .clear,
                            radius: isActive ? 8 : 0
                        )

                    // 퀀타이즈 대기 링
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
