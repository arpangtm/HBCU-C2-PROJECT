import Foundation

enum VisionAnalysisMode: Hashable {
    case object
    case sign
    case scan
    case adaCompliance
}

struct VisionAnalysisResult: Equatable {
    let title: String
    let spokenMessage: String
}

protocol AnalyzingService {
    func analyze(mode: VisionAnalysisMode) async -> VisionAnalysisResult
}

final class LocalVisionAnalyzingService: AnalyzingService {
    private let delayNanoseconds: UInt64
    private var scanCaptureCount = 0
    private var adaCaptureCount = 0

    init(delayNanoseconds: UInt64 = 900_000_000) {
        self.delayNanoseconds = delayNanoseconds
    }

    func analyze(mode: VisionAnalysisMode) async -> VisionAnalysisResult {
        if delayNanoseconds > 0 {
            try? await Task.sleep(nanoseconds: delayNanoseconds)
        }

        switch mode {
        case .object:
            return VisionAnalysisResult(
                title: "Bottle",
                spokenMessage: "This is a bottle."
            )
        case .sign:
            return VisionAnalysisResult(
                title: "17th Avenue",
                spokenMessage: "The visible text reads 17th Avenue."
            )
        case .scan:
            scanCaptureCount += 1
            switch (scanCaptureCount - 1) % 3 {
            case 0:
                return VisionAnalysisResult(
                    title: "Homework Due April 10th",
                    spokenMessage: "The white board says homework is due April 10th."
                )
            case 1:
                return VisionAnalysisResult(
                    title: "Bottle",
                    spokenMessage: "The object is bottle."
                )
            default:
                return VisionAnalysisResult(
                    title: "Bus Stop",
                    spokenMessage: "The sign is Bus Stop."
                )
            }
        case .adaCompliance:
            adaCaptureCount += 1
            switch (adaCaptureCount - 1) % 2 {
            case 0:
                return VisionAnalysisResult(
                    title: "Obstacle Detected",
                    spokenMessage: "Obstacle detected, accessibility barrier reported to the university."
                )
            default:
                return VisionAnalysisResult(
                    title: "Inconsistent Desk Arrangement",
                    spokenMessage: "Inconsistent desk arrangement detected in the classroom and reported to the university."
                )
            }
        }
    }
}
