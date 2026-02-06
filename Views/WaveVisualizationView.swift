import SwiftUI

struct WaveVisualizationView: View {
    let amplitudes: [Float]
    let frequencyBands: [Float]
    let globalAmplitude: Float

    @State private var phase: Double = 0

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSinceReferenceDate
                phase = now

                // Draw multiple visualization layers
                drawCircularWave(context: context, size: size)
                drawFrequencyBars(context: context, size: size)
                drawWaveform(context: context, size: size)
                drawParticles(context: context, size: size)
            }
        }
        .background(Color.clear)
    }

    // MARK: - Circular Wave (중앙 원형 파동)

    private func drawCircularWave(context: GraphicsContext, size: CGSize) {
        let centerX = size.width / 2
        let centerY = size.height / 2
        let baseRadius: CGFloat = 30

        // 글로벌 진폭 기반 원형 파동
        let amplitude = CGFloat(globalAmplitude)

        // 3개의 동심원 파동
        for i in 0..<3 {
            let offset = Double(i) * 0.4
            let radius = baseRadius + amplitude * 20 + CGFloat(sin(phase * 2 + offset)) * 15

            let path = Path { path in
                path.addEllipse(in: CGRect(
                    x: centerX - radius,
                    y: centerY - radius,
                    width: radius * 2,
                    height: radius * 2
                ))
            }

            let opacity = 0.6 - Double(i) * 0.15
            let color = Color.purple.opacity(opacity * Double(amplitude + 0.3))

            context.stroke(path, with: .color(color), lineWidth: 3.0)

            // Glow effect
            var blurredContext = context
            blurredContext.addFilter(.blur(radius: 8))
            blurredContext.stroke(path, with: .color(color.opacity(0.3)), lineWidth: 6.0)
        }
    }

    // MARK: - Frequency Bars (주파수 바)

    private func drawFrequencyBars(context: GraphicsContext, size: CGSize) {
        let barCount = frequencyBands.count
        let barWidth = size.width / CGFloat(barCount * 2)
        let spacing = barWidth * 0.3

        for i in 0..<barCount {
            let amplitude = CGFloat(frequencyBands[i])
            let barHeight = amplitude * size.height * 0.7

            let x = CGFloat(i) * (barWidth + spacing) + spacing
            let y = size.height - barHeight

            // Bar rectangle
            let barRect = CGRect(
                x: x,
                y: y,
                width: barWidth,
                height: barHeight
            )

            // Gradient from purple to blue
            let gradientStart = GugakDesign.Colors.waveGradientPurple
            let gradientEnd = GugakDesign.Colors.waveGradientBlue

            // Simulate gradient with opacity layers
            context.fill(
                Path(roundedRect: barRect, cornerRadius: barWidth / 4),
                with: .color(gradientStart.opacity(0.7))
            )

            // Glow at top
            let glowRect = CGRect(
                x: x,
                y: y,
                width: barWidth,
                height: min(barHeight, 10)
            )

            var glowContext = context
            glowContext.addFilter(.blur(radius: 8))
            glowContext.fill(
                Path(roundedRect: glowRect, cornerRadius: barWidth / 4),
                with: .color(gradientEnd.opacity(0.9))
            )
        }
    }

    // MARK: - Waveform (파형)

    private func drawWaveform(context: GraphicsContext, size: CGSize) {
        let centerY = size.height / 2

        // Calculate average amplitude
        let activeAmplitudes = amplitudes.filter { $0 > 0.01 }
        let averageAmplitude = activeAmplitudes.isEmpty
            ? 0.0
            : activeAmplitudes.reduce(0.0, +) / Float(activeAmplitudes.count)

        // Create flowing waveform
        for layerIndex in 0..<2 {
            let layerOffset = Double(layerIndex) * 0.5
            let layerAmplitude = CGFloat(averageAmplitude) * (1.0 - CGFloat(layerIndex) * 0.3)

            let path = createFlowingWavePath(
                width: size.width,
                centerY: centerY,
                amplitude: layerAmplitude,
                phase: phase + layerOffset,
                frequency: 2.0 + Double(layerIndex) * 0.5
            )

            let color = layerIndex == 0
                ? GugakDesign.Colors.waveGradientBlue
                : GugakDesign.Colors.waveGradientPurple

            let opacity = 0.5 - Double(layerIndex) * 0.15

            context.stroke(
                path,
                with: .color(color.opacity(opacity)),
                lineWidth: 3.0
            )

            // Glow
            var blurredContext = context
            blurredContext.addFilter(.blur(radius: 10))
            blurredContext.stroke(
                path,
                with: .color(color.opacity(opacity * 0.4)),
                lineWidth: 6.0
            )
        }
    }

    private func createFlowingWavePath(
        width: CGFloat,
        centerY: CGFloat,
        amplitude: CGFloat,
        phase: Double,
        frequency: Double
    ) -> Path {
        var path = Path()
        let stepCount = 200
        let step = width / CGFloat(stepCount)

        for i in 0...stepCount {
            let x = CGFloat(i) * step
            let normalizedX = x / width

            // Multiple sine waves for complex motion
            let angle1 = normalizedX * frequency * 2 * .pi + phase
            let angle2 = normalizedX * frequency * 1.5 * .pi - phase * 0.7

            let wave1 = sin(angle1)
            let wave2 = sin(angle2) * 0.5

            let combinedWave = (wave1 + wave2) / 1.5

            // Envelope
            let envelope = 1.0 - abs(normalizedX - 0.5) * 0.5

            let y = centerY + combinedWave * amplitude * envelope * 40

            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        return path
    }

    // MARK: - Particles (파티클 효과)

    private func drawParticles(context: GraphicsContext, size: CGSize) {
        // 활성 패드 기반 파티클 생성
        let particleCount = 20
        let centerY = size.height / 2

        for i in 0..<particleCount {
            // 각 파티클의 위치 계산 (시간 기반)
            let particlePhase = phase + Double(i) * 0.3
            let x = CGFloat(sin(particlePhase * 0.8)) * size.width * 0.4 + size.width / 2
            let y = centerY + CGFloat(cos(particlePhase * 1.2)) * 30

            // 진폭에 따른 파티클 크기
            let amplitude = CGFloat(globalAmplitude)
            let baseSize: CGFloat = 2.0
            let size = baseSize + amplitude * 4.0

            // 파티클 색상 (인덱스에 따라 변화)
            let colorProgress = Double(i) / Double(particleCount)
            let color = colorProgress < 0.5
                ? GugakDesign.Colors.waveGradientPurple
                : GugakDesign.Colors.waveGradientBlue

            let particleRect = CGRect(
                x: x - size / 2,
                y: y - size / 2,
                width: size,
                height: size
            )

            let opacity = (amplitude + 0.2) * 0.6

            // Draw particle with glow
            var glowContext = context
            glowContext.addFilter(.blur(radius: 4))
            glowContext.fill(
                Path(ellipseIn: particleRect),
                with: .color(color.opacity(opacity))
            )
        }
    }
}

// MARK: - Preview

struct WaveVisualizationView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            GugakDesign.Colors.darkNight
                .ignoresSafeArea()

            WaveVisualizationView(
                amplitudes: [0.5, 0.3, 0.7, 0.2, 0.4, 0.6, 0.3, 0.5, 0.2, 0.8, 0.4, 0.3, 0.6, 0.5, 0.4, 0.3, 0.7, 0.2, 0.5, 0.4, 0.6, 0.3, 0.5, 0.4, 0.3],
                frequencyBands: [0.8, 0.6, 0.7, 0.5, 0.4, 0.6, 0.3, 0.5],
                globalAmplitude: 0.7
            )
            .frame(height: 120)
            .padding()
            .glassmorphism()
        }
    }
}
