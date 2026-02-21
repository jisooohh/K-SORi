import Foundation

struct SoundPad {
    var sounds: [Sound]

    init() {
        self.sounds = SoundPad.createDefaultSounds()
    }

    // 버튼 배치: M(6), P(6), R(5), V(4), B(4) = 25개
    //
    // Row 0 (pos 0-4)  : M M M M M       ← 해금 5개
    // Row 1 (pos 5-9)  : P P P P P       ← 소리북 5개
    // Row 2 (pos 10-14): R R R R R       ← 장구 5개
    // Row 3 (pos 15-19): V V M V V       ← 부채 4개 + 해금(borrowed) at col 2
    // Row 4 (pos 20-24): B B B B P       ← 거문고 4개 + 소리북(borrowed) at col 4
    static func createDefaultSounds() -> [Sound] {
        let soundFiles = [
            "sound0",  "sound1",  "sound2",  "sound3",  "sound4",   // Row 0
            "sound5",  "sound6",  "sound7",  "sound8",  "sound9",   // Row 1
            "sound10", "sound11", "sound14", "sound20", "sound0",   // Row 2
            "sound1",  "sound2",  "sound3",  "sound4",  "sound5",   // Row 3
            "sound6",  "sound7",  "sound8",  "sound9",  "sound10"   // Row 4
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
            // Row 4 – B ×4 + 1 borrowed P at col 4 (position 24)
            .base, .base, .base, .base, .percussion
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
