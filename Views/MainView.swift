import SwiftUI

struct MainView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var beatEngine      = BeatEngine(bpm: 120.0)
    @StateObject private var audioPlayerManager = AudioPlayerManager()
    @StateObject private var hapticManager   = HapticManager()
    @StateObject private var recordingManager = RecordingManager()

    // 현재 재생 중인 패드
    @State private var activePads: Set<Int> = []
    // 퀀타이즈 대기 중인 패드
    @State private var pendingPads: Set<Int> = []
    // 0.5초 딜레이 후 정지 예약된 패드
    @State private var pendingStopPads: Set<Int> = []

    // 카테고리별 활성 버튼 수 (디스플레이 밝기 계산용)
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

                // 악기 디스플레이 (Wave Visualizer 대체)
                InstrumentDisplayView(categoryActiveCounts: categoryActiveCounts)
                    .padding(.horizontal, GugakDesign.Spacing.md)

                // 패드 그리드
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
            // 정지 예약 취소 → 계속 재생
            pendingStopPads.remove(pos)

        } else if activePads.contains(pos) {
            // 두 번째 클릭 → 0.5초 후 정지
            pendingStopPads.insert(pos)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                guard pendingStopPads.contains(pos) else { return }
                audioPlayerManager.stopSound(at: pos)
                activePads.remove(pos)
                pendingStopPads.remove(pos)
            }

        } else if pendingPads.contains(pos) {
            // 퀀타이즈 대기 중 재탭 → 시작 취소
            audioPlayerManager.stopSound(at: pos)
            pendingPads.remove(pos)

        } else {
            // 첫 번째 클릭 → 소리 시작
            audioPlayerManager.toggleSoundQuantized(sound)
            hapticManager.playHaptic(for: sound.category)
            pendingPads.insert(pos)
            pollForActivation(sound)
        }
    }

    // 퀀타이즈 시작 후 재생 여부 확인 (최대 8회 폴링)
    private func pollForActivation(_ sound: Sound, attempt: Int = 0) {
        guard attempt < 8 else {
            pendingPads.remove(sound.position)
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            if audioPlayerManager.isPlaying(at: sound.position) {
                activePads.insert(sound.position)
                pendingPads.remove(sound.position)
            } else if pendingPads.contains(sound.position) {
                pollForActivation(sound, attempt: attempt + 1)
            }
        }
    }

    // MARK: - Recording

    private func toggleRecording() {
        if recordingManager.isRecording {
            if let music = recordingManager.stopRecording() {
                appState.addRecordedMusic(music)
            }
        } else {
            _ = recordingManager.startRecording()
        }
        hapticManager.playSimpleHaptic()
    }

    // MARK: - Stop All

    private func stopAll() {
        if recordingManager.isRecording {
            if let music = recordingManager.stopRecording() {
                appState.addRecordedMusic(music)
            }
        }
        audioPlayerManager.stopAllSounds()
        activePads.removeAll()
        pendingPads.removeAll()
        pendingStopPads.removeAll()
        hapticManager.playSimpleHaptic()
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let h = Int(duration) / 3600
        let m = (Int(duration) % 3600) / 60
        let s = Int(duration) % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
}

// MARK: - Instrument Display

/// 5가지 악기 이미지 행
/// - 초기 상태: 악기 하단 20%가 클리핑으로 숨겨짐 (어두운 노란색)
/// - 버튼 클릭 시: 해당 악기가 중앙으로 상승 + 밝기 증가 (최대 6단계 → white + glow)
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
        .frame(height: 130)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .glassmorphism()
    }
}

struct InstrumentColumn: View {
    let category: Constants.SoundCategory
    let activeCount: Int

    // 컨테이너: 110pt / 악기 VStack: 72pt
    // 비활성 시 → offset +34 → 하단 ~20%가 클리핑됨
    // 활성 시  → offset  0  → 중앙 배치
    private let containerH: CGFloat = 110
    private let instrumentH: CGFloat = 72
    private let inactiveOffset: CGFloat = 34

