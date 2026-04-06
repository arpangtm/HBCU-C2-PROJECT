import Foundation

struct ADAComplianceReport: Identifiable, Equatable {
    static let campusReportLatitude = 36.16776
    static let campusReportLongitude = -86.77878

    let id: UUID
    let timestamp: Date
    let latitude: Double
    let longitude: Double
    let hasPhoto: Bool
    let summary: String

    init(summary: String, hasPhoto: Bool) {
        id = UUID()
        timestamp = Date()
        latitude = Self.campusReportLatitude
        longitude = Self.campusReportLongitude
        self.hasPhoto = hasPhoto
        self.summary = summary
    }

    var coordinateText: String {
        String(format: "%.5f, %.5f", latitude, longitude)
    }

    var shortIdentifier: String {
        String(id.uuidString.prefix(8))
    }
}
