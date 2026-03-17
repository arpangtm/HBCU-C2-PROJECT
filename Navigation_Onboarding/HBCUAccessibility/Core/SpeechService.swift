//
//  SpeechService.swift
//  HBCUAccessibility
//
//  In-app TTS. Use for all spoken guidance (onboarding, navigation). Works alongside VoiceOver.
//

import AVFoundation
import SwiftUI

final class SpeechService: ObservableObject {
    static let shared = SpeechService()
    private let synthesizer = AVSpeechSynthesizer()

    /// Speak after a short delay so VoiceOver can finish if needed.
    func speak(_ text: String, delay: TimeInterval = 0.4) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?._speak(text)
        }
    }

    func speakImmediately(_ text: String) {
        _speak(text)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    private func _speak(_ text: String) {
        guard !text.isEmpty else { return }
        stop()
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.88
        utterance.pitchMultiplier = 1.0
        synthesizer.speak(utterance)
    }
}
