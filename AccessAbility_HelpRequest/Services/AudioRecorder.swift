import AVFoundation
import SwiftUI
import Combine

@MainActor // Ensures all UI updates happen on the main thread
class AudioRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var hasRecording = false
    
    private var audioRecorder: AVAudioRecorder?
    private let audioSession = AVAudioSession.sharedInstance()
    
    func requestPermission() {
        // Use the new AVAudioApplication API (iOS 17+)
        AVAudioApplication.requestRecordPermission { allowed in
            if !allowed {
                print("Microphone permission denied")
            }
        }
    }
    
    func startRecording() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFilename = documentsPath.appendingPathComponent("recording.m4a")
        
        // High-quality settings for M4A
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0, // Standard high quality
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            // 1. Configure Session
            try audioSession.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            try audioSession.setActive(true)
            
            // 2. Initialize Recorder
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.prepareToRecord() // Prepares hardware buffers
            audioRecorder?.record()
            
            isRecording = true
        } catch {
            print("Could not start recording: \(error.localizedDescription)")
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        hasRecording = true
        
        // Deactivate session to allow other apps to use audio
        try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)
    }
}
