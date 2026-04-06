import SwiftUI
import UIKit

struct ContentView: View {
    @State private var announceHome = true

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        NavigationLink {
                            NavigationAssistView()
                        } label: {
                            quadrantView(
                                title: "Navigation",
                                systemImage: "location.circle.fill",
                                color: Color(red: 0.14, green: 0.33, blue: 0.78),
                                accessibilityIdentifier: "home.tile.navigation"
                            )
                        }

                        NavigationLink {
                            ReadSignsView()
                        } label: {
                            quadrantView(
                                title: "Read Signs",
                                systemImage: "text.viewfinder",
                                color: Color(red: 0.14, green: 0.54, blue: 0.28),
                                accessibilityIdentifier: "home.tile.readSigns"
                            )
                        }
                    }

                    HStack(spacing: 6) {
                        NavigationLink {
                            IdentifyObjectView()
                        } label: {
                            quadrantView(
                                title: "Identify Object",
                                systemImage: "camera.viewfinder",
                                color: Color(red: 0.83, green: 0.45, blue: 0.14),
                                accessibilityIdentifier: "home.tile.identifyObject"
                            )
                        }

                        NavigationLink {
                            RequestHelpView()
                        } label: {
                            quadrantView(
                                title: "Request Help",
                                systemImage: "person.wave.2.fill",
                                color: Color(red: 0.74, green: 0.18, blue: 0.22),
                                accessibilityIdentifier: "home.tile.requestHelp"
                            )
                        }
                    }
                }
                .padding(6)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .background(Color.black.opacity(0.95))
            }
            .navigationTitle("AccessAbility")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            guard announceHome else { return }
            announceHome = false
            SpeechManager.shared.speak(
                "Home. Top left, Navigation. Top right, Read Signs. Bottom left, Identify Object. Bottom right, Request Help. Double tap a section to open.",
                interrupt: true
            )
        }
    }

    @ViewBuilder
    private func quadrantView(
        title: String,
        systemImage: String,
        color: Color,
        accessibilityIdentifier: String
    ) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(color.opacity(0.97))

            VStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.system(size: 58, weight: .bold))
                Text(title)
                    .font(.title2.weight(.bold))
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(.white)
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(Text(title))
        .accessibilityHint(Text("Double tap to open \(title)"))
        .accessibilityIdentifier(accessibilityIdentifier)
        .simultaneousGesture(
            TapGesture().onEnded {
                SpeechManager.shared.speak(title, interrupt: true)
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            }
        )
    }
}
