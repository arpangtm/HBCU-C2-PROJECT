import AVFoundation
import Combine
import Speech

final class VoiceInputService: ObservableObject {
    @Published var isListening = false
    @Published var recognizedText = ""
    @Published var authorizationStatus = "unknown"

    private var audioEngine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var timeoutWork: DispatchWorkItem?
    private var completionHandler: ((String) -> Void)?
    private var didCompleteCurrentSession = false
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    self?.authorizationStatus = "authorized"
                    self?.requestMicrophonePermission(completion: completion)
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
                    self?.authorizationStatus = "unknown"
                    completion(false)
                }
            }
        }
    }

    func startListening(completion: @escaping (String) -> Void) {
        guard speechRecognizer?.isAvailable == true else {
            completion("")
            return
        }

        stopListening()

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            completion("")
            return
        }

        let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest.shouldReportPartialResults = true
        request = recognitionRequest

        let engine = AVAudioEngine()
        audioEngine = engine

        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak recognitionRequest] buffer, _ in
            recognitionRequest?.append(buffer)
        }

        engine.prepare()
        do {
            try engine.start()
        } catch {
            completion("")
            return
        }

        isListening = true
        recognizedText = ""
        completionHandler = completion
        didCompleteCurrentSession = false

        let timeoutWork = DispatchWorkItem { [weak self] in
            self?.finishListening(with: self?.recognizedText ?? "")
        }
        self.timeoutWork = timeoutWork
        DispatchQueue.main.asyncAfter(deadline: .now() + 6, execute: timeoutWork)

        task = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            DispatchQueue.main.async {
                if let result {
                    let text = result.bestTranscription.formattedString.trimmingCharacters(in: .whitespacesAndNewlines)
                    self?.recognizedText = text
                    if result.isFinal {
                        self?.finishListening(with: text)
                    }
                }

                if error != nil {
                    self?.finishListening(with: self?.recognizedText ?? "")
                }
            }
        }
    }

    @discardableResult
    func finishListening() -> String {
        let text = recognizedText.trimmingCharacters(in: .whitespacesAndNewlines)
        finishListening(with: text)
        return text
    }

    func stopListening() {
        timeoutWork?.cancel()
        timeoutWork = nil
        completionHandler = nil
        didCompleteCurrentSession = true
        stopAudio()
    }

    private func finishListening(with text: String) {
        guard !didCompleteCurrentSession else { return }
        didCompleteCurrentSession = true
        timeoutWork?.cancel()
        timeoutWork = nil
        stopAudio()

        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        recognizedText = cleaned
        let completion = completionHandler
        completionHandler = nil
        completion?(cleaned)
    }

    private func stopAudio() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        audioEngine = nil
        request = nil
        task = nil
        isListening = false
    }

    private func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        AVAudioApplication.requestRecordPermission { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
}
