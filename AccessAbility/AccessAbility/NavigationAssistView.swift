import SwiftUI

struct NavigationAssistView: View {
    var body: some View {
        SupportPlaceholderScreen(
            title: "Navigation",
            systemImage: "location.circle.fill",
            message: "Navigation support is coming soon. Return to the home screen to choose another option.",
            screenIdentifier: "navigation.screen"
        )
    }
}
