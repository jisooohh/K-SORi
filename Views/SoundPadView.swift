import SwiftUI

struct SoundPadView: View {
    let sounds: [Sound]
    let onPadTapped: (Sound) -> Void

    @State private var activePads: Set<Int> = []

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: Constants.gridSize)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(sounds) { sound in
                PadButton(
                    sound: sound,
                    isActive: activePads.contains(sound.position),
                    onTap: {
                        handlePadTap(sound)
                    }
                )
            }
        }
        .padding(16)
    }

    private func handlePadTap(_ sound: Sound) {
        activePads.insert(sound.position)
        onPadTapped(sound)

        // 사운드 지속 시간 후 비활성화
        DispatchQueue.main.asyncAfter(deadline: .now() + sound.duration) {
            activePads.remove(sound.position)
        }
    }
}

struct PadButton: View {
    let sound: Sound
    let isActive: Bool
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        GeometryReader { geometry in
            Button(action: {
                onTap()
            }) {
                ZStack {
                    // 배경
                    RoundedRectangle(cornerRadius: 16)
                        .fill(sound.category.color.opacity(isActive ? 1.0 : 0.3))
                        .shadow(
                            color: isActive ? sound.category.color.opacity(0.6) : .clear,
                            radius: isActive ? 20 : 0,
                            x: 0,
                            y: 0
                        )

                    // 테두리 효과
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            sound.category.color.opacity(isActive ? 1.0 : 0.5),
                            lineWidth: isActive ? 3 : 1
                        )

                    // 사운드 이름 (작은 텍스트)
                    VStack {
                        Spacer()
                        Text(sound.name)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(
                                sound.category == .voice ? .black.opacity(0.7) : .white.opacity(0.7)
                            )
                            .padding(.bottom, 6)
                    }
                }
            }
            .buttonStyle(PadButtonStyle())
            .frame(width: geometry.size.width, height: geometry.size.width)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

struct PadButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct SoundPadView_Previews: PreviewProvider {
    static var previews: some View {
        SoundPadView(sounds: SoundPad().sounds) { sound in
            print("Tapped: \(sound.name)")
        }
        .background(Constants.Colors.background)
    }
}
