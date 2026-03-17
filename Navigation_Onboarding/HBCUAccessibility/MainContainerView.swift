//
//  MainContainerView.swift
//  HBCUAccessibility
//

import SwiftUI

struct MainContainerView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            // Demo mode: always show onboarding first.
            // On completion, onboarding will push the user into the app for this run,
            // but we don't persist skipping onboarding across relaunches.
            OnboardingView()
        }
    }
}

#Preview {
    MainContainerView()
        .environmentObject(AppState.shared)
}
