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

    // Toggle 방식: 재생 중이면 정지, 정지 중이면 재생
    func toggleSound(_ sound: Sound) {
        if let player = audioPlayers[sound.position], player.isPlaying {
            // 이미 재생 중이면 정지
            stopSound(at: sound.position)
        } else {
            // 정지 중이면 재생 시작
            playSound(sound)
        }
    }

    private func playSound(_ sound: Sound) {
        // Swift Package Manager에서 리소스 찾기
        var soundURL: URL?

        // 방법 1: Bundle.module 사용 (Swift Package Manager)
        #if canImport(Foundation)
        if let moduleBundle = Bundle(identifier: "KSORi.AppModule") ?? Bundle.main.path(forResource: "AppModule", ofType: "bundle").flatMap(Bundle.init(path:)) {
            soundURL = moduleBundle.url(forResource: sound.fileName, withExtension: "wav", subdirectory: "Resources")
            if soundURL != nil {
                print("✅ 방법 1 (module bundle): 파일 찾음")
            }
        }
        #endif

        // 방법 2: Bundle.main에서 찾기 (Resources 서브디렉토리)
        if soundURL == nil {
            soundURL = Bundle.main.url(forResource: sound.fileName, withExtension: "wav", subdirectory: "Resources")
            if soundURL != nil {
                print("✅ 방법 2 (main bundle Resources): 파일 찾음")
            }
        }

        // 방법 3: Bundle.main에서 직접 찾기
        if soundURL == nil {
            soundURL = Bundle.main.url(forResource: sound.fileName, withExtension: "wav")
            if soundURL != nil {
                print("✅ 방법 3 (main bundle): 파일 찾음")
            }
        }

        // 방법 4: 프로젝트 디렉토리에서 직접 찾기
        if soundURL == nil {
            let fileManager = FileManager.default
            if let resourcePath = Bundle.main.resourcePath {
                // 여러 경로 시도
                let paths = [
                    (resourcePath as NSString).appendingPathComponent("Resources/\(sound.fileName).wav"),
                    (resourcePath as NSString).appendingPathComponent("\(sound.fileName).wav"),
                    (resourcePath as NSString).deletingLastPathComponent.appending("/Resources/\(sound.fileName).wav")
                ]

                for path in paths {
                    if fileManager.fileExists(atPath: path) {
                        soundURL = URL(fileURLWithPath: path)
                        print("✅ 방법 4 (직접 경로): 파일 찾음 - \(path)")
                        break
                    }
                }
            }
        }

        guard let finalURL = soundURL else {
            print("❌ 사운드 파일을 찾을 수 없음: \(sound.fileName).wav")
            print("📁 Bundle path: \(Bundle.main.bundlePath)")
            print("📁 Resource path: \(Bundle.main.resourcePath ?? "nil")")

            // 디버깅: Resources 폴더 내용 확인
            if let resourcePath = Bundle.main.resourcePath {
                let resourcesDir = (resourcePath as NSString).appendingPathComponent("Resources")
                if let files = try? FileManager.default.contentsOfDirectory(atPath: resourcesDir) {
                    print("📂 Resources 폴더 내용: \(files)")
                }
            }
            return
        }

        print("✅ 사운드 파일 찾음: \(finalURL.path)")

        do {
            let player = try AVAudioPlayer(contentsOf: finalURL)
            player.isMeteringEnabled = true // 메터링 활성화
            player.numberOfLoops = -1 // 무한 반복 재생 🔁
            player.prepareToPlay()
            player.volume = 1.0
            player.play()

            audioPlayers[sound.position] = player
            print("🎵 재생 시작: \(sound.fileName) (Loop: ♾️)")
        } catch {
            print("❌ 오디오 재생 실패: \(error.localizedDescription)")
        }
    }

    // 재생 중인지 확인
    func isPlaying(at position: Int) -> Bool {
        if let player = audioPlayers[position] {
            return player.isPlaying
        }
        return false
    }


    func stopSound(at position: Int) {
        if let player = audioPlayers[position] {
            player.stop()
            print("⏹️ 재생 정지: Position \(position)")
        }
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
