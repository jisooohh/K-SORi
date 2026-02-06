import Foundation

struct SoundPad {
    var sounds: [Sound]

    init() {
        self.sounds = SoundPad.createDefaultSounds()
    }

    // 기본 사운드 패드 구성 (5x5 = 25개)
    // 실제 음원 파일이 추가되면 fileName을 업데이트해야 합니다
    static func createDefaultSounds() -> [Sound] {
        var sounds: [Sound] = []

        // Row 0: Rhythm (빨강)
        for col in 0..<5 {
            sounds.append(Sound(
                name: "장단\(col + 1)",
                fileName: "rhythm_\(col + 1)",
                category: .rhythm,
                duration: 2.0,
                position: col
            ))
        }

        // Row 1: Percussion (검정)
        for col in 0..<5 {
            sounds.append(Sound(
                name: "타악\(col + 1)",
                fileName: "percussion_\(col + 1)",
                category: .percussion,
                duration: 1.0,
                position: 5 + col
            ))
        }

        // Row 2: Melody (노랑)
        for col in 0..<5 {
            sounds.append(Sound(
                name: "관현\(col + 1)",
                fileName: "melody_\(col + 1)",
                category: .melody,
                duration: 3.0,
                position: 10 + col
            ))
        }

        // Row 3: Voice (하양)
        for col in 0..<5 {
            sounds.append(Sound(
                name: "성악\(col + 1)",
                fileName: "voice_\(col + 1)",
                category: .voice,
                duration: 2.5,
                position: 15 + col
            ))
        }

        // Row 4: Base (파랑)
        for col in 0..<5 {
            sounds.append(Sound(
                name: "베이스\(col + 1)",
                fileName: "base_\(col + 1)",
                category: .base,
                duration: 4.0,
                position: 20 + col
            ))
        }

        return sounds
    }

    func sound(at position: Int) -> Sound? {
        sounds.first { $0.position == position }
    }
}
