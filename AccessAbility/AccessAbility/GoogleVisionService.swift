//
//  GoogleVisionService.swift
//  AccessAbility
//
//  Created by Assistant on 4/6/26.
//

import Foundation
import UIKit

struct GoogleVisionService {
    enum VisionError: Error, LocalizedError {
        case apiKeyMissing
        case invalidResponse
        case server(String)

        var errorDescription: String? {
            switch self {
            case .apiKeyMissing: return "Missing Google Vision API key."
            case .invalidResponse: return "Invalid response from server."
            case .server(let message): return message
            }
        }
    }

    private static var apiKey: String? {
        // Read from Info.plist key "GOOGLE_VISION_API_KEY"
        Bundle.main.object(forInfoDictionaryKey: "GOOGLE_VISION_API_KEY") as? String
    }

    struct Annotation: Decodable {
        let description: String?
        let score: Double?
    }

    struct APIResponse: Decodable {
        struct Response: Decodable {
            let labelAnnotations: [Annotation]? // for object labels
            let localizedObjectAnnotations: [LocalizedObject]? // if object localization is enabled
            let error: APIError?
        }
        struct LocalizedObject: Decodable { let name: String?; let score: Double? }
        struct APIError: Decodable { let message: String? }
        let responses: [Response]
    }

    static func classify(image: UIImage) async throws -> String {
        guard let key = apiKey, !key.isEmpty else { throw VisionError.apiKeyMissing }
        guard let jpegData = image.jpegData(compressionQuality: 0.8) else { throw VisionError.invalidResponse }
        let base64 = jpegData.base64EncodedString()

        // Request: LABEL_DETECTION + OBJECT_LOCALIZATION
        let body: [String: Any] = [
            "requests": [[
                "image": ["content": base64],
                "features": [
                    ["type": "LABEL_DETECTION", "maxResults": 5],
                    ["type": "OBJECT_LOCALIZATION", "maxResults": 5]
                ]
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
            throw VisionError.server(serverMessage)
        }

        let decoded = try JSONDecoder().decode(APIResponse.self, from: data)
        guard let first = decoded.responses.first else { throw VisionError.invalidResponse }
        if let err = first.error?.message { throw VisionError.server(err) }

        var parts: [String] = []
        if let objs = first.localizedObjectAnnotations, !objs.isEmpty {
            let objectNames = objs.compactMap { $0.name }.prefix(3)
            if !objectNames.isEmpty { parts.append("Objects: " + objectNames.joined(separator: ", ")) }
        }
        if let labels = first.labelAnnotations, !labels.isEmpty {
            let labelNames = labels.compactMap { $0.description }.prefix(3)
            if !labelNames.isEmpty { parts.append("Labels: " + labelNames.joined(separator: ", ")) }
        }
        return parts.isEmpty ? "I couldn't recognize the object." : parts.joined(separator: ". ")
    }
}
