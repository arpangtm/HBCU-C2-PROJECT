//
//  SpeechManager.swift
//  AccessAbility
//
//  Created by Assistant on 4/6/26.
//

import Foundation
import AVFoundation

@MainActor
final class SpeechManager: NSObject, AVSpeechSynthesizerDelegate {
    static let shared = SpeechManager()

    private let synthesizer = AVSpeechSynthesizer()
    private override init() {
        super.init()
        synthesizer.delegate = self
        configureAudioSession()
    }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            // Playback so speech is audible even in silent mode. Duck other audio.
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true, options: [])
        } catch {
            #if DEBUG
            print("Audio session error: \(error)")
            #endif
        }
    }

    func speak(
        _ text: String,
        interrupt: Bool = false,
        language: String = AVSpeechSynthesisVoice.currentLanguageCode(),
        delay: TimeInterval = 0
    ) {
        if delay > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.performSpeak(text, interrupt: interrupt, language: language)
            }
        } else {
            performSpeak(text, interrupt: interrupt, language: language)
        }
    }

    func speakImmediately(_ text: String) {
        speak(text, interrupt: true, delay: 0)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    private func performSpeak(_ text: String, interrupt: Bool, language: String) {
        configureAudioSession()
        if interrupt, synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .word)
        }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = preferredVoice(for: language)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.92
        utterance.pitchMultiplier = 1.04
        utterance.volume = 1.0
        synthesizer.speak(utterance)
    }

    private func preferredVoice(for language: String) -> AVSpeechSynthesisVoice? {
        let languagePrefix = language.split(separator: "-").first.map(String.init) ?? "en"
        let voices = AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix(languagePrefix) }

        if let premiumVoice = voices.first(where: { $0.quality == .premium }) {
            return premiumVoice
        }

        if let enhancedVoice = voices.first(where: { $0.quality == .enhanced }) {
            return enhancedVoice
        }

        if let preferredName = voices.first(where: { ["Ava", "Samantha", "Nicky", "Allison"].contains($0.name) }) {
            return preferredName
        }

        return AVSpeechSynthesisVoice(language: language)
    }
}
