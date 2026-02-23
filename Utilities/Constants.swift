import SwiftUI

enum Constants {
    // 색상 컨셉
    enum Colors {
        static let yellow = Color(red: 1.0, green: 0.85, blue: 0.2)
        static let red    = Color(red: 0.95, green: 0.2,  blue: 0.2)
        static let blue   = Color(red: 0.2,  green: 0.5,  blue: 0.9)
        static let white  = Color.white
        static let black  = Color(red: 0.15, green: 0.15, blue: 0.15)

        static let background     = Color(red: 0.05, green: 0.05, blue: 0.1)
        static let cardBackground = Color(red: 0.1,  green: 0.1,  blue: 0.15)
    }

    // 사운드 카테고리
    enum SoundCategory: String, CaseIterable {
        case melody     = "Melody"      // M - 해금
        case percussion = "Percussion"  // P - 소리북
        case rhythm     = "Rhythm"      // R - 장구
        case voice      = "Voice"       // V - 부채
        case base       = "Base"        // B - 거문고

        // 카테고리 대표 색상
        var color: Color {
            switch self {
            case .melody:     return Colors.blue    // M
            case .percussion: return Colors.red     // P
            case .rhythm:     return Colors.yellow  // R
            case .voice:      return Colors.white   // V
            case .base:       return Colors.black   // B
            }
        }

        // 카테고리 레이블 (M/P/R/V/B)
        var categoryLetter: String {
            switch self {
            case .melody:     return "M"
            case .percussion: return "P"
            case .rhythm:     return "R"
            case .voice:      return "V"
            case .base:       return "B"
            }
        }

        // 대표 악기 이름
        var instrumentName: String {
            switch self {
            case .melody:     return "해금"
            case .percussion: return "소리북"
            case .rhythm:     return "장구"
            case .voice:      return "부채"
            case .base:       return "거문고"
            }
        }

        // 대표 악기 이름 (영문)
        var instrumentNameEnglish: String {
            switch self {
            case .melody:     return "Haegeum"
            case .percussion: return "Soribuk"
            case .rhythm:     return "Janggu"
            case .voice:      return "Buchae"
            case .base:       return "Geomungo"
            }
        }

        // 대표 악기 이미지 파일명 (Resources/)
        var instrumentImageName: String {
            switch self {
            case .melody:     return "instrument_haegeum"
            case .percussion: return "instrument_soribuk"
            case .rhythm:     return "instrument_janggu"
            case .voice:      return "instrument_buchae"
            case .base:       return "instrument_geomungo"
            }
        }

        var description: String {
            switch self {
            case .melody:     return "해금 (멜로디)"
            case .percussion: return "소리북 (타악)"
            case .rhythm:     return "장구 (장단)"
            case .voice:      return "부채 (바람)"
            case .base:       return "거문고 (베이스)"
            }
        }
    }

    // 그리드 설정
    static let gridSize  = 5
    static let totalPads = gridSize * gridSize
}
