import Foundation

struct AssistanceRequest: Identifiable, Codable {
    let id: UUID
    let category: String
    let urgency: String
    let audioFileURL: URL?
    let timestamp: Date
    
    init(category: String, urgency: String, audioFileURL: URL? = nil) {
        self.id = UUID()
        self.category = category
        self.urgency = urgency
        self.audioFileURL = audioFileURL
        self.timestamp = Date()
    }
}
