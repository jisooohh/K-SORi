import SwiftUI
import AVFoundation

struct MusicListView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var playbackManager = MusicPlaybackManager()

    var body: some View {
        ZStack {
            GugakDesign.Colors.darkNight
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerView
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 16)

                if appState.recordedMusics.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(appState.recordedMusics) { music in
                                MusicCard(
                                    music: music,
                                    isPlaying: playbackManager.currentlyPlaying?.id == music.id,
                                    currentTime: playbackManager.currentlyPlaying?.id == music.id ? playbackManager.currentTime : 0,
                                    onTogglePlay: {
                                        if playbackManager.currentlyPlaying?.id == music.id {
                                            playbackManager.stop()
                                        } else {
                                            playbackManager.play(music)
                                        }
                                    },
                                    onDelete: { deleteMusic(music) }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
    }

    private var headerView: some View {
        HStack {
            Button(action: {
                playbackManager.stop()
                appState.navigateTo(.main)
            }) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
            }

            Text("Recorded Music")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            Spacer()

            Text("\(appState.recordedMusics.count) tracks")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "music.note")
                .font(.system(size: 80))
                .foregroundColor(.white.opacity(0.3))

            Text("No recordings yet")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.7))

            Text("Create music on the main screen\nand press the record button")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)

            Spacer()
        }
    }

    private func deleteMusic(_ music: RecordedMusic) {
        if playbackManager.currentlyPlaying?.id == music.id {
            playbackManager.stop()
        }
        appState.deleteRecordedMusic(music)

        // Delete file
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioURL = documentsPath.appendingPathComponent(music.fileName)
        try? FileManager.default.removeItem(at: audioURL)
    }
}

// MARK: - Music Playback Manager

@MainActor
class MusicPlaybackManager: ObservableObject {
    @Published var currentlyPlaying: RecordedMusic?
    @Published var currentTime: TimeInterval = 0

    private var audioPlayer: AVAudioPlayer?
    private var displayLink: CADisplayLink?

    func play(_ music: RecordedMusic) {
        stop()

        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioURL = documentsPath.appendingPathComponent(music.fileName)

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            currentlyPlaying = music
            currentTime = 0

            startDisplayLink()
        } catch {
            print("❌ Playback failed: \(error.localizedDescription)")
        }
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        currentlyPlaying = nil
        currentTime = 0
        stopDisplayLink()
    }

    private func startDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateProgress))
        displayLink?.add(to: .main, forMode: .common)
    }

    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func updateProgress() {
        guard let player = audioPlayer, player.isPlaying else {
            stop()
            return
        }

        currentTime = player.currentTime

        // Auto-stop when finished
        if currentTime >= player.duration {
            stop()
        }
    }

    nonisolated deinit {
        // Invalidate on deinit - safe from any context
        displayLink?.invalidate()
    }
}

// MARK: - Music Card

struct MusicCard: View {
    let music: RecordedMusic
    let isPlaying: Bool
    let currentTime: TimeInterval
    let onTogglePlay: () -> Void
    let onDelete: () -> Void

    @State private var showDeleteConfirmation = false
    @State private var showShareSheet = false

    private var progress: Double {
        guard music.duration > 0 else { return 0 }
        return min(currentTime / music.duration, 1.0)
    }

    private var fileURL: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent(music.fileName)
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                // Play/Stop Button
                Button(action: onTogglePlay) {
                    ZStack {
                        Circle()
                            .fill(isPlaying ? GugakDesign.Colors.obangsaekRed : Color.white.opacity(0.2))
                            .frame(width: 50, height: 50)

                        Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .offset(x: isPlaying ? 0 : 2)
                    }
                }

                // Music Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(music.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                        Text(isPlaying ? formatTime(currentTime) : music.formattedDuration)
                            .font(.system(size: 12, design: .monospaced))
                    }
                    .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                // Export Button
                Button(action: { showShareSheet = true }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.1))
                        )
                }

                // Delete Button
                Button(action: { showDeleteConfirmation = true }) {
                    Image(systemName: "trash")
                        .font(.system(size: 18))
                        .foregroundColor(GugakDesign.Colors.obangsaekRed)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.1))
                        )
                }
            }

            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 6)

                    // Progress Fill
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    GugakDesign.Colors.obangsaekBlue,
                                    GugakDesign.Colors.obangsaekRed
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .confirmationDialog("Delete this recording?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [fileURL])
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
