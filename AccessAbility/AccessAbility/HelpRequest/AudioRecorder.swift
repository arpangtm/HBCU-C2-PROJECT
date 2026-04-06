import AVFoundation
import Combine

final class AudioRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var hasRecording = false
    @Published private(set) var recordingURL: URL?

    private var audioRecorder: AVAudioRecorder?
    private let audioSession = AVAudioSession.sharedInstance()

    func requestPermission() {
        AVAudioApplication.requestRecordPermission { allowed in
            if !allowed {
                #if DEBUG
                print("Microphone permission denied")
                #endif
            }
        }
    }

    func startRecording() {
        guard !isRecording else { return }

        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioURL = documentsPath.appendingPathComponent("help-request-\(UUID().uuidString).m4a")

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            try audioSession.setActive(true)

            let recorder = try AVAudioRecorder(url: audioURL, settings: settings)
            recorder.prepareToRecord()
            recorder.record()

            audioRecorder = recorder
            recordingURL = audioURL
            isRecording = true
            hasRecording = false
        } catch {
            #if DEBUG
            print("Could not start recording: \(error.localizedDescription)")
            #endif
        }
    }

    func stopRecording() -> URL? {
        guard isRecording else { return recordingURL }

        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false
        hasRecording = true
        try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        return recordingURL
    }
}
