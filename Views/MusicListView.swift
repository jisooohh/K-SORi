import SwiftUI
import AVFoundation

struct MusicListView: View {
    @EnvironmentObject var appState: AppState
    @State private var playingMusic: RecordedMusic?
    @State private var audioPlayer: AVAudioPlayer?
    @State private var editingMusic: RecordedMusic?
    @State private var newName: String = ""

    var body: some View {
        ZStack {
            Constants.Colors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 헤더
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
                                    isPlaying: playingMusic?.id == music.id,
                                    onPlay: { playMusic(music) },
                                    onStop: { stopMusic() },
                                    onRename: { editingMusic = music; newName = music.name },
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
        .alert("이름 변경", isPresented: .constant(editingMusic != nil)) {
            TextField("새 이름", text: $newName)
            Button("취소", role: .cancel) {
                editingMusic = nil
            }
            Button("확인") {
                if let music = editingMusic {
                    appState.renameRecordedMusic(music, newName: newName)
                    editingMusic = nil
                }
            }
        }
    }

    private var headerView: some View {
        HStack {
            Button(action: {
                stopMusic()
                appState.navigateTo(.main)
            }) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
            }

            Text("제작 음악")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            Spacer()

            Text("\(appState.recordedMusics.count)곡")
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

            Text("아직 녹음된 음악이 없습니다")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.7))

            Text("메인 화면에서 음악을 만들고\n녹음 버튼을 눌러보세요")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)

            Spacer()
        }
    }

    private func playMusic(_ music: RecordedMusic) {
        stopMusic()

        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioURL = documentsPath.appendingPathComponent(music.fileName)

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer?.play()
            playingMusic = music

            // 재생이 끝나면 자동으로 정지
            DispatchQueue.main.asyncAfter(deadline: .now() + music.duration) { [weak audioPlayer] in
                if audioPlayer?.isPlaying == false {
                    self.playingMusic = nil
                }
            }
        } catch {
            print("오디오 재생 실패: \(error.localizedDescription)")
        }
    }

    private func stopMusic() {
        audioPlayer?.stop()
        audioPlayer = nil
        playingMusic = nil
    }

    private func deleteMusic(_ music: RecordedMusic) {
        if playingMusic?.id == music.id {
            stopMusic()
        }
        appState.deleteRecordedMusic(music)

        // 파일도 삭제
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioURL = documentsPath.appendingPathComponent(music.fileName)
        try? FileManager.default.removeItem(at: audioURL)
    }
}

struct MusicCard: View {
    let music: RecordedMusic
    let isPlaying: Bool
    let onPlay: () -> Void
    let onStop: () -> Void
    let onRename: () -> Void
    let onDelete: () -> Void

    @State private var showDeleteConfirmation = false

    var body: some View {
        HStack(spacing: 16) {
            // 재생/정지 버튼
            Button(action: {
                if isPlaying {
                    onStop()
                } else {
                    onPlay()
                }
            }) {
                Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(isPlaying ? Constants.Colors.red : .white)
            }

            // 음악 정보
            VStack(alignment: .leading, spacing: 6) {
                Text(music.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                HStack(spacing: 12) {
                    Label(music.formattedDuration, systemImage: "clock")
                    Label(music.formattedDate, systemImage: "calendar")
                }
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            // 메뉴 버튼
            Menu {
                Button(action: onRename) {
                    Label("이름 변경", systemImage: "pencil")
                }
                Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                    Label("삭제", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Constants.Colors.cardBackground)
        )
        .confirmationDialog("이 음악을 삭제하시겠습니까?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("삭제", role: .destructive, action: onDelete)
            Button("취소", role: .cancel) {}
        }
    }
}
