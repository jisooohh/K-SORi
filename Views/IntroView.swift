import SwiftUI
import UIKit

struct IntroView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var tutorialManager: TutorialManager
    @State private var showContent = false
    @State private var dontShowAgain = false

    @Environment(\.horizontalSizeClass) private var hSizeClass
    private var isCompact: Bool { hSizeClass == .compact }

    var body: some View {
        ZStack {
            // Traditional Background with Wadang Pattern
            wadangBackgroundLayer
                .ignoresSafeArea()

            // Content — GeometryReader로 가용 크기 파악
            GeometryReader { geo in
                ScrollView {
                    VStack(spacing: 28) {
                        Spacer(minLength: 48)

                        // App Title with Traditional Style
                        titleSection
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : -30)

                        // Main Description with Hanji Style
                        hanjiDescriptionCard
                            .padding(.horizontal, isCompact ? 20 : 32)
                            .opacity(showContent ? 1 : 0)
                            .scaleEffect(showContent ? 1 : 0.95)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: showContent)

                        // Two Feature Sections
                        VStack(spacing: 14) {
                            beautyOfKSORiCard

                            traditionalFeatureCard(
                                title: "K-SORi SoundPad Features",
                                description: "Tap rhythm, melody, percussion, voice, and bass pads.\nEvery sound is harmonically structured — so any combination creates natural music.\n\nNo theory required. Just touch and create.",
                                color: GugakDesign.Colors.obangsaekRed,
                                icon: "music.note"
                            )
                        }
                        .padding(.horizontal, isCompact ? 20 : 32)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: showContent)

                        // Don't show again checkbox
                        Button(action: {
                            dontShowAgain.toggle()
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: dontShowAgain ? "checkmark.square.fill" : "square")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white.opacity(0.9))

                                Text("Don't show this again")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                        .opacity(showContent ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.4), value: showContent)

                        Spacer(minLength: 18)

                        // Start Button with Traditional Style
                        startButton
                            .opacity(showContent ? 1 : 0)
                            .scaleEffect(showContent ? 1 : 0.9)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.45), value: showContent)

                        // Tutorial replay button
                        tutorialButton
                            .opacity(showContent ? 1 : 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.5), value: showContent)

                        Spacer(minLength: 40)
                    }
                    // 콘텐츠 최대 너비 제한 + 중앙 정렬
                    .frame(maxWidth: 720)
                    .frame(maxWidth: .infinity)
                    // 화면보다 짧을 때 Spacer가 남는 공간을 균등 분배 → 수직 중앙 정렬
                    .frame(minHeight: geo.size.height)
                }
            }
        }
        .onAppear {
            withAnimation {
                showContent = true
            }
        }
    }

    // MARK: - Background with Wadang Pattern

    private var wadangBackgroundLayer: some View {
        ZStack {
            // Warm traditional background
            Color(red: 0.18, green: 0.14, blue: 0.10)
                .ignoresSafeArea()

            // Centered Wadang medallion (vector, gold)
            GeometryReader { geometry in
                let minSide = min(geometry.size.width, geometry.size.height)
                let size = minSide * 0.62
                let gold = Color(red: 0.78, green: 0.64, blue: 0.28)
                WadangMedallion()
                    .stroke(gold.opacity(0.28), lineWidth: size * 0.06)
                    .frame(width: size, height: size)
                    .position(x: geometry.size.width * 0.5, y: geometry.size.height * 0.45)
            }

            // Overlay gradient for depth
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.45),
                    Color.black.opacity(0.12),
                    Color.black.opacity(0.45)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(spacing: 16) {
            // Traditional decorative line
            TraditionalLineDecoration()
                .stroke(GugakDesign.Colors.obangsaekRed, lineWidth: 2)
                .frame(width: 150, height: 20)

            // K-SORi logo with Taeguk inside the O
            HStack(alignment: .center, spacing: 0) {
                Text("K-S")
                    .font(.system(size: isCompact ? 44 : 64, weight: .bold, design: .serif))
                    .foregroundColor(.white)

                ZStack {
                    // Invisible O maintains correct kerning/spacing
                    Text("O")
                        .font(.system(size: isCompact ? 44 : 64, weight: .bold, design: .serif))
                        .foregroundColor(.clear)
                    TaegukkImageView(size: isCompact ? 33 : 48)
                }

                Text("Ri")
                    .font(.system(size: isCompact ? 44 : 64, weight: .bold, design: .serif))
                    .foregroundColor(.white)
            }
            .shadow(color: GugakDesign.Colors.obangsaekRed.opacity(0.3), radius: 10)

            Text("Korean Traditional SoundPad")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .tracking(1.4)

            TraditionalLineDecoration()
                .stroke(GugakDesign.Colors.obangsaekBlue, lineWidth: 2)
                .frame(width: 150, height: 20)
                .scaleEffect(x: -1, y: 1)
        }
        .padding(.horizontal, isCompact ? 20 : 32)
    }

    // MARK: - Hanji Description Card

    private var hanjiDescriptionCard: some View {
        VStack(spacing: 16) {
            hanjiDescriptionText
        }
        .multilineTextAlignment(.center)
        .lineSpacing(6)
        .padding(24)
        .background(hanjiCardBackground)
    }

    private var hanjiDescriptionText: Text {
        let part1 = Text("A Korean Traditional Sound Pad —\nwhere \"")
            .font(.system(size: 15))
            .foregroundColor(.white.opacity(0.85))

        let part2 = Text("Sori")
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(GugakDesign.Colors.obangsaekYellow)

        let part3 = Text("\" means sound, and the small \"")
            .font(.system(size: 15))
            .foregroundColor(.white.opacity(0.85))

        let part4 = Text("i")
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(GugakDesign.Colors.obangsaekYellow)

        let part5 = Text("\" stands for inspiration.")
            .font(.system(size: 15))
            .foregroundColor(.white.opacity(0.85))

        return part1 + part2 + part3 + part4 + part5
    }

    private var hanjiCardBackground: some View {
        ZStack {
            // Hanji paper texture effect
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.03))

            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            GugakDesign.Colors.obangsaekRed.opacity(0.3),
                            GugakDesign.Colors.obangsaekBlue.opacity(0.3)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )

            // Corner decorations
            VStack {
                HStack {
                    CornerDecoration()
                        .stroke(GugakDesign.Colors.obangsaekRed, lineWidth: 2)
                        .frame(width: 30, height: 30)
                    Spacer()
                    CornerDecoration()
                        .stroke(GugakDesign.Colors.obangsaekBlue, lineWidth: 2)
                        .frame(width: 30, height: 30)
                        .scaleEffect(x: -1, y: 1)
                }
                Spacer()
                HStack {
                    CornerDecoration()
                        .stroke(GugakDesign.Colors.obangsaekBlue, lineWidth: 2)
                        .frame(width: 30, height: 30)
                        .scaleEffect(x: 1, y: -1)
                    Spacer()
                    CornerDecoration()
                        .stroke(GugakDesign.Colors.obangsaekRed, lineWidth: 2)
                        .frame(width: 30, height: 30)
                        .scaleEffect(x: -1, y: -1)
                }
            }
            .padding(8)
        }
    }

    // MARK: - Traditional Feature Card

    private func traditionalFeatureCard(title: String, description: String, color: Color, icon: String) -> some View {
        HStack(spacing: 16) {
            // Icon with wadang background
            ZStack {
                WadangPattern(style: .lotus)
                    .fill(color.opacity(0.15))
                    .frame(width: 60, height: 60)

                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)

                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.8))
                    .lineSpacing(4)
            }

            Spacer()
        }
        .padding(20)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.03))

                RoundedRectangle(cornerRadius: 16)
                    .stroke(color.opacity(0.3), lineWidth: 1.5)
            }
        )
    }

    // MARK: - Start Button

    private var startButton: some View {
        Button(action: {
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
            .foregroundColor(GugakDesign.Colors.darkNight)
            .padding(.horizontal, 50)
            .padding(.vertical, 18)
            .background(
                ZStack {
                    Capsule()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    GugakDesign.Colors.obangsaekYellow,
                                    Color.white
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Capsule()
                        .stroke(GugakDesign.Colors.obangsaekRed.opacity(0.3), lineWidth: 2)
                }
            )
            .shadow(color: GugakDesign.Colors.obangsaekYellow.opacity(0.4), radius: 20, x: 0, y: 10)
        }
    }

    // MARK: - Beauty of K-SORi Card (with instrument images)

    private func categoryDisplayLabel(_ category: Constants.SoundCategory) -> String {
        switch category {
        case .melody:     return "MELODY"
        case .percussion: return "PERCUSSION"
        case .rhythm:     return "RHYTHM"
        case .voice:      return "VOCAL"
        case .base:       return "BASS"
        }
    }

    private var beautyOfKSORiCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                ZStack {
                    WadangPattern(style: .lotus)
                        .fill(GugakDesign.Colors.obangsaekBlue.opacity(0.15))
                        .frame(width: 60, height: 60)
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 24))
                        .foregroundColor(GugakDesign.Colors.obangsaekBlue)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("The Beauty of K-SORi")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Text("Korean traditional music expresses emotion through space, breath, and harmony.\nIts tones carry depth, joy, and spirit — shaping a uniquely Korean sound.")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                        .lineSpacing(3)
                }
                Spacer()
            }

            // 5 representative instrument images
            HStack(spacing: 1) {
                ForEach(Constants.SoundCategory.allCases, id: \.self) { category in
                    VStack(spacing: 0) {
                        InstrumentImage(name: category.instrumentImageName)
                            .scaledToFit()
                            .frame(height: isCompact ? 90 : 144)
                            .brightness(-0.05)
                            .saturation(0.85)
                        Text(categoryDisplayLabel(category))
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(GugakDesign.Colors.obangsaekYellow)
                            .padding(.top, 2)
                        Text(category.instrumentNameEnglish)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.03))
                RoundedRectangle(cornerRadius: 16)
                    .stroke(GugakDesign.Colors.obangsaekBlue.opacity(0.3), lineWidth: 1.5)
            }
        )
    }

    // MARK: - Tutorial Button

    private var tutorialButton: some View {
        Button(action: {
            if dontShowAgain { appState.setShouldShowIntro(false) }
            appState.navigateTo(.main)
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000)
                tutorialManager.start(sounds: appState.soundPad.sounds)
            }
        }) {
            HStack(spacing: 10) {
                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 16))
                Text("Start Tutorial")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(.white.opacity(0.85))
            .padding(.horizontal, 40)
            .padding(.vertical, 13)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.08))
                    .overlay(Capsule().stroke(Color.white.opacity(0.25), lineWidth: 1.5))
            )
        }
    }

}

