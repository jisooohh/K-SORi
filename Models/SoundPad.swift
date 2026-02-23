import Foundation

struct SoundPad {
    var sounds: [Sound]

    init() {
        self.sounds = SoundPad.createDefaultSounds()
    }

    // 버튼 배치: M(6), P(5), R(6), V(4), B(4) = 25개
    //
    // Row 0 (pos 0-4)  : M1 M2 M3 M4 M5     ← 해금 5개
    // Row 1 (pos 5-9)  : P1 P2 P3 P4 P5     ← 소리북 5개
    // Row 2 (pos 10-14): R1 R2 R3 R4 R5     ← 장구 5개
    // Row 3 (pos 15-19): V1 V2 M6 V3 V4     ← 부채 4개 + 해금(borrowed) at col 2
    // Row 4 (pos 20-24): B1 B2 B3 B4 R6     ← 거문고 4개 + 장구(borrowed) at col 4
    static func createDefaultSounds() -> [Sound] {
        let soundFiles = [
            "M1", "M2", "M3", "M4", "M5",   // Row 0
            "P1", "P2", "P3", "P4", "P5",   // Row 1
            "R1", "R2", "R3", "R4", "R5",   // Row 2
            "V1", "V2", "M6", "V3", "V4",   // Row 3
            "B1", "B2", "B3", "B4", "R6"    // Row 4
        ]

        let categories: [Constants.SoundCategory] = [
            // Row 0 – M (melody / 해금) ×5
            .melody, .melody, .melody, .melody, .melody,
            // Row 1 – P (percussion / 소리북) ×5
            .percussion, .percussion, .percussion, .percussion, .percussion,
            // Row 2 – R (rhythm / 장구) ×5
            .rhythm, .rhythm, .rhythm, .rhythm, .rhythm,
            // Row 3 – V ×4 + 1 borrowed M at col 2 (position 17)
            .voice, .voice, .melody, .voice, .voice,
            // Row 4 – B ×4 + 1 borrowed R at col 4 (position 24)
            .base, .base, .base, .base, .rhythm
        ]

        return (0..<25).map { position in
            Sound(
                name: soundFiles[position].capitalized,
                fileName: soundFiles[position],
                category: categories[position],
                duration: 2.0,
                position: position
            )
        }
    }

    func sound(at position: Int) -> Sound? {
        sounds.first { $0.position == position }
    }
}
