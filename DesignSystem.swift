import SwiftUI

// MARK: - Design System for Gugak MIDI Pad

enum GugakDesign {

    // MARK: - Color Palette

    enum Colors {
        // Intro View - "Yeobaek" (Beauty of Emptiness)
        static let hanjiBeige = Color(red: 0.95, green: 0.93, blue: 0.88)
        static let darkCharcoal = Color(red: 0.2, green: 0.2, blue: 0.2)
        static let mutedRed = Color(red: 0.7, green: 0.3, blue: 0.3)
        static let inkGray = Color(red: 0.4, green: 0.4, blue: 0.4)

        // Main View - "Modern Tradition"
        static let darkNight = Color(red: 0.1, green: 0.12, blue: 0.15)
        static let glassBackground = Color(white: 0.15, opacity: 0.6)

        // Obangsaek - Traditional Five Colors
        static let obangsaekBlue = Color(red: 0.15, green: 0.25, blue: 0.45)      // Dark Navy/Indigo
        static let obangsaekRed = Color(red: 0.65, green: 0.3, blue: 0.25)        // Terracotta/Brick Red
        static let obangsaekYellow = Color(red: 0.85, green: 0.7, blue: 0.3)      // Mustard/Gold
        static let obangsaekWhite = Color(red: 0.95, green: 0.93, blue: 0.88)     // Warm Ivory
        static let obangsaekBlack = Color(red: 0.25, green: 0.25, blue: 0.28)     // Dark Grey/Charcoal

        // Glow Colors
        static let goldenGlow = Color(red: 1.0, green: 0.85, blue: 0.4)
        static let waveGradientPurple = Color(red: 0.5, green: 0.3, blue: 0.7)
        static let waveGradientBlue = Color(red: 0.3, green: 0.5, blue: 0.8)

        // All Obangsaek colors array for random distribution
        static let allObangsaek: [Color] = [
            obangsaekBlue, obangsaekRed, obangsaekYellow, obangsaekWhite, obangsaekBlack
        ]

        // Get color by index (0-4)
        static func obangsaek(at index: Int) -> Color {
            allObangsaek[index % 5]
        }

        // Get random Obangsaek color
        static func randomObangsaek(seed: Int) -> Color {
            allObangsaek[seed % 5]
        }
    }

    // MARK: - Typography

    enum Typography {
        static let serifFont = "NewYorkMedium-Regular" // or "Georgia"
        static let headingSize: CGFloat = 34
        static let subheadingSize: CGFloat = 20
        static let bodySize: CGFloat = 16
        static let captionSize: CGFloat = 12

        static func heading(_ text: String) -> Text {
            Text(text)
                .font(.custom(serifFont, size: headingSize))
                .fontWeight(.bold)
        }

        static func body(_ text: String) -> Text {
            Text(text)
                .font(.system(size: bodySize))
        }
    }

    // MARK: - Spacing

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
}

// MARK: - Custom Shapes

/// Giwa (Traditional Korean Roof Tile) Shape
/// Square top, slightly rounded/curved bottom
struct GiwaShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.width
        let height = rect.height
        let curveHeight: CGFloat = height * 0.15 // Bottom curve depth

        // Start from top-left
        path.move(to: CGPoint(x: 0, y: 0))

        // Top edge (straight)
        path.addLine(to: CGPoint(x: width, y: 0))

        // Right edge (straight)
        path.addLine(to: CGPoint(x: width, y: height - curveHeight))

        // Bottom-right curve
        path.addQuadCurve(
            to: CGPoint(x: width * 0.5, y: height),
            control: CGPoint(x: width * 0.85, y: height - curveHeight * 0.3)
        )

        // Bottom-left curve
        path.addQuadCurve(
            to: CGPoint(x: 0, y: height - curveHeight),
            control: CGPoint(x: width * 0.15, y: height - curveHeight * 0.3)
        )

        // Left edge (straight)
        path.addLine(to: CGPoint(x: 0, y: 0))

        path.closeSubpath()
        return path
    }
}

/// Traditional Korean Frame Shape (Double Border)
struct TraditionalFrameShape: Shape {
    var cornerRadius: CGFloat = 8

    func path(in rect: CGRect) -> Path {
        Path(roundedRect: rect, cornerRadius: cornerRadius)
    }
}

/// Korean Knot (Maedeup) Icon
struct MaedeupIcon: View {
    var color: Color = GugakDesign.Colors.mutedRed
    var size: CGFloat = 30

    var body: some View {
        ZStack {
            // Simplified Korean knot pattern
            Circle()
                .stroke(color, lineWidth: 3)
                .frame(width: size, height: size)

            Circle()
                .fill(color)
                .frame(width: size * 0.3, height: size * 0.3)

            ForEach(0..<4) { i in
                Capsule()
                    .fill(color)
                    .frame(width: size * 0.15, height: size * 0.5)
                    .rotationEffect(.degrees(Double(i) * 90))
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Traditional Button Style

struct TraditionalButtonStyle: ButtonStyle {
    var backgroundColor: Color = GugakDesign.Colors.hanjiBeige
    var borderColor: Color = GugakDesign.Colors.mutedRed

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 16)
            .padding(.horizontal, 48)
            .background(
                ZStack {
                    // Outer border
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(borderColor, lineWidth: 3)
                        .padding(2)

                    // Inner border
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(borderColor, lineWidth: 1.5)
                        .padding(6)

                    // Background
                    RoundedRectangle(cornerRadius: 8)
                        .fill(backgroundColor)
                }
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Glassmorphism Modifier

struct GlassmorphismModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(GugakDesign.Colors.glassBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

extension View {
    func glassmorphism() -> some View {
        modifier(GlassmorphismModifier())
    }
}

// MARK: - Giwa Button Style

struct GiwaButtonStyle: ButtonStyle {
    let color: Color
    let isActive: Bool

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            // Base Giwa shape with 3D depth
            GiwaShape()
                .fill(
                    LinearGradient(
                        colors: [
                            color,
                            color.opacity(0.8)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 4)

            // Inner shadow for depth
            GiwaShape()
                .stroke(Color.black.opacity(0.3), lineWidth: 1)

            // Glow effect when active
            if isActive || configuration.isPressed {
                GiwaShape()
                    .fill(GugakDesign.Colors.goldenGlow.opacity(0.6))
                    .blur(radius: 8)

                GiwaShape()
                    .stroke(GugakDesign.Colors.goldenGlow, lineWidth: 2)
            }

            // Engraved pattern (simplified)
            configuration.label
                .foregroundColor(color == GugakDesign.Colors.obangsaekWhite ? .black.opacity(0.3) : .white.opacity(0.3))
        }
        .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
