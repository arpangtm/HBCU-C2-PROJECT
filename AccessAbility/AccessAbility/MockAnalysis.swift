import Foundation

enum MockAnalysisMode: Equatable {
    case object
    case sign
}

struct MockAnalysisResult: Equatable {
    let title: String
    let spokenMessage: String
}

protocol AnalyzingService {
    func analyze(mode: MockAnalysisMode) async -> MockAnalysisResult
}

final class MockAnalyzingService: AnalyzingService {
    private let delayNanoseconds: UInt64

    init(delayNanoseconds: UInt64 = 900_000_000) {
        self.delayNanoseconds = delayNanoseconds
    }

    func analyze(mode: MockAnalysisMode) async -> MockAnalysisResult {
        if delayNanoseconds > 0 {
            try? await Task.sleep(nanoseconds: delayNanoseconds)
        }

        switch mode {
        case .object:
            return MockAnalysisResult(
                title: "Bottle",
                spokenMessage: "This is a bottle."
            )
        case .sign:
            return MockAnalysisResult(
                title: "17th Avenue",
                spokenMessage: "The street sign says 17th Avenue."
            )
        }
    }
}
