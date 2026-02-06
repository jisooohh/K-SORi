import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
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
        }
        .onAppear {
            appState.loadRecordedMusics()
            appState.determineInitialScreen()
        }
    }
}
