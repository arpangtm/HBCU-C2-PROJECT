//
//  HomePlaceholderView.swift
//  HBCUAccessibility
//
//  Home screen. Consistent gestures: up = Indoor Nav, right = Request help,
//  left = Camera/Transcribe, down = Report to admin.
//

import SwiftUI

private enum HomeRoute: Hashable {
    case indoorNav
    case requestHelp
    case cameraTranscribe
    case report
}

struct HomePlaceholderView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var speech = SpeechService.shared
    @State private var path = [HomeRoute]()

    private let swipeDistance: CGFloat = 60

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Theme.cardBackground.ignoresSafeArea()
                List {
                    Section {
                        if !appState.userName.isEmpty {
                            Text("Welcome back, \(appState.userName)")
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(Theme.fiskNavy)
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                    Section("Swipe to open") {
                        row(title: "Indoor Navigation", icon: "arrow.up", route: .indoorNav, hint: "Swipe up, or double-tap to open")
                        row(title: "Request help", icon: "arrow.right", route: .requestHelp, hint: "Swipe right, or double-tap to open")
                        row(title: "Camera / Transcribe", icon: "arrow.left", route: .cameraTranscribe, hint: "Swipe left, or double-tap to open")
                        row(title: "Report to admin", icon: "arrow.down", route: .report, hint: "Swipe down, or double-tap to report non-ADA or other issues")
                    }
                    .listRowBackground(Color.white.opacity(0.8))
                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
                .simultaneousGesture(
                    DragGesture(minimumDistance: swipeDistance)
                        .onEnded { value in
                            handleSwipe(translation: value.translation)
                        }
                )
            }
            .navigationTitle("Fisk Accessibility")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
                case .indoorNav:
                    IndoorNavigationView()
                case .requestHelp:
                    RequestHelpPlaceholderView()
                case .cameraTranscribe:
                    CameraTranscribePlaceholderView()
                case .report:
                    ReportPlaceholderView()
                }
            }
            .onAppear {
                if !appState.userName.isEmpty {
                    speech.speak("Welcome back, \(appState.userName). You're on the home screen. Swipe up for indoor navigation. Swipe right to request help. Swipe left for camera and transcribe. Swipe down to report to admin. Or explore the list and double-tap to open.")
                }
            }
        }
    }

    private func row(title: String, icon: String, route: HomeRoute, hint: String) -> some View {
        Button {
            speech.stop()
            path.append(route)
            announceRoute(route)
        } label: {
            HStack {
                Text(title)
                Spacer()
                Image(systemName: icon)
            }
            .foregroundStyle(Theme.fiskNavy)
        }
        .listRowBackground(Color.white.opacity(0.8))
        .accessibilityLabel(title)
        .accessibilityHint(hint)
    }

    private func handleSwipe(translation: CGSize) {
        speech.stop()
        let dx = translation.width
        let dy = translation.height
        if abs(dy) >= abs(dx) {
            if dy < -swipeDistance {
                path.append(.indoorNav)
                speech.speak("Opening indoor navigation.")
            } else if dy > swipeDistance {
                path.append(.report)
                speech.speak("Opening report to admin.")
            }
        } else {
            if dx > swipeDistance {
                path.append(.requestHelp)
                speech.speak("Opening request help.")
            } else if dx < -swipeDistance {
                path.append(.cameraTranscribe)
                speech.speak("Opening camera and transcribe.")
            }
        }
    }

    private func announceRoute(_ route: HomeRoute) {
        switch route {
        case .indoorNav: speech.speak("Opening indoor navigation.")
        case .requestHelp: speech.speak("Opening request help.")
        case .cameraTranscribe: speech.speak("Opening camera and transcribe.")
        case .report: speech.speak("Opening report to admin.")
        }
    }
}

struct RequestHelpPlaceholderView: View {
    var body: some View {
        Text("Request help — campus security or volunteer (placeholder)")
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.cardBackground)
    }
}

struct CameraTranscribePlaceholderView: View {
    var body: some View {
        Text("Camera / Transcribe — scan and read signs (placeholder)")
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.cardBackground)
    }
}

struct ReportPlaceholderView: View {
    var body: some View {
        Text("Report — non-ADA compliant or other issues to admin (placeholder)")
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.cardBackground)
    }
}

#Preview {
    HomePlaceholderView()
        .environmentObject(AppState.shared)
}