// MARK: - Wadang Pattern Shape

enum WadangPatternStyle {
    case lotus
    case geometric
    case circular
}

struct WadangPattern: Shape {
    let style: WadangPatternStyle

    func path(in rect: CGRect) -> Path {
        switch style {
        case .lotus:
            return lotusPattern(in: rect)
        case .geometric:
            return geometricPattern(in: rect)
        case .circular:
            return circularPattern(in: rect)
        }
    }

    private func lotusPattern(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        // Outer circle
        path.addEllipse(in: CGRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        ))

        // Lotus petals (8 petals)
        for i in 0..<8 {
            let angle = Double(i) * .pi / 4
            let petalPath = Path { p in
                let startAngle = angle - .pi / 8
                let endAngle = angle + .pi / 8

                p.move(to: center)
                p.addArc(
                    center: center,
                    radius: radius * 0.8,
                    startAngle: .radians(startAngle),
                    endAngle: .radians(endAngle),
                    clockwise: false
                )
                p.closeSubpath()
            }
            path.addPath(petalPath)
        }

        // Inner circle
        path.addEllipse(in: CGRect(
            x: center.x - radius * 0.3,
            y: center.y - radius * 0.3,
            width: radius * 0.6,
            height: radius * 0.6
        ))

        return path
    }

    private func geometricPattern(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        // Outer circle
        path.addEllipse(in: CGRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        ))

        // Geometric pattern (square rotated)
        for i in 0..<4 {
            let angle = Double(i) * .pi / 2
            let size = radius * 0.7

            let squarePath = Path { p in
                let x1 = center.x + cos(angle) * radius * 0.4
                let y1 = center.y + sin(angle) * radius * 0.4
                let x2 = center.x + cos(angle + .pi / 2) * radius * 0.4
                let y2 = center.y + sin(angle + .pi / 2) * radius * 0.4

                p.move(to: CGPoint(x: x1, y: y1))
                p.addLine(to: CGPoint(x: x2, y: y2))
            }
            path.addPath(squarePath)
        }

        return path
    }

    private func circularPattern(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        // Multiple concentric circles
        for i in 1...3 {
            let r = radius * CGFloat(i) / 3.0
            path.addEllipse(in: CGRect(
                x: center.x - r,
                y: center.y - r,
                width: r * 2,
                height: r * 2
            ))
        }

        return path
    }
}

