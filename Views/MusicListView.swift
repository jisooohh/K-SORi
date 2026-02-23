import SwiftUI
import AVFoundation

struct MusicListView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var tutorialManager: TutorialManager
    @StateObject private var playbackManager = MusicPlaybackManager()

    @State private var selectedIDs: Set<UUID> = []
    @State private var isSelectionMode = false
    @State private var showDeleteConfirm = false

    private var allSelected: Bool {
        !appState.recordedMusics.isEmpty &&
        selectedIDs.count == appState.recordedMusics.count
    }

    var body: some View {
        ZStack {
            GugakDesign.Colors.darkNight.ignoresSafeArea()

            VStack(spacing: 0) {
                headerView
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 16)

                if appState.recordedMusics.isEmpty {
                    emptyStateView
                } else {
                    List {
                        ForEach(appState.recordedMusics) { music in
                            let isFirst = appState.recordedMusics.first?.id == music.id
                            MusicCard(
                                music: music,
                                isPlaying: playbackManager.currentlyPlaying?.id == music.id,
                                currentTime: playbackManager.currentlyPlaying?.id == music.id ? playbackManager.currentTime : 0,
                                isSelectionMode: isSelectionMode,
                                isSelected: selectedIDs.contains(music.id),
                                isTutorialTarget: isFirst && tutorialManager.isActive && tutorialManager.step == .playButton,
                                onTogglePlay: {
                                    guard !isSelectionMode else { return }
                                    if playbackManager.currentlyPlaying?.id == music.id {
                                        playbackManager.stop()
                                    } else {
                                        playbackManager.play(music)
                                        if isFirst && tutorialManager.isActive && tutorialManager.step == .playButton {
                                            tutorialManager.advance()
                                        }
                                    }
                                },
                                onToggleSelect: {
                                    toggleSelection(music.id)
                                },
                                onLongPress: {
                                    guard !isSelectionMode else { return }
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        isSelectionMode = true
                                        selectedIDs = [music.id]
                                    }
                                }
                            )
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowSeparator(.hidden)
                        }
                        .onDelete(perform: isSelectionMode ? nil : deleteMusicAtOffsets)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .appStopAllAudio)) { _ in
            playbackManager.stop()
        }
    }

    // MARK: - Header

    @ViewBuilder
    private var headerView: some View {
        if isSelectionMode {
            HStack(spacing: 8) {
                Text("\(selectedIDs.count) selected")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                // Trash button — confirmationDialog를 버튼에 직접 부착 (List 컨텍스트 우회)
                Button(action: {
                    showDeleteConfirm = true
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 18))
                        .foregroundColor(selectedIDs.isEmpty ? .white.opacity(0.3) : Color(red: 1.0, green: 0.3, blue: 0.3))
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color.white.opacity(selectedIDs.isEmpty ? 0.05 : 0.12)))
                }
                .disabled(selectedIDs.isEmpty)
                .confirmationDialog(
                    selectedIDs.count == 1 ? "Delete this recording?" : "Delete \(selectedIDs.count) recordings?",
                    isPresented: $showDeleteConfirm,
                    titleVisibility: .visible
                ) {
                    Button("Delete", role: .destructive) {
                        deleteSelectedMusics()
                        exitSelectionMode()
                    }
                    Button("Cancel", role: .cancel) {}
                }

                // Select All → Cancel (when all selected)
                Button(action: {
                    if allSelected {
                        exitSelectionMode()
                    } else {
                        withAnimation {
                            selectedIDs = Set(appState.recordedMusics.map { $0.id })
                        }
                    }
                }) {
                    Text(allSelected ? "Cancel" : "Select All")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.white.opacity(0.15)))
                }
            }
            .frame(height: 44)
        } else {
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
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                Text("\(appState.recordedMusics.count) tracks")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }

    // MARK: - Empty State

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

    // MARK: - Actions

    private func toggleSelection(_ id: UUID) {
        withAnimation(.easeInOut(duration: 0.15)) {
            if selectedIDs.contains(id) {
                selectedIDs.remove(id)
                if selectedIDs.isEmpty { exitSelectionMode() }
            } else {
                selectedIDs.insert(id)
            }
        }
    }

    private func exitSelectionMode() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isSelectionMode = false
            selectedIDs.removeAll()
        }
    }

    private func deleteMusic(_ music: RecordedMusic) {
        if playbackManager.currentlyPlaying?.id == music.id { playbackManager.stop() }
        appState.deleteRecordedMusic(music)
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        try? FileManager.default.removeItem(at: docs.appendingPathComponent(music.fileName))
    }

    private func deleteMusicAtOffsets(_ offsets: IndexSet) {
        for index in offsets { deleteMusic(appState.recordedMusics[index]) }
    }

    private func deleteSelectedMusics() {
        for music in appState.recordedMusics.filter({ selectedIDs.contains($0.id) }) {
            deleteMusic(music)
        }
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
        let audioURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(music.fileName)
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
        guard let player = audioPlayer, player.isPlaying else { stop(); return }
        currentTime = player.currentTime
        if currentTime >= player.duration { stop() }
    }

    nonisolated deinit {
        displayLink?.invalidate()
    }
}

// MARK: - Music Card

struct MusicCard: View {
    let music: RecordedMusic
    let isPlaying: Bool
    let currentTime: TimeInterval
    var isSelectionMode: Bool = false
    var isSelected: Bool = false
    var isTutorialTarget: Bool = false
    let onTogglePlay: () -> Void
    var onToggleSelect: () -> Void = {}
    var onLongPress: () -> Void = {}

    @State private var showShareSheet = false

    private var progress: Double {
        guard music.duration > 0 else { return 0 }
        return min(currentTime / music.duration, 1.0)
    }

    private var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(music.fileName)
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {

                // 선택 모드: 체크박스 / 일반 모드: 재생 버튼
                if isSelectionMode {
                    Button(action: onToggleSelect) {
                        ZStack {
                            Circle()
                                .fill(isSelected ? GugakDesign.Colors.obangsaekBlue : Color.clear)
                                .frame(width: 28, height: 28)
                            Circle()
                                .stroke(
                                    isSelected ? GugakDesign.Colors.obangsaekBlue : Color.white.opacity(0.4),
                                    lineWidth: 2
                                )
                                .frame(width: 28, height: 28)
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(width: 50, height: 50)
                    }
                    .buttonStyle(.plain)
                } else {
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
                    .buttonStyle(.plain)
                    .tutorialFrame(isTutorialTarget ? "play_first" : "play_\(music.id)")
                }

                // 곡 정보
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

                // 공유 버튼 — 일반 모드에서만 표시
                if !isSelectionMode {
                    Button(action: { showShareSheet = true }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(Color.white.opacity(0.1)))
                    }
                    .buttonStyle(.plain)
                }
            }

            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [
                                GugakDesign.Colors.obangsaekBlue,
                                GugakDesign.Colors.obangsaekRed
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: geometry.size.width * progress, height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isSelected ? Color.white.opacity(0.10) : Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isSelected
                                ? GugakDesign.Colors.obangsaekBlue.opacity(0.6)
                                : Color.white.opacity(0.1),
                            lineWidth: isSelected ? 1.5 : 1
                        )
                )
        )
        .contentShape(RoundedRectangle(cornerRadius: 16))
        // 선택 모드에서 카드 탭 → 선택 토글
        .onTapGesture {
            if isSelectionMode { onToggleSelect() }
        }
        // 일반 모드에서 길게 누르면 선택 모드 진입
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.45)
                .onEnded { _ in onLongPress() }
        )
        .animation(.easeInOut(duration: 0.15), value: isSelectionMode)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
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
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
