import SwiftUI
import UIKit

// MARK: - PreferenceKey

struct TutorialFrameKey: PreferenceKey {
    static var defaultValue: [String: CGRect] { [:] }
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue()) { $1 }
    }
}

// MARK: - View Extension

extension View {
    /// Reports this view's global frame under `key` via TutorialFrameKey.
    func tutorialFrame(_ key: String) -> some View {
        self.background(
            GeometryReader { geo in
                Color.clear.preference(
                    key: TutorialFrameKey.self,
                    value: [key: geo.frame(in: .global)]
                )
            }
        )
    }
}

// MARK: - Cutout Shape (even-odd fill)

private struct CutoutShape: Shape {
    let targetRect: CGRect
    let cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRect(rect)                           // outer: fill entire screen
        path.addRoundedRect(                         // inner: punch a hole
            in: targetRect.insetBy(dx: -6, dy: -6),
            cornerSize: CGSize(width: cornerRadius + 6, height: cornerRadius + 6)
        )
        return path
    }
}

// MARK: - UIKit Touch Blocker

/// A UIView that blocks touches outside the cutout and passes touches inside through.
private class TutorialBlockerUIView: UIView {
    var cutoutRect: CGRect = .zero

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // Convert from this view's local coordinates to window (global) coordinates
        let globalPoint = convert(point, to: nil)
        // Generous inset so buttons near the edge of the highlight still work
        if cutoutRect.insetBy(dx: -12, dy: -12).contains(globalPoint) {
            return nil   // pass through — let underlying SwiftUI button handle it
        }
        return self      // absorb the touch
    }

    // Absorb without any action
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {}
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {}
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {}
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {}
}

private struct TutorialBlocker: UIViewRepresentable {
    let cutoutRect: CGRect

    func makeUIView(context: Context) -> TutorialBlockerUIView {
        let view = TutorialBlockerUIView()
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: TutorialBlockerUIView, context: Context) {
        uiView.cutoutRect = cutoutRect
    }
}

// MARK: - Speech Bubble

private struct TutorialBubble: View {
    let title: String
    let message: String
    let targetRect: CGRect
    let screenSize: CGSize

    /// Place bubble above target when the target is in the lower half of the screen
    private var isAbove: Bool { targetRect.midY > screenSize.height * 0.52 }

    /// Clamped X origin so the 300 pt bubble stays on screen
    private var bubbleOriginX: CGFloat {
        let half: CGFloat = 150
        return min(max(targetRect.midX - half, 16), screenSize.width - 16 - half * 2)
    }

    /// Arrow horizontal offset relative to bubble center, pointing at target midX
    private var arrowOffsetX: CGFloat { targetRect.midX - (bubbleOriginX + 150) }

    var body: some View {
        VStack(spacing: 0) {
            if !isAbove { arrowTip(pointsUp: true)  .padding(.leading, 150 + arrowOffsetX) }
            bubbleBody
            if isAbove  { arrowTip(pointsUp: false) .padding(.leading, 150 + arrowOffsetX) }
        }
        .frame(width: 300, alignment: .leading)
        .position(
            x: bubbleOriginX + 150,
            y: isAbove
                ? targetRect.minY - 6 - 52
                : targetRect.maxY + 6 + 52
        )
    }

    private var bubbleBody: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
            Text(message)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(white: 0.12).opacity(0.97))
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.18), lineWidth: 1))
        )
    }

    private func arrowTip(pointsUp: Bool) -> some View {
        ArrowTriangle(pointsUp: pointsUp)
            .fill(Color(white: 0.12).opacity(0.97))
            .frame(width: 16, height: 9)
    }
}

private struct ArrowTriangle: Shape {
    let pointsUp: Bool
    func path(in rect: CGRect) -> Path {
        var p = Path()
        if pointsUp {
            p.move(to: CGPoint(x: rect.midX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        } else {
            p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        }
        p.closeSubpath()
        return p
    }
}

// MARK: - Completion Banner

struct TutorialCompletionBanner: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.green)
            Text("All Done!")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            Text("Enjoy making music freely.")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(white: 0.1).opacity(0.97))
                .overlay(RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1))
        )
        .shadow(color: .black.opacity(0.5), radius: 30)
    }
}

// MARK: - Tutorial Overlay View

struct TutorialOverlayView: View {
    @EnvironmentObject var tutorialManager: TutorialManager
    let screenSize: CGSize

    var body: some View {
        if tutorialManager.isActive {
            if tutorialManager.step == .complete {
                // Completion state — no interaction needed
                ZStack {
                    Color.black.opacity(0.6).ignoresSafeArea()
                    TutorialCompletionBanner()
                }
                .allowsHitTesting(false)

            } else if let targetRect = tutorialManager.currentTargetFrame() {
                ZStack {
                    // 1. Visual dimming with even-odd cutout (no hit testing)
                    CutoutShape(targetRect: targetRect, cornerRadius: 12)
                        .fill(Color.black.opacity(0.72), style: FillStyle(eoFill: true))
                        .ignoresSafeArea()
                        .allowsHitTesting(false)

                    // 2. UIKit blocker: passes touches inside cutout, absorbs outside
                    TutorialBlocker(cutoutRect: targetRect)
                        .ignoresSafeArea()

                    // 3. Speech bubble (visual only)
                    TutorialBubble(
                        title: tutorialManager.step.title,
                        message: tutorialManager.step.message,
                        targetRect: targetRect,
                        screenSize: screenSize
                    )
                    .allowsHitTesting(false)

                    // 4. Skip button (must be above blocker in z-order)
                    VStack {
                        HStack {
                            Spacer()
                            Button("Skip") { tutorialManager.skip() }
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(Color.white.opacity(0.15)))
                                .padding(.top, 60)
                                .padding(.trailing, 20)
                        }
                        Spacer()
                    }
                }
            } else {
                // Target frame not yet collected — wait silently (no hit blocking)
                Color.clear
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
    }
}
