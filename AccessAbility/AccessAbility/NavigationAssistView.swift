//
//  NavigationAssistView.swift
//  AccessAbility
//
//  Created by Assistant on 4/6/26.
//

import SwiftUI

struct NavigationAssistView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 24) {
                Text("Navigation")
                    .font(.largeTitle).bold()
                    .foregroundStyle(.white)
                    .accessibilityAddTraits(.isHeader)
                Text("Coming soon. Use top-left to return.")
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding()
        }
        .onAppear { SpeechManager.shared.speak("Navigation. Coming soon.", interrupt: true) }
    }
}

#Preview { NavigationAssistView() }
