//
//  AccessAbilityApp.swift
//  AccessAbility
//
//  Created by Rohan Ray Yadav on 4/6/26.
//

import SwiftUI

@main
struct AccessAbilityApp: App {
    @StateObject private var appState = AppState.shared

    var body: some Scene {
        WindowGroup {
            AccessAbilityRootView()
                .environmentObject(appState)
        }
    }
}
