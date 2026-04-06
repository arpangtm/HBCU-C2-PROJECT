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

    func speak(_ text: String, interrupt: Bool = false, language: String = AVSpeechSynthesisVoice.currentLanguageCode()) {
        DispatchQueue.main.async {
            if interrupt, self.synthesizer.isSpeaking {
                self.synthesizer.stopSpeaking(at: .immediate)
            }
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = AVSpeechSynthesisVoice(language: language)
            utterance.rate = AVSpeechUtteranceDefaultSpeechRate
            utterance.pitchMultiplier = 1.0
            utterance.volume = 1.0
            self.synthesizer.speak(utterance)
        }
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}