    private var level: Int { min(activeCount, 6) }
    private var isActive: Bool { activeCount > 0 }

    // 어두운 노란색(level 0) → 흰색(level 6) 보간
    private var instrumentColor: Color {
        let t = Double(level) / 6.0
        return Color(
            red:   0.55 + 0.45 * t,
            green: 0.40 + 0.60 * t,
            blue:  0.05 + 0.95 * t
        )
    }

    private var glowRadius: CGFloat {
        level >= 4 ? CGFloat(level - 3) * 5 : 0
    }

    var body: some View {
        ZStack {
            VStack(spacing: 4) {
                Image(systemName: category.instrumentSymbol)
                    .font(.system(size: 40, weight: .regular))
                    .foregroundStyle(instrumentColor)
                    .shadow(
                        color: level >= 4 ? instrumentColor.opacity(0.9) : .clear,
                        radius: glowRadius
                    )

                Text(category.instrumentName)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(instrumentColor.opacity(0.9))
            }
            .frame(height: instrumentH)
            .offset(y: isActive ? 0 : inactiveOffset)
            .animation(.spring(response: 0.45, dampingFraction: 0.72), value: isActive)
            .animation(.easeInOut(duration: 0.25), value: level)
        }
        .frame(maxWidth: .infinity)
        .frame(height: containerH)
        .clipped()
    }
}

// MARK: - KSORi Pad Grid

struct KSORiPadGrid: View {
    let sounds: [Sound]
    @Binding var activePads: Set<Int>
    @Binding var pendingPads: Set<Int>
    let onPadTapped: (Sound) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(sounds) { sound in
                KSORiPadButton(
                    sound: sound,
                    isActive: activePads.contains(sound.position),
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
    let isActive: Bool
    let isPending: Bool
    let onTap: () -> Void

    @State private var pulseAnimation = false

    private var categoryColor: Color { sound.category.color }

    // 흰색(voice) 버튼은 아이콘을 검정으로
    private var iconColor: Color {
        sound.category == .voice
            ? Color.black.opacity(isActive ? 0.85 : 0.55)
            : Color.white.opacity(isActive ? 1.0 : 0.65)
    }

    var body: some View {
        GeometryReader { geo in
            Button(action: onTap) {
                ZStack {
                    // 배경
                    RoundedRectangle(cornerRadius: 12)
                        .fill(categoryColor.opacity(isActive ? 0.9 : 0.35))

                    // 외부 글로우 (활성 시)
                    if isActive {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(categoryColor.opacity(0.45))
                            .blur(radius: 10)
                            .scaleEffect(1.08)
                    }

                    // 테두리
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            categoryColor.opacity(isActive ? 0.95 : 0.4),
                            lineWidth: isActive ? 2 : 1
                        )

                    // 악기 아이콘 (확대)
                    Image(systemName: sound.category.instrumentSymbol)
                        .font(.system(size: 30, weight: .regular))
                        .foregroundStyle(iconColor)
                        .shadow(
                            color: isActive ? categoryColor.opacity(0.7) : .clear,
                            radius: isActive ? 6 : 0
                        )

                    // 카테고리 레이블 (하단 소문자)
                    VStack {
                        Spacer()
                        Text(sound.category.categoryLetter)
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(iconColor.opacity(0.55))
                            .padding(.bottom, 4)
                    }

                    // 퀀타이즈 대기 링 (박자 동기화 대기 중)
                    if isPending {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.yellow.opacity(0.9), lineWidth: 2.5)
                            .scaleEffect(pulseAnimation ? 1.05 : 0.96)
                            .opacity(pulseAnimation ? 0.45 : 1.0)
                    }
                }
            }
            .buttonStyle(KSORiButtonStyle())
            .frame(width: geo.size.width, height: geo.size.width)
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
