import SwiftUI

struct RequestHelpView: View {
    var body: some View {
        SupportPlaceholderScreen(
            title: "Request Help",
            systemImage: "person.wave.2.fill",
            message: "Request Help is coming soon. Return to the home screen to choose another option.",
            screenIdentifier: "requestHelp.screen"
        )
    }
}
