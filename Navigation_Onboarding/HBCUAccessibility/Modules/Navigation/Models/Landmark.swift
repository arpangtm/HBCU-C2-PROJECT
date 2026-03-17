//
//  Landmark.swift
//  HBCUAccessibility
//
//  Named places for indoor nav. matchTerms used to match voice transcription.
//

import Foundation

struct Landmark: Identifiable, Hashable {
    let id: String
    let name: String
    /// Terms we match against (e.g. "cafeteria", "cafe", "park johnson 308", "pj 308").
    let matchTerms: [String]

    static let all: [Landmark] = [
        Landmark(id: "cafeteria_front", name: "Cafeteria front door", matchTerms: ["cafeteria", "cafe", "cafeteria front", "front door cafeteria"]),
        Landmark(id: "library_entrance", name: "Library entrance", matchTerms: ["library", "lib"]),
        Landmark(id: "chapel_main", name: "Fisk Memorial Chapel", matchTerms: ["chapel", "memorial chapel", "fisk chapel"]),
        Landmark(id: "pj_308", name: "Park Johnson Room 308", matchTerms: ["park johnson 308", "pj 308", "room 308", "308", "3 0 8"]),
        Landmark(id: "pj_208", name: "Park Johnson Room 208", matchTerms: ["park johnson 208", "pj 208", "room 208", "208", "2 0 8"]),
        Landmark(id: "pj_lobby", name: "Park Johnson lobby", matchTerms: ["park johnson", "pj", "park johnson lobby", "lobby"]),
    ]

    /// Match voice transcription to closest landmark. Returns nil if no good match.
    static func match(from transcription: String) -> Landmark? {
        let raw = transcription.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !raw.isEmpty else { return nil }
        let words = raw.split(separator: " ").map(String.init)
        var best: (landmark: Landmark, score: Int)?
        for landmark in all {
            let score = scoreMatch(input: raw, words: words, landmark: landmark)
            if score > 0, best == nil || score > best!.score {
                best = (landmark, score)
            }
        }
        return best?.landmark
    }

    private static func scoreMatch(input: String, words: [String], landmark: Landmark) -> Int {
        let nameLower = landmark.name.lowercased()
        if input.contains(nameLower) || nameLower.contains(input) { return 100 }
        for term in landmark.matchTerms {
            let t = term.lowercased()
            if input.contains(t) || t.contains(input) { return 80 }
            if words.contains(where: { t.contains($0) || $0.contains(t) }) { return 60 }
        }
        if nameLower.split(separator: " ").contains(where: { input.contains($0) }) { return 40 }
        return 0
    }
}
