import Foundation

struct Landmark: Identifiable, Hashable {
    let id: String
    let name: String
    let matchTerms: [String]

    static let all: [Landmark] = [
        Landmark(id: "cafeteria_front", name: "Cafeteria front door", matchTerms: ["cafeteria", "cafe", "cafeteria front", "front door cafeteria"]),
        Landmark(id: "library_entrance", name: "Library entrance", matchTerms: ["library", "lib"]),
        Landmark(id: "chapel_main", name: "Fisk Memorial Chapel", matchTerms: ["chapel", "memorial chapel", "fisk chapel"]),
        Landmark(id: "pj_308", name: "Park Johnson Room 308", matchTerms: ["park johnson 308", "pj 308", "room 308", "308", "3 0 8"]),
        Landmark(id: "pj_208", name: "Park Johnson Room 208", matchTerms: ["park johnson 208", "pj 208", "room 208", "208", "2 0 8"]),
        Landmark(id: "pj_lobby", name: "Park Johnson lobby", matchTerms: ["park johnson", "pj", "park johnson lobby", "lobby"])
    ]

    static func match(from transcription: String) -> Landmark? {
        let raw = transcription.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !raw.isEmpty else { return nil }
        let words = raw.split(separator: " ").map(String.init)

        return all
            .map { landmark in (landmark: landmark, score: scoreMatch(input: raw, words: words, landmark: landmark)) }
            .filter { $0.score > 0 }
            .max { $0.score < $1.score }?
            .landmark
    }

    private static func scoreMatch(input: String, words: [String], landmark: Landmark) -> Int {
        let name = landmark.name.lowercased()
        if input.contains(name) || name.contains(input) { return 100 }

        for term in landmark.matchTerms {
            let normalized = term.lowercased()
            if input.contains(normalized) || normalized.contains(input) { return 80 }
            if words.contains(where: { normalized.contains($0) || $0.contains(normalized) }) { return 60 }
        }

        if name.split(separator: " ").contains(where: { input.contains($0) }) { return 40 }
        return 0
    }
}
