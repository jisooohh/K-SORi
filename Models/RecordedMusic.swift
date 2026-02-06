import Foundation

struct RecordedMusic: Identifiable, Codable {
    let id: UUID
    var name: String
    let recordedDate: Date
    let duration: Double
    let fileName: String // 저장된 파일명

    init(id: UUID = UUID(), name: String, recordedDate: Date = Date(), duration: Double, fileName: String) {
        self.id = id
        self.name = name
        self.recordedDate = recordedDate
        self.duration = duration
        self.fileName = fileName
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: recordedDate)
    }

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
