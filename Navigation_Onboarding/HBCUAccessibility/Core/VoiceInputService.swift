//
//  VoiceInputService.swift
//  HBCUAccessibility
//
//  Speech-to-text for name and student ID. Uses device microphone and Speech framework.
//

import AVFoundation
import Speech
import SwiftUI

final class VoiceInputService: ObservableObject {
    @Published var isListening = false
    @Published var recognizedText = ""
    @Published var authorizationStatus: String = "unknown" // "authorized", "denied", "restricted", "notDetermined"

    private var audioEngine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    self?.authorizationStatus = "authorized"
                    self?.requestMicPermission(completion: completion)
                case .denied:
                    self?.authorizationStatus = "denied"
                    completion(false)
                case .restricted:
                    self?.authorizationStatus = "restricted"
                    completion(false)
                case .notDetermined:
                    self?.authorizationStatus = "notDetermined"
                    completion(false)
                @unknown default:
                    completion(false)
                }
            }
        }
    }

    private func requestMicPermission(completion: @escaping (Bool) -> Void) {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    func startListening(completion: @escaping (String) -> Void) {
        guard speechRecognizer?.isAvailable == true else {
            completion("")
            return
        }

        stopListening()

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            completion("")
            return
        }

        request = SFSpeechAudioBufferRecognitionRequest()
        guard let request = request else { completion(""); return }
        request.shouldReportPartialResults = true

        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else { completion(""); return }

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak request] buffer, _ in
            request?.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            completion("")
            return
        }

        isListening = true
        recognizedText = ""

        var didComplete = false
        let finish: (String) -> Void = { [weak self] text in
            guard !didComplete else { return }
            didComplete = true
            self?.stopListening()
            DispatchQueue.main.async {
                self?.recognizedText = text
                completion(text)
            }
        }

        let timeoutSeconds = 6.0
        let timeoutWork = DispatchWorkItem { [weak self] in
            let partial = self?.recognizedText ?? ""
            finish(partial.isEmpty ? "" : partial)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + timeoutSeconds, execute: timeoutWork)

        task = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
            DispatchQueue.main.async {
                if let result = result {
                    let text = result.bestTranscription.formattedString.trimmingCharacters(in: .whitespacesAndNewlines)
                    self?.recognizedText = text
                    if result.isFinal && !text.isEmpty {
                        timeoutWork.cancel()
                        finish(text)
                    }
                }
                if error != nil {
                    timeoutWork.cancel()
                    finish(self?.recognizedText ?? "")
                }
            }
        }
    }

    func stopListening() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        audioEngine = nil
        request = nil
        task = nil
        isListening = false
    }
}
