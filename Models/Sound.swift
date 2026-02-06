import Foundation

struct Sound: Identifiable, Codable {
    let id: UUID
    let name: String
    let fileName: String
    let category: Constants.SoundCategory
    let duration: Double // 초 단위
    let position: Int // 0-24 (5x5 그리드)

    init(id: UUID = UUID(), name: String, fileName: String, category: Constants.SoundCategory, duration: Double, position: Int) {
        self.id = id
        self.name = name
        self.fileName = fileName
        self.category = category
        self.duration = duration
        self.position = position
    }

    // 그리드 좌표 계산
    var gridRow: Int { position / Constants.gridSize }
    var gridColumn: Int { position % Constants.gridSize }
}

extension Constants.SoundCategory: Codable {}
