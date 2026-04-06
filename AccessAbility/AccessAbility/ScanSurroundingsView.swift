import SwiftUI

struct ScanSurroundingsView: View {
    var body: some View {
        CameraCaptureScreen(
            title: "Scan Surroundings",
            prompt: "Point at text or objects. Press capture.",
            guidanceNote: "Reads text and identifies objects.",
            introSpeech: "Scan Surroundings. Point at text or objects, then press capture.",
            mode: .scan
        )
        .accessibilityIdentifier("scanSurroundings.screen")
    }
}
