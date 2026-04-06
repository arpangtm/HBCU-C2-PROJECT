import SwiftUI

struct ReadSignsView: View {
    var body: some View {
        CameraCaptureScreen(
            title: "Read Signs",
            prompt: "Point the camera at a street sign, then tap the capture button to hear what it says.",
            demoNote: "Reads text from street signs using the camera. This feature is useful for visually impaired users to navigate and understand their surroundings.",
            introSpeech: "Read Signs. Point the camera at a street sign and tap capture to hear the result.",
            mode: .sign
        )
        .accessibilityIdentifier("readSigns.screen")
    }
}
