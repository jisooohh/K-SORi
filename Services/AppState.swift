import SwiftUI
import Combine

enum AppScreen {
    case intro
    case main
    case musicList
}

@MainActor
class AppState: ObservableObject {
    @Published var currentScreen: AppScreen = .intro
    @Published var soundPad: SoundPad = SoundPad()
    @Published var recordedMusics: [RecordedMusic] = []
    @Published var isRecording: Bool = false
    @Published var shouldShowIntro: Bool = true

    private let shouldShowIntroKey = "shouldShowIntro"

    init() {
        loadSettings()
    }

    func navigateTo(_ screen: AppScreen) {
        NotificationCenter.default.post(name: .appStopAllAudio, object: nil)
        withAnimation(.easeInOut(duration: 0.3)) {
            currentScreen = screen
        }
    }

    func addRecordedMusic(_ music: RecordedMusic) {
        recordedMusics.insert(music, at: 0)
        saveRecordedMusics()
    }

    func deleteRecordedMusic(_ music: RecordedMusic) {
        recordedMusics.removeAll { $0.id == music.id }
        saveRecordedMusics()
    }

    func renameRecordedMusic(_ music: RecordedMusic, newName: String) {
        if let index = recordedMusics.firstIndex(where: { $0.id == music.id }) {
            recordedMusics[index].name = newName
            saveRecordedMusics()
        }
    }

    // 인트로 표시 설정 저장
    func setShouldShowIntro(_ value: Bool) {
        shouldShowIntro = value
        UserDefaults.standard.set(value, forKey: shouldShowIntroKey)
    }

    // 초기 화면 결정
    func determineInitialScreen() {
        currentScreen = shouldShowIntro ? .intro : .main
    }

    // UserDefaults에 저장
    private func saveRecordedMusics() {
        if let encoded = try? JSONEncoder().encode(recordedMusics) {
            UserDefaults.standard.set(encoded, forKey: "recordedMusics")
        }
    }

    // UserDefaults에서 로드
    func loadRecordedMusics() {
        if let data = UserDefaults.standard.data(forKey: "recordedMusics"),
           let decoded = try? JSONDecoder().decode([RecordedMusic].self, from: data) {
            recordedMusics = decoded
        }
    }

    // 설정 로드
    private func loadSettings() {
        // 기본값은 true (인트로 표시)
        if UserDefaults.standard.object(forKey: shouldShowIntroKey) == nil {
            shouldShowIntro = true
        } else {
            shouldShowIntro = UserDefaults.standard.bool(forKey: shouldShowIntroKey)
        }
    }
}
