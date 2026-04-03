import SwiftUI
import AVFoundation

struct AudioDetailsView: View {
    let category: String
    let urgency: String

    @StateObject private var audioRecorder = AudioRecorder()
    @State private var showingSubmitConfirmation = false
    @State private var isPressed = false

    private var statusColor: Color {
        if isPressed { return Color(.systemGray5) }
        return audioRecorder.hasRecording ? Color(.systemGreen).opacity(0.08) : Color(.systemBlue).opacity(0.06)
    }

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            Color(statusColor)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.2), value: isPressed)
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

            VStack(spacing: 24) {
                Spacer()

                Image(systemName: isPressed ? "mic.fill" : (audioRecorder.hasRecording ? "checkmark.circle" : "mic.circle"))
                    .font(.system(size: 80, weight: .light))
                    .foregroundColor(isPressed ? .primary : (audioRecorder.hasRecording ? Color(.systemGreen) : .accentColor))
                    .scaleEffect(isPressed ? 1.15 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)

                Text(isPressed ? "Recording… Release to send" : "Hold anywhere to record")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Text(isPressed ? "" : "Tap and hold anywhere on screen")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .animation(.easeInOut, value: isPressed)

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
