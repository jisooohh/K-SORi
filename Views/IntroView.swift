import SwiftUI

struct IntroView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var tutorialManager: TutorialManager
    @State private var showContent = false
    @State private var dontShowAgain = false
    @State private var rotationAngle: Double = 0

    var body: some View {
        ZStack {
            // Traditional Background with Wadang Pattern
            wadangBackgroundLayer
                .ignoresSafeArea()

            // Content
            ScrollView {
                VStack(spacing: 50) {
                    Spacer(minLength: 60)

                    // App Title with Traditional Style
                    titleSection
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : -30)

                    // Main Description with Hanji Style
                    hanjiDescriptionCard
                        .padding(.horizontal, 32)
                        .opacity(showContent ? 1 : 0)
                        .scaleEffect(showContent ? 1 : 0.95)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: showContent)

                    // Two Feature Sections
                    VStack(spacing: 20) {
                            beautyOfKSORiCard

                        traditionalFeatureCard(
                            title: "K-SORi Features",
                            description: "Experience traditional sounds with intuitive Giwa buttons. Create your own music easily through simple composition and recording functions.",
                            color: GugakDesign.Colors.obangsaekRed,
                            icon: "music.note"
                        )
                    }
                    .padding(.horizontal, 32)
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

                    // Start Button with Traditional Style
                    startButton
                        .opacity(showContent ? 1 : 0)
                        .scaleEffect(showContent ? 1 : 0.9)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.45), value: showContent)

                    // Tutorial replay button
                    tutorialButton
                        .opacity(showContent ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.5), value: showContent)

                    Spacer(minLength: 60)
                }
            }
        }
        .onAppear {
            withAnimation {
                showContent = true
            }
            // Slow rotation animation for wadang patterns
            withAnimation(.linear(duration: 60).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
        }
    }

    // MARK: - Background with Wadang Pattern

    private var wadangBackgroundLayer: some View {
        ZStack {
            // Dark traditional background
            GugakDesign.Colors.darkNight
                .ignoresSafeArea()

            // Wadang patterns scattered across background
            GeometryReader { geometry in
                ForEach(0..<12, id: \.self) { index in
                    let color = obangsaekColor(for: index)
                    let size = wadangSize(for: index, in: geometry.size)
                    let position = wadangPosition(for: index, in: geometry.size)

                    WadangPattern(style: wadangStyle(for: index))
                        .fill(color.opacity(0.08))
                        .frame(width: size, height: size)
                        .position(position)
                        .rotationEffect(.degrees(rotationAngle * rotationMultiplier(for: index)))
                        .blur(radius: 1)
                }
            }

            // Overlay gradient for depth
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.4),
                    Color.black.opacity(0.1),
                    Color.black.opacity(0.4)
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
                    .font(.system(size: 64, weight: .bold, design: .serif))
                    .foregroundColor(.white)

                ZStack {
                    // Invisible O maintains correct kerning/spacing
                    Text("O")
                        .font(.system(size: 64, weight: .bold, design: .serif))
                        .foregroundColor(.clear)
                    TaegukkCircle(size: 48)
                }

                Text("Ri")
                    .font(.system(size: 64, weight: .bold, design: .serif))
                    .foregroundColor(.white)
            }
            .shadow(color: GugakDesign.Colors.obangsaekRed.opacity(0.3), radius: 10)

            Text("Korean Sound Origami")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .tracking(2)

            TraditionalLineDecoration()
                .stroke(GugakDesign.Colors.obangsaekBlue, lineWidth: 2)
                .frame(width: 150, height: 20)
                .scaleEffect(x: -1, y: 1)
        }
        .padding(.horizontal, 32)
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
        let part1 = Text("Korean traditional music offers deep rest through the art of ")
            .font(.system(size: 15))
            .foregroundColor(.white.opacity(0.85))

        let part2 = Text("empty space")
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(GugakDesign.Colors.obangsaekYellow)

        let part3 = Text(" and ")
            .font(.system(size: 15))
            .foregroundColor(.white.opacity(0.85))

        let part4 = Text("harmony")
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(GugakDesign.Colors.obangsaekYellow)

        let part5 = Text(". Meet ")
            .font(.system(size: 15))
            .foregroundColor(.white.opacity(0.85))

        let part6 = Text("Gugak MIDI Pad")
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(GugakDesign.Colors.obangsaekYellow)

        let part7 = Text(", your own healing sound completed with a ")
            .font(.system(size: 15))
            .foregroundColor(.white.opacity(0.85))

        let part8 = Text("single touch")
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(GugakDesign.Colors.obangsaekYellow)

        let part9 = Text(".")
            .font(.system(size: 15))
            .foregroundColor(.white.opacity(0.85))

        return part1 + part2 + part3 + part4 + part5 + part6 + part7 + part8 + part9
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

    private var beautyOfKSORiCard: some View {
        VStack(spacing: 14) {
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
                    Text("Gugak embodies the aesthetics of nature. Melodies based on breath provide comfort and catharsis through the harmony of instruments.")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                        .lineSpacing(3)
                }
                Spacer()
            }

            // 5 representative instrument images
            HStack(spacing: 4) {
                ForEach(Constants.SoundCategory.allCases, id: \.self) { category in
                    VStack(spacing: 5) {
                        InstrumentImage(name: category.instrumentImageName)
                            .scaledToFit()
                            .frame(height: 58)
                            .brightness(-0.05)
                            .saturation(0.85)
                        Text(category.instrumentName)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 2)
        }
        .padding(20)
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

    // MARK: - Helper Functions

    private func obangsaekColor(for index: Int) -> Color {
        let colors = [
            GugakDesign.Colors.obangsaekBlue,
            GugakDesign.Colors.obangsaekRed,
            GugakDesign.Colors.obangsaekYellow,
            GugakDesign.Colors.obangsaekWhite,
            GugakDesign.Colors.obangsaekBlack
        ]
        return colors[index % colors.count]
    }

    private func wadangStyle(for index: Int) -> WadangPatternStyle {
        let styles: [WadangPatternStyle] = [.lotus, .geometric, .circular]
        return styles[index % styles.count]
    }

    private func wadangSize(for index: Int, in size: CGSize) -> CGFloat {
        let baseSizes: [CGFloat] = [120, 100, 80, 150, 90, 110, 130, 95, 105, 115, 85, 125]
        return baseSizes[index % baseSizes.count]
    }

    private func wadangPosition(for index: Int, in size: CGSize) -> CGPoint {
        // Distribute wadang patterns across the screen
        let positions: [(x: CGFloat, y: CGFloat)] = [
            (0.15, 0.1), (0.85, 0.15), (0.25, 0.25),
            (0.75, 0.3), (0.1, 0.4), (0.9, 0.45),
            (0.2, 0.55), (0.8, 0.65), (0.15, 0.75),
            (0.85, 0.8), (0.3, 0.9), (0.7, 0.92)
        ]
        let pos = positions[index % positions.count]
        return CGPoint(x: size.width * pos.x, y: size.height * pos.y)
    }

    private func rotationMultiplier(for index: Int) -> Double {
        // Different rotation speeds for visual interest
        let multipliers: [Double] = [0.3, -0.5, 0.2, -0.4, 0.6, -0.3, 0.4, -0.2, 0.5, -0.6, 0.35, -0.45]
        return multipliers[index % multipliers.count]
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

// MARK: - Taeguk (태극) Circle

/// Yin-yang style Taeguk symbol used inside the logo O
struct TaegukkCircle: View {
    let size: CGFloat

    private let yangRed  = Color(red: 0.95, green: 0.2,  blue: 0.2)
    private let yinBlue  = Color(red: 0.2,  green: 0.5,  blue: 0.9)

    var body: some View {
        ZStack {
            // 1. Yin (blue) base — full circle
            Circle().fill(yinBlue)

            // 2. Yang (red) — right half
            Circle().fill(yangRed)
                .clipShape(TaegukkHalfClip(side: .right))

            // 3. Yin bump: blue small circle on top (S-curve upper half)
            Circle().fill(yinBlue)
                .frame(width: size * 0.5, height: size * 0.5)
                .offset(y: -size * 0.25)

            // 4. Yang bump: red small circle on bottom (S-curve lower half)
            Circle().fill(yangRed)
                .frame(width: size * 0.5, height: size * 0.5)
                .offset(y: size * 0.25)

            // 5. Yang seed dot in yin bump
            Circle().fill(yangRed)
                .frame(width: size * 0.17, height: size * 0.17)
                .offset(y: -size * 0.25)

            // 6. Yin seed dot in yang bump
            Circle().fill(yinBlue)
                .frame(width: size * 0.17, height: size * 0.17)
                .offset(y: size * 0.25)
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.white.opacity(0.75), lineWidth: 1.5))
    }
}

private struct TaegukkHalfClip: Shape {
    enum Side { case left, right }
    let side: Side

    func path(in rect: CGRect) -> Path {
        switch side {
        case .right:
            return Path(CGRect(x: rect.midX, y: rect.minY,
                               width: rect.width / 2, height: rect.height))
        case .left:
            return Path(CGRect(x: rect.minX, y: rect.minY,
                               width: rect.width / 2, height: rect.height))
        }
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
