//
//  HBCUAccessibilityApp.swift
//  HBCUAccessibility
//

import SwiftUI

@main
struct HBCUAccessibilityApp: App {
    @StateObject private var appState = AppState.shared

    var body: some Scene {
        WindowGroup {
            MainContainerView()
                .environmentObject(appState)
        }
    }
}
