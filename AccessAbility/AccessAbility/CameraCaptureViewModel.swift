import AVFoundation
import Combine
import SwiftUI
import UIKit

enum CameraAuthorizationState: Equatable {
    case checking
    case authorized
    case denied
    case unavailable
}

final class CameraCaptureViewModel: NSObject, ObservableObject {
    @Published private(set) var authorizationState: CameraAuthorizationState = .checking
    @Published private(set) var isSessionReady = false
    @Published var isProcessing = false
    @Published var result: VisionAnalysisResult?
    @Published var errorMessage: String?
    @Published private(set) var lastCapturedImage: UIImage?

    let session = AVCaptureSession()
    let mode: VisionAnalysisMode
    let usesPreviewFallback: Bool

    var canCapture: Bool {
        !isProcessing && authorizationState == .authorized && (usesPreviewFallback || isSessionReady)
    }

    var hasPhotoForResult: Bool {
        usesPreviewFallback || lastCapturedImage != nil
    }

    private let analyzingService: AnalyzingService
    private let sessionQueue = DispatchQueue(label: "com.accessability.camera.session")
    private let photoOutput = AVCapturePhotoOutput()
    private var isSessionConfigured = false

    init(
        mode: VisionAnalysisMode,
        analyzingService: AnalyzingService = LocalVisionAnalyzingService(),
        usesPreviewFallback: Bool = ProcessInfo.processInfo.arguments.contains("-use-camera-preview-fallback")
    ) {
        self.mode = mode
        self.analyzingService = analyzingService
        self.usesPreviewFallback = usesPreviewFallback
        super.init()
    }

    func prepareCamera() {
        if usesPreviewFallback {
            authorizationState = .authorized
            isSessionReady = true
            errorMessage = nil
            return
        }

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureSessionIfNeeded()
        case .notDetermined:
            authorizationState = .checking
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    guard let self else { return }
                    if granted {
                        self.configureSessionIfNeeded()
                    } else {
                        self.authorizationState = .denied
                        self.isSessionReady = false
                        self.errorMessage = "Camera access is turned off. Enable it in Settings to use this screen."
                    }
                }
            }
        case .denied, .restricted:
            authorizationState = .denied
            isSessionReady = false
            errorMessage = "Camera access is turned off. Enable it in Settings to use this screen."
        @unknown default:
            authorizationState = .unavailable
            isSessionReady = false
            errorMessage = "The camera is unavailable right now."
        }
    }

    func setSessionActive(_ isActive: Bool) {
        guard !usesPreviewFallback, isSessionConfigured else { return }

        sessionQueue.async { [weak self] in
            guard let self else { return }
            if isActive {
                if !self.session.isRunning {
                    self.session.startRunning()
                }
            } else if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }

    func capturePhoto() {
        guard !isProcessing else { return }
        errorMessage = nil
        result = nil

        if usesPreviewFallback {
            lastCapturedImage = nil
            runCameraAnalysisFallback()
            return
        }

        guard canCapture else {
            errorMessage = "Camera is not ready yet. Please wait a moment and try again."
            return
        }

        isProcessing = true
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .off
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    func retake() {
        result = nil
        errorMessage = nil
        lastCapturedImage = nil
    }

    private func configureSessionIfNeeded() {
        guard !usesPreviewFallback else { return }

        if isSessionConfigured {
            authorizationState = .authorized
            isSessionReady = true
            errorMessage = nil
            setSessionActive(true)
            return
        }

        sessionQueue.async { [weak self] in
            guard let self else { return }

            self.session.beginConfiguration()
            self.session.sessionPreset = .photo

            do {
                guard
                    let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
                else {
                    throw CameraSetupError.cameraUnavailable
                }

                let input = try AVCaptureDeviceInput(device: camera)
                guard self.session.canAddInput(input), self.session.canAddOutput(self.photoOutput) else {
                    throw CameraSetupError.configurationFailed
                }

                self.session.addInput(input)
                self.session.addOutput(self.photoOutput)
                self.photoOutput.maxPhotoQualityPrioritization = .balanced
                self.session.commitConfiguration()
                self.isSessionConfigured = true
                self.session.startRunning()

                DispatchQueue.main.async {
                    self.authorizationState = .authorized
                    self.isSessionReady = true
                    self.errorMessage = nil
                }
            } catch {
                self.session.commitConfiguration()
                DispatchQueue.main.async {
                    self.authorizationState = .unavailable
                    self.isSessionReady = false
                    self.errorMessage = "The camera is unavailable on this device."
                }
            }
        }
    }

    private func runCameraAnalysisFallback() {
        isProcessing = true

        Task { @MainActor [weak self] in
            guard let self else { return }
            let analysis = await self.analyzingService.analyze(mode: self.mode)
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            self.result = analysis
            self.isProcessing = false
        }
    }
}

extension CameraCaptureViewModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if error != nil {
            DispatchQueue.main.async { [weak self] in
                self?.isProcessing = false
                self?.errorMessage = "We could not capture that photo. Please try again."
            }
            return
        }

        if
            let imageData = photo.fileDataRepresentation(),
            let image = UIImage(data: imageData)
        {
            DispatchQueue.main.async { [weak self] in
                self?.lastCapturedImage = image
            }
        }

        Task { @MainActor [weak self] in
            guard let self else { return }
            let analysis = await self.analyzingService.analyze(mode: self.mode)
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            self.result = analysis
            self.isProcessing = false
        }
    }
}

private enum CameraSetupError: Error {
    case cameraUnavailable
    case configurationFailed
}