// MARK: - Traditional Line Decoration

struct TraditionalLineDecoration: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        // Decorative curved line (cloud-like)
        path.move(to: CGPoint(x: 0, y: height / 2))

        let controlPoint1 = CGPoint(x: width * 0.25, y: 0)
        let controlPoint2 = CGPoint(x: width * 0.25, y: height)
        let endPoint1 = CGPoint(x: width * 0.5, y: height / 2)

        path.addCurve(to: endPoint1, control1: controlPoint1, control2: controlPoint2)

        let controlPoint3 = CGPoint(x: width * 0.75, y: 0)
        let controlPoint4 = CGPoint(x: width * 0.75, y: height)
        let endPoint2 = CGPoint(x: width, y: height / 2)

        path.addCurve(to: endPoint2, control1: controlPoint3, control2: controlPoint4)

        return path
    }
}

// MARK: - Taeguk Image View

/// Loads taeguk.png from app bundle for use inside the logo O
struct TaegukkImageView: View {
    let size: CGFloat

    private var uiImage: UIImage? {
        if let img = UIImage(named: "taeguk") { return img }
        if let url = Bundle.main.url(forResource: "taeguk", withExtension: "png"),
           let data = try? Data(contentsOf: url),
           let img = UIImage(data: data) { return img }
        return nil
    }

