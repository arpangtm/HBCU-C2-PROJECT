import SwiftUI

struct AccessAbilityRootView: View {
    @EnvironmentObject private var appState: AppState
    @State private var hasCompletedSessionOnboarding: Bool

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        _hasCompletedSessionOnboarding = State(initialValue: arguments.contains("-skip-onboarding"))
    }

    var body: some View {
        Group {
            if hasCompletedSessionOnboarding {
                ContentView()
            } else {
                OnboardingView { name, studentId in
                    appState.completeOnboarding(name: name, studentId: studentId)
                    hasCompletedSessionOnboarding = true
                }
            }
        }
    }
}

#Preview {
    AccessAbilityRootView()
        .environmentObject(AppState.shared)
}
