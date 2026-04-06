//
//  SignDetectionService.swift
//  AccessAbility
//
//  Created by Assistant on 4/6/26.
//

import Foundation
import UIKit

struct SignDetectionService {
    enum SignError: Error, LocalizedError {
        case apiKeyMissing
        case invalidResponse
        case server(String)
        var errorDescription: String? {
            switch self {
            case .apiKeyMissing: return "Missing Google Vision API key."
            case .invalidResponse: return "Invalid response from server."
            case .server(let s): return s
            }
        }
    }

    private static var apiKey: String? { Bundle.main.object(forInfoDictionaryKey: "GOOGLE_VISION_API_KEY") as? String }

    struct APIResponse: Decodable {
        struct Response: Decodable {
            let textAnnotations: [TextAnnotation]? // OCR result
            let error: APIError?
        }
        struct TextAnnotation: Decodable { let description: String? }
        struct APIError: Decodable { let message: String? }
        let responses: [Response]
    }

    static func detectSign(in image: UIImage) async throws -> String {
        guard let key = apiKey, !key.isEmpty else { throw SignError.apiKeyMissing }
        guard let jpegData = image.jpegData(compressionQuality: 0.8) else { throw SignError.invalidResponse }
        let base64 = jpegData.base64EncodedString()

        let body: [String: Any] = [
            "requests": [[
                "image": ["content": base64],
                "features": [["type": "TEXT_DETECTION", "maxResults": 1]]
            ]]
        ]
        let jsonData = try JSONSerialization.data(withJSONObject: body, options: [])

        var request = URLRequest(url: URL(string: "https://vision.googleapis.com/v1/images:annotate?key=\(key)")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let serverMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw SignError.server(serverMessage)
        }

        let decoded = try JSONDecoder().decode(APIResponse.self, from: data)
        guard let first = decoded.responses.first else { throw SignError.invalidResponse }
        if let err = first.error?.message { throw SignError.server(err) }

        let text = first.textAnnotations?.first?.description?.lowercased() ?? ""
        if text.isEmpty { return "I couldn't read any sign." }

        // Very simple heuristic mapping for common signs. Could be replaced by a custom model later.
        let mappings: [(keywords: [String], message: String)] = [
            (["stop"], "Stop sign ahead."),
            (["slippery", "wet"], "Caution: slippery surface."),
            (["ramp"], "Ramp ahead."),
            (["exit"], "Exit sign ahead."),
            (["caution"], "Caution sign ahead."),
            (["yield"], "Yield sign ahead."),
            (["no parking"], "No parking area."),
            (["speed limit"], "Speed limit sign detected."),
        ]

        for map in mappings {
            if map.keywords.contains(where: { text.contains($0) }) {
                return map.message
            }
        }
        return "Sign reads: \(text)"
    }
}
