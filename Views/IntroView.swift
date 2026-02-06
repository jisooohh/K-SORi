import SwiftUI

struct IntroView: View {
    @EnvironmentObject var appState: AppState
    @State private var showContent = false
    @State private var dontShowAgain = false

    var body: some View {
        ZStack {
            Constants.Colors.background
                .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // 앱 타이틀
                VStack(spacing: 16) {
                    Text("K-SORi")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : -20)

                    Text("Korean Sound Origami")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .opacity(showContent ? 1 : 0)

                    // Header Description
                    headerDescription
                        .padding(.top, 8)
                        .opacity(showContent ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: showContent)
                }
                .padding(.horizontal, 32)

                Spacer()

                // Two Sections
                VStack(spacing: 20) {
                    // Section 1: The Beauty of K-SORi
                    descriptionCard(
                        icon: "sparkles",
                        title: "The Beauty of K-SORi",
                        description: "Gugak embodies the aesthetics of nature. Melodies based on breath provide comfort and emotional catharsis through the harmony of instruments."
                    )
                    .opacity(showContent ? 1 : 0)
                    .offset(x: showContent ? 0 : -30)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: showContent)

                    // Section 2: K-SORi Features
                    descriptionCard(
                        icon: "music.note.list",
                        title: "K-SORi Features",
                        description: "Experience traditional sounds with intuitive Giwa buttons. Create your own music easily through simple composition and recording functions."
                    )
                    .opacity(showContent ? 1 : 0)
                    .offset(x: showContent ? 0 : 30)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: showContent)
                }
                .padding(.horizontal, 32)

                Spacer()

                // "다시 보지 않기" 체크박스
                Button(action: {
                    dontShowAgain.toggle()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: dontShowAgain ? "checkmark.square.fill" : "square")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.8))

                        Text("Don't show this again")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .opacity(showContent ? 1 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.35), value: showContent)

                // 시작 버튼
                Button(action: {
                    // "다시 보지 않기" 설정 저장
                    if dontShowAgain {
                        appState.setShouldShowIntro(false)
                    }
                    appState.navigateTo(.main)
                }) {
                    HStack(spacing: 12) {
                        Text("Start")
                            .font(.system(size: 20, weight: .semibold))
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 24))
                    }
                    .foregroundColor(Constants.Colors.background)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 18)
                    .background(
                        Capsule()
                            .fill(.white)
                    )
                    .shadow(color: .white.opacity(0.3), radius: 20, x: 0, y: 10)
                }
                .opacity(showContent ? 1 : 0)
                .scaleEffect(showContent ? 1 : 0.8)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.4), value: showContent)

                Spacer()
            }
        }
        .onAppear {
            withAnimation {
                showContent = true
            }
        }
    }

    // Header Description with bold keywords
    private var headerDescription: some View {
        Text("Korean traditional music offers deep rest through the art of ")
            .font(.system(size: 15))
            .foregroundColor(.white.opacity(0.8))
        + Text("empty space")
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(.white)
        + Text(" and ")
            .font(.system(size: 15))
            .foregroundColor(.white.opacity(0.8))
        + Text("harmony")
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(.white)
        + Text(". Meet ")
            .font(.system(size: 15))
            .foregroundColor(.white.opacity(0.8))
        + Text("Gugak MIDI Pad")
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(.white)
        + Text(", your own healing sound completed with a ")
            .font(.system(size: 15))
            .foregroundColor(.white.opacity(0.8))
        + Text("single touch")
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(.white)
        + Text(".")
            .font(.system(size: 15))
            .foregroundColor(.white.opacity(0.8))
    }

    private func descriptionCard(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)

                Text(attributedDescription(for: title, text: description))
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.75))
                    .lineSpacing(4)
            }
            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Constants.Colors.cardBackground)
        )
    }

    // Helper to create attributed text with bold keywords
    private func attributedDescription(for title: String, text: String) -> AttributedString {
        var attributedString = AttributedString(text)

        // Define keywords to bold for each section
        let keywords: [String]
        if title.contains("Beauty") {
            keywords = ["nature", "breath", "comfort", "emotional catharsis", "harmony"]
        } else {
            keywords = ["Giwa buttons", "composition", "recording"]
        }

        // Apply bold to keywords
        for keyword in keywords {
            if let range = attributedString.range(of: keyword) {
                attributedString[range].font = .system(size: 13, weight: .bold)
                attributedString[range].foregroundColor = .white
            }
        }

        return attributedString
    }
}