    var body: some View {
        if let img = uiImage {
            Image(uiImage: img)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.65), lineWidth: 1.1))
        }
    }
}

// MARK: - Wadang Medallion (Vector)

struct WadangMedallion: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let w = rect.width
        let h = rect.height
        let inset = min(w, h) * 0.08
        let line = min(w, h) * 0.12
        let r = min(w, h) / 2 - inset
        let cx = rect.midX
        let cy = rect.midY

        // Outer circle
        path.addEllipse(in: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))

        let s = line
        let d = r - s

        func move(_ x: CGFloat, _ y: CGFloat) { path.move(to: CGPoint(x: x, y: y)) }
        func lineTo(_ x: CGFloat, _ y: CGFloat) { path.addLine(to: CGPoint(x: x, y: y)) }

        // Vertical spine
        move(cx, cy - d)
        lineTo(cx, cy + d)

        // Horizontal mid bar
        move(cx - d, cy)
        lineTo(cx + d, cy)

        // Upper left
        move(cx - d, cy - s)
        lineTo(cx - s, cy - s)
        lineTo(cx - s, cy - d)

        // Upper right
        move(cx + d, cy - s)
        lineTo(cx + s, cy - s)
        lineTo(cx + s, cy - d)

        // Lower left
        move(cx - d, cy + s)
        lineTo(cx - s, cy + s)
        lineTo(cx - s, cy + d)

        // Lower right
        move(cx + d, cy + s)
        lineTo(cx + s, cy + s)
        lineTo(cx + s, cy + d)

        return path
    }
}

// MARK: - Corner Decoration

struct CornerDecoration: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Traditional corner pattern
        path.move(to: CGPoint(x: 0, y: rect.height * 0.6))
        path.addLine(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width * 0.6, y: 0))

        // Add curve
        path.move(to: CGPoint(x: 0, y: rect.height * 0.6))
        path.addQuadCurve(
            to: CGPoint(x: rect.width * 0.6, y: 0),
            control: CGPoint(x: 0, y: 0)
        )

        return path
    }
}
