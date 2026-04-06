import AVFoundation
import SwiftUI

struct CameraCaptureScreen: View {
    let title: String
    let prompt: String
    let demoNote: String
    let introSpeech: String

    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel: CameraCaptureViewModel

    init(
        title: String,
        prompt: String,
        demoNote: String,
        introSpeech: String,
        mode: MockAnalysisMode
    ) {
        self.title = title
        self.prompt = prompt
        self.demoNote = demoNote
        self.introSpeech = introSpeech
        _viewModel = StateObject(wrappedValue: CameraCaptureViewModel(mode: mode))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerCard
                previewCard
                controlsCard

                if let result = viewModel.result {
                    resultCard(for: result)
                } else if let errorMessage = viewModel.errorMessage {
                    messageCard(
                        title: "Camera Message",
                        icon: "exclamationmark.triangle.fill",
                        tint: .yellow,
                        text: errorMessage
                    )
                }
            }
            .padding(20)
        }
        .background(Color.black.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.prepareCamera()
            SpeechManager.shared.speak(introSpeech, interrupt: true)
        }
        .onDisappear {
            viewModel.setSessionActive(false)
            SpeechManager.shared.stop()
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                viewModel.prepareCamera()
                viewModel.setSessionActive(true)
            default:
                viewModel.setSessionActive(false)
            }
        }
        .onChange(of: viewModel.result) { _, result in
            guard let result else { return }
            SpeechManager.shared.speak(result.spokenMessage, interrupt: true)
        }
        .onChange(of: viewModel.errorMessage) { _, message in
            guard let message else { return }
            SpeechManager.shared.speak(message, interrupt: true)
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
            Text(prompt)
                .font(.body)
                .foregroundStyle(.white.opacity(0.88))
            Text(demoNote)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.yellow.opacity(0.95))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
    }

    private var previewCard: some View {
        ZStack {
            Group {
                switch viewModel.authorizationState {
                case .authorized:
                    if viewModel.usesMockPreview {
                        MockCameraPlaceholderView()
                    } else {
                        CameraPreviewView(session: viewModel.session)
                    }
                case .checking:
                    statusPlaceholder(
                        icon: "camera.metering.center.weighted",
                        title: "Getting Camera Ready",
                        detail: "Please wait while we prepare the camera."
                    )
                case .denied:
                    statusPlaceholder(
                        icon: "camera.fill.badge.ellipsis",
                        title: "Camera Access Needed",
                        detail: "Allow camera access in Settings to use this screen on your device."
                    )
                case .unavailable:
                    statusPlaceholder(
                        icon: "camera.slash.fill",
                        title: "Camera Unavailable",
                        detail: "This device cannot start the camera right now."
                    )
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 340)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

            if viewModel.isProcessing {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.black.opacity(0.58))
                    .overlay {
                        VStack(spacing: 12) {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                            Text("Analyzing...")
                                .font(.headline)
                                .foregroundStyle(.white)
                        }
                    }
            }
        }
        .overlay(alignment: .topLeading) {
            Label("Live Camera", systemImage: "camera.viewfinder")
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.black.opacity(0.55), in: Capsule())
                .foregroundStyle(.white)
                .padding(16)
        }
        .accessibilityIdentifier("camera.preview")
    }

    private var controlsCard: some View {
        VStack(spacing: 16) {
            Button {
                SpeechManager.shared.speak("Capturing photo.", interrupt: true)
                viewModel.capturePhoto()
            } label: {
                Label(viewModel.isProcessing ? "Analyzing..." : "Tap to Capture", systemImage: "camera.circle.fill")
                    .font(.title3.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(viewModel.canCapture ? Color.white : Color.gray.opacity(0.45))
                    .foregroundStyle(viewModel.canCapture ? Color.black : Color.white.opacity(0.75))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .disabled(!viewModel.canCapture)
            .accessibilityIdentifier("camera.capture")

            if viewModel.result != nil || viewModel.lastCapturedImage != nil {
                Button {
                    viewModel.retake()
                    SpeechManager.shared.speak("Ready for another photo.", interrupt: true)
                } label: {
                    Text("Retake")
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white.opacity(0.08))
                        .foregroundStyle(.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .accessibilityIdentifier("camera.retake")
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
    }

    private func resultCard(for result: MockAnalysisResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Detected Result", systemImage: "speaker.wave.2.fill")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
            Text(result.title)
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
                .accessibilityIdentifier("camera.result.title")
            Text(result.spokenMessage)
                .font(.body)
                .foregroundStyle(.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(red: 0.10, green: 0.36, blue: 0.24))
        )
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("camera.result.card")
    }

    private func messageCard(title: String, icon: String, tint: Color, text: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.headline.weight(.semibold))
                .foregroundStyle(tint)
            Text(text)
                .font(.body)
                .foregroundStyle(.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
    }

    private func statusPlaceholder(icon: String, title: String, detail: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(.white)
            Text(title)
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
            Text(detail)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.82))
                .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [Color.gray.opacity(0.55), Color.black.opacity(0.92)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

private struct MockCameraPlaceholderView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.21, green: 0.23, blue: 0.33), Color(red: 0.06, green: 0.07, blue: 0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            VStack(spacing: 14) {
                Image(systemName: "camera.aperture")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundStyle(.white)
                Text("Mock Camera Preview")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                Text("UI tests use this preview instead of a real camera feed.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.84))
                    .padding(.horizontal, 20)
            }
        }
    }
}

private struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewContainerView {
        let view = PreviewContainerView()
        view.previewLayer.session = session
        return view
    }

    func updateUIView(_ uiView: PreviewContainerView, context: Context) {
        uiView.previewLayer.session = session
    }
}

private final class PreviewContainerView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        previewLayer.videoGravity = .resizeAspectFill
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
