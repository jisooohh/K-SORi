import SwiftUI

enum Constants {
    // 색상 컨셉
    enum Colors {
        static let yellow = Color(red: 1.0, green: 0.85, blue: 0.2)  // 노랑 - 여운 (멜로디)
        static let red = Color(red: 0.95, green: 0.2, blue: 0.2)     // 빨강 - 리듬 (장단)
        static let blue = Color(red: 0.2, green: 0.5, blue: 0.9)     // 파랑 - 흐름 (베이스)
        static let white = Color.white                                 // 하양 - 바람 (보컬)
        static let black = Color(red: 0.15, green: 0.15, blue: 0.15)  // 검정 - 장식 (타악)

        static let background = Color(red: 0.05, green: 0.05, blue: 0.1)
        static let cardBackground = Color(red: 0.1, green: 0.1, blue: 0.15)
    }

    // 사운드 카테고리
    enum SoundCategory: String, CaseIterable {
        case rhythm = "Rhythm"      // 장단
        case percussion = "Percussion" // 타악
        case melody = "Melody"      // 관현
        case voice = "Voice"        // 성악
        case base = "Base"          // 화성/공간

        var color: Color {
            switch self {
            case .rhythm: return Colors.red
            case .percussion: return Colors.black
            case .melody: return Colors.yellow
            case .voice: return Colors.white
            case .base: return Colors.blue
            }
        }

        var description: String {
            switch self {
            case .rhythm: return "리듬 (장단)"
            case .percussion: return "장식 (징, 꽹가리)"
            case .melody: return "여운 (멜로디)"
            case .voice: return "바람 (보컬)"
            case .base: return "흐름 (베이스)"
            }
        }
    }

    // 그리드 설정
    static let gridSize = 5
    static let totalPads = gridSize * gridSize
}
