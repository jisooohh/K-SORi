import SwiftUI

@main
struct MyApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var tutorialManager = TutorialManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(tutorialManager)
                .preferredColorScheme(.dark)
        }
    }
}
