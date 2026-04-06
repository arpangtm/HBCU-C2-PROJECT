//
//  RequestHelpView.swift
//  AccessAbility
//
//  Created by Assistant on 4/6/26.
//

import SwiftUI

struct RequestHelpView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 24) {
                Text("Request Help")
                    .font(.largeTitle).bold()
                    .foregroundStyle(.white)
                    .accessibilityAddTraits(.isHeader)
                Text("Coming soon. In emergencies, call 911.")
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding()
        }
        .onAppear { SpeechManager.shared.speak("Request Help. Coming soon.", interrupt: true) }
    }
}

#Preview { RequestHelpView() }
