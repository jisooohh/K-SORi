import Foundation

struct SoundPad {
    var sounds: [Sound]

    init() {
        self.sounds = SoundPad.createDefaultSounds()
    }

    // 실제 사운드 파일 기반 패드 구성 (5x5 = 25개)
    // 사용 가능한 파일: sound0~11, sound14, sound20
    static func createDefaultSounds() -> [Sound] {
        var sounds: [Sound] = []

        // 실제 사운드 파일 매핑 (14개)
        let soundFiles = [
            "sound0", "sound1", "sound2", "sound3", "sound4",    // Row 0 (0-4)
            "sound5", "sound6", "sound7", "sound8", "sound9",    // Row 1 (5-9)
            "sound10", "sound11", "sound14", "sound20", "sound0", // Row 2 (10-14, sound0 반복)
            "sound1", "sound2", "sound3", "sound4", "sound5",    // Row 3 (15-19, 반복)
            "sound6", "sound7", "sound8", "sound9", "sound10"    // Row 4 (20-24, 반복)
        ]

        // 카테고리 분배 (오방색 패턴)
        let categories: [Constants.SoundCategory] = [
            // Row 0
            .rhythm, .percussion, .melody, .voice, .base,
            // Row 1
            .rhythm, .percussion, .melody, .voice, .base,
            // Row 2
            .rhythm, .percussion, .melody, .voice, .base,
            // Row 3
            .rhythm, .percussion, .melody, .voice, .base,
            // Row 4
            .rhythm, .percussion, .melody, .voice, .base
        ]

        for position in 0..<25 {
            sounds.append(Sound(
                name: soundFiles[position].capitalized,
                fileName: soundFiles[position],
                category: categories[position],
                duration: 2.0, // 실제 재생 시 자동 감지됨
                position: position
            ))
        }

        return sounds
    }

    func sound(at position: Int) -> Sound? {
        sounds.first { $0.position == position }
    }
}
