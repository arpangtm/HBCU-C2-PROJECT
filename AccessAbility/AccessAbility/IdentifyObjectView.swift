import SwiftUI

struct IdentifyObjectView: View {
    var body: some View {
        CameraCaptureScreen(
            title: "Identify Object",
            prompt: "Point the camera at an item, then tap the capture button to hear the result.",
            demoNote: "Identifies objects in the environment using the camera. This feature is helpful for visually impaired users to understand their surroundings.",
            introSpeech: "Identify Object. Point the camera at an item and tap capture to hear the result.",
            mode: .object
        )
        .accessibilityIdentifier("identifyObject.screen")
    }
}
