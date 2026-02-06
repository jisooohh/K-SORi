import AVFoundation
import SwiftUI

@MainActor
class AudioManager: ObservableObject {
    private var audioPlayers: [Int: AVAudioPlayer] = [:]
    private var meteringTimer: Timer?

    @Published var currentAmplitudes: [Float] = Array(repeating: 0.0, count: Constants.totalPads)
    @Published var globalAmplitude: Float = 0.0
    @Published var frequencyBands: [Float] = Array(repeating: 0.0, count: 8) // 8 frequency bands

    init() {
        setupAudioSession()
        startMetering()
    }

    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("오디오 세션 설정 실패: \(error.localizedDescription)")
        }
    }

    private func startMetering() {
        // 60 FPS로 오디오 레벨 업데이트
        meteringTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateAllAmplitudes()
            }
        }
    }

    func playSound(_ sound: Sound) {
        // 실제 음원 파일이 있을 때 사용
        guard let soundURL = Bundle.main.url(forResource: sound.fileName, withExtension: "mp3") ??
              Bundle.main.url(forResource: sound.fileName, withExtension: "wav") else {
            print("사운드 파일을 찾을 수 없음: \(sound.fileName)")
            playPlaceholderSound(for: sound)
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: soundURL)
            player.isMeteringEnabled = true // 중요: 메터링 활성화
            player.prepareToPlay()
            player.volume = 1.0
            player.play()

            audioPlayers[sound.position] = player

            // 재생이 끝나면 플레이어 제거
            DispatchQueue.main.asyncAfter(deadline: .now() + sound.duration) { [weak self] in
                self?.audioPlayers.removeValue(forKey: sound.position)
                self?.currentAmplitudes[sound.position] = 0.0
            }
        } catch {
            print("오디오 재생 실패: \(error.localizedDescription)")
            playPlaceholderSound(for: sound)
        }
    }

    // 실제 음원이 없을 때 사용할 임시 사운드
    private func playPlaceholderSound(for sound: Sound) {
        let systemSoundID: SystemSoundID
        switch sound.category {
        case .rhythm:
            systemSoundID = 1103
        case .percussion:
            systemSoundID = 1104
        case .melody:
            systemSoundID = 1105
        case .voice:
            systemSoundID = 1106
        case .base:
            systemSoundID = 1107
        }
        AudioServicesPlaySystemSound(systemSoundID)

        // 시스템 사운드용 시뮬레이션
        simulateAmplitudeForSystemSound(at: sound.position, duration: sound.duration)
    }

    private func simulateAmplitudeForSystemSound(at position: Int, duration: Double) {
        // 시스템 사운드의 진폭 시뮬레이션 (실제 오디오 파일이 없을 때)
        let steps = 30
        let stepDuration = duration / Double(steps)

        for step in 0..<steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(step)) { [weak self] in
                // 감쇠하는 진폭 시뮬레이션
                let progress = Float(step) / Float(steps)
                let amplitude = (1.0 - progress) * Float.random(in: 0.6...0.9)
                self?.currentAmplitudes[position] = amplitude
            }
        }

        // 마지막에 0으로
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.currentAmplitudes[position] = 0.0
        }
    }

    func stopSound(at position: Int) {
        audioPlayers[position]?.stop()
        audioPlayers.removeValue(forKey: position)
        currentAmplitudes[position] = 0.0
    }

    func stopAllSounds() {
        audioPlayers.values.forEach { $0.stop() }
        audioPlayers.removeAll()
        currentAmplitudes = Array(repeating: 0.0, count: Constants.totalPads)
        globalAmplitude = 0.0
    }

    // 모든 오디오 플레이어의 진폭 업데이트
    private func updateAllAmplitudes() {
        var maxAmplitude: Float = 0.0

        for (position, player) in audioPlayers where player.isPlaying {
            player.updateMeters()

            // 평균 파워 (dB)
            let avgPower = player.averagePower(forChannel: 0)

            // 피크 파워 (dB)
            let peakPower = player.peakPower(forChannel: 0)

            // dB를 선형 값으로 변환 (0.0 ~ 1.0)
            let normalizedAvg = pow(10, avgPower / 20)
            let normalizedPeak = pow(10, peakPower / 20)

            // 평균과 피크를 혼합하여 더 역동적인 시각화
            let amplitude = (normalizedAvg * 0.6 + normalizedPeak * 0.4)

            currentAmplitudes[position] = max(0.0, min(1.0, amplitude))
            maxAmplitude = max(maxAmplitude, amplitude)
        }

        // 전역 진폭 (부드러운 전환)
        let targetGlobal = maxAmplitude
        globalAmplitude = globalAmplitude * 0.85 + targetGlobal * 0.15

        // 주파수 밴드 시뮬레이션 (실제 FFT는 더 복잡하지만 시각적 효과를 위해 시뮬레이션)
        updateFrequencyBands()
    }

    private func updateFrequencyBands() {
        // 활성 오디오 기반 주파수 밴드 시뮬레이션
        let activeCount = audioPlayers.values.filter { $0.isPlaying }.count

        if activeCount > 0 {
            for i in 0..<frequencyBands.count {
                let baseAmplitude = globalAmplitude
                let variation = Float.random(in: -0.2...0.2)
                let bandAmplitude = baseAmplitude + variation

                // 부드러운 전환
                let targetValue = max(0.0, min(1.0, bandAmplitude))
                frequencyBands[i] = frequencyBands[i] * 0.7 + targetValue * 0.3
            }
        } else {
            // 감쇠
            for i in 0..<frequencyBands.count {
                frequencyBands[i] *= 0.85
            }
        }
    }

    deinit {
        meteringTimer?.invalidate()
    }
}
