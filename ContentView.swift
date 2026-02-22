import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var tutorialManager: TutorialManager

    var body: some View {
        GeometryReader { geo in
            ZStack {
                switch appState.currentScreen {
                case .intro:
                    IntroView()
                        .transition(.opacity)

                case .main:
                    MainView()
                        .transition(.move(edge: .trailing))

                case .musicList:
                    MusicListView()
                        .transition(.move(edge: .trailing))
                }

                // 튜토리얼 오버레이 (항상 최상단)
                TutorialOverlayView(screenSize: geo.size)
            }
            .onPreferenceChange(TutorialFrameKey.self) { frames in
                tutorialManager.frames = frames
            }
        }
        .onAppear {
            appState.loadRecordedMusics()
            appState.determineInitialScreen()
        }
    }
}
