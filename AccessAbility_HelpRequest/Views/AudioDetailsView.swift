import SwiftUI
import AVFoundation

struct AudioDetailsView: View {
    let category: String
    let urgency: String

    @StateObject private var audioRecorder = AudioRecorder()
    @State private var showingSubmitConfirmation = false
    @State private var isPressed = false

    var body: some View {
        ZStack {
            // Full-screen tap-and-hold area
            Color(isPressed ? .darkGray : (audioRecorder.hasRecording ? .systemGreen : .systemBlue))
                .ignoresSafeArea()
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if !isPressed {
                                isPressed = true
                                ScreenVoiceGuide.shared.stop()
                                audioRecorder.startRecording()
                            }
                        }
                        .onEnded { _ in
                            if isPressed {
                                isPressed = false
                                audioRecorder.stopRecording()
                                submitRequest()
                            }
                        }
                )

            VStack(spacing: 32) {
                Spacer()

                Image(systemName: isPressed ? "mic.fill" : (audioRecorder.hasRecording ? "checkmark.circle.fill" : "mic.circle"))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .foregroundColor(.white)
                    .scaleEffect(isPressed ? 1.3 : 1.0)
                    .animation(.easeInOut(duration: 0.15), value: isPressed)

                Text(isPressed ? "Recording... Release to send" : "Tap and hold anywhere to record")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Spacer()
            }
        }
        .navigationBarBackButtonHidden(false)
        .alert("Request Submitted", isPresented: $showingSubmitConfirmation) {
            Button("OK") { }
        } message: {
            Text("Your \(urgency.lowercased()) request for \(category.lowercased()) has been submitted.")
        }
        .onAppear {
            audioRecorder.requestPermission()
//            ScreenVoiceGuide.shared.speak(
//                "Tap and hold anywhere on the screen to say any additional things you want admins to know. Release to send the message."
//            )
        }
        .onDisappear {
            ScreenVoiceGuide.shared.stop()
        }
    }

    private func submitRequest() {
        showingSubmitConfirmation = true
        ScreenVoiceGuide.shared.speak("Your request has been submitted.")
    }
}
