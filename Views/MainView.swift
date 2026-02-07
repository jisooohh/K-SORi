import SwiftUI

struct MainView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var beatEngine = BeatEngine(bpm: 120.0)
    @StateObject private var audioPlayerManager = AudioPlayerManager()
    @StateObject private var hapticManager = HapticManager()
    @StateObject private var recordingManager = RecordingManager()

    @State private var activePads: Set<Int> = []
    @State private var pendingPads: Set<Int> = []

    var body: some View {
        ZStack {
            // Dark Giwa pattern background
            GugakDesign.Colors.darkNight
                .ignoresSafeArea()

            // Optional: Background pattern image
            // Image("bg_pattern")
            //     .resizable()
            //     .scaledToFill()
            //     .ignoresSafeArea()
            //     .opacity(0.2)

            VStack(spacing: GugakDesign.Spacing.md) {
                // Top Control Bar
                topControlBar
                    .padding(.horizontal, GugakDesign.Spacing.md)
                    .padding(.top, GugakDesign.Spacing.md)

                // AI Wave Analysis Visualizer
                visualizerSection
                    .padding(.horizontal, GugakDesign.Spacing.md)

                // MIDI Pad Grid (5x5)
                GiwaPadGrid(
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
            // Connect BeatEngine to AudioPlayerManager
            audioPlayerManager.setBeatEngine(beatEngine)

            // Start BeatEngine for quantization
            if !beatEngine.isRunning {
                beatEngine.start()
            }
        }
    }

    // MARK: - Top Control Bar

    private var topControlBar: some View {
        HStack(spacing: GugakDesign.Spacing.md) {
            // Info Button (설명)
            Button(action: {
                appState.navigateTo(.intro)
            }) {
                Image(systemName: "info.circle")
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.1))
                    )
            }

            // File Button
            Button(action: {
                appState.navigateTo(.musicList)
            }) {
                Text("File")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.1))
                    )
            }

            Spacer()

            // Transport Controls
            HStack(spacing: 12) {
                // Record Button (with glow effect when recording)
                Button(action: toggleRecording) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(
                            color: recordingManager.isRecording ? Color.red.opacity(0.8) : .clear,
                            radius: recordingManager.isRecording ? 12 : 0
                        )
                        .opacity(recordingManager.isRecording ? 1.0 : 0.6)
                }

                // Stop Button
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

            // Timer
            Text(formatDuration(recordingManager.isRecording ? recordingManager.recordingDuration : 0))
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                )
        }
        .padding(GugakDesign.Spacing.md)
        .glassmorphism()
    }

    // MARK: - Visualizer Section

    private var visualizerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("AI Wave Analysis")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.5))
                .padding(.leading, 4)

            WaveVisualizationView(
                amplitudes: audioPlayerManager.currentAmplitudes,
                frequencyBands: audioPlayerManager.frequencyBands,
                globalAmplitude: audioPlayerManager.globalAmplitude
            )
            .frame(height: 120)
            .padding(GugakDesign.Spacing.md)
            .glassmorphism()
        }
    }

    // MARK: - Actions

    private func handlePadTapped(_ sound: Sound) {
        // Quantized toggle: waits for next beat before starting
        audioPlayerManager.toggleSoundQuantized(sound)
        hapticManager.playHaptic(for: sound.category)

        // Update pad states
        if audioPlayerManager.isPlaying(at: sound.position) {
            // Already playing - will stop immediately
            activePads.remove(sound.position)
            pendingPads.remove(sound.position)
        } else if audioPlayerManager.isPending(at: sound.position) {
            // Waiting for quantization
            pendingPads.insert(sound.position)
        } else {
            // Check after a short delay if it started playing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if audioPlayerManager.isPlaying(at: sound.position) {
                    activePads.insert(sound.position)
                    pendingPads.remove(sound.position)
                }
            }
        }
    }

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

    private func stopAll() {
        // Stop recording if active
        if recordingManager.isRecording {
            if let music = recordingManager.stopRecording() {
                appState.addRecordedMusic(music)
            }
        }

        // Stop all pad sounds
        audioPlayerManager.stopAllSounds()
        activePads.removeAll()
        pendingPads.removeAll()
        hapticManager.playSimpleHaptic()
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

// MARK: - Giwa Pad Grid

struct GiwaPadGrid: View {
    let sounds: [Sound]
    @Binding var activePads: Set<Int>
    @Binding var pendingPads: Set<Int>
    let onPadTapped: (Sound) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(sounds) { sound in
                GiwaPadButton(
                    sound: sound,
                    isActive: activePads.contains(sound.position),
                    isPending: pendingPads.contains(sound.position),
                    onTap: {
                        onPadTapped(sound)
                    }
                )
            }
        }
    }
}

// MARK: - Giwa Pad Button

struct GiwaPadButton: View {
    let sound: Sound
    let isActive: Bool
    let isPending: Bool
    let onTap: () -> Void

    @State private var pulseAnimation: Bool = false

    // Obangsaek color for this button (based on position)
    private var buttonColor: Color {
        GugakDesign.Colors.randomObangsaek(seed: sound.position)
    }

    // Traditional pattern icon (simplified)
    private var patternIcon: String {
        let patterns = ["leaf.fill", "cloud.fill", "circle.grid.cross.fill", "square.grid.2x2.fill"]
        return patterns[sound.position % patterns.count]
    }

    var body: some View {
        GeometryReader { geometry in
            Button(action: onTap) {
                ZStack {
                    // Engraved pattern
                    Image(systemName: patternIcon)
                        .font(.system(size: 20))
                        .foregroundColor(
                            buttonColor == GugakDesign.Colors.obangsaekWhite
                                ? .black.opacity(0.15)
                                : .white.opacity(0.15)
                        )

                    // Pending indicator (pulsing ring)
                    if isPending {
                        Circle()
                            .stroke(Color.yellow, lineWidth: 3)
                            .scaleEffect(pulseAnimation ? 1.1 : 0.9)
                            .opacity(pulseAnimation ? 0.3 : 0.8)
                    }
                }
            }
            .buttonStyle(GiwaButtonStyle(color: buttonColor, isActive: isActive))
            .frame(width: geometry.size.width, height: geometry.size.width)
        }
        .aspectRatio(1, contentMode: .fit)
        .onAppear {
            if isPending {
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    pulseAnimation = true
                }
            }
        }
        .onChange(of: isPending) { newValue in
            if newValue {
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    pulseAnimation = true
                }
            } else {
                pulseAnimation = false
            }
        }
    }
}
