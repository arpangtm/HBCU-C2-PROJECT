import SwiftUI
import UIKit

private enum HomeRoute: Hashable {
    case navigation
    case scanSurroundings
    case adaReport
    case requestHelp

    var title: String {
        switch self {
        case .navigation: "Navigation"
        case .scanSurroundings: "Scan Surroundings"
        case .adaReport: "Report ADA Issue"
        case .requestHelp: "Request Help"
        }
    }

    var gestureHint: String {
        switch self {
        case .navigation: "Swipe up"
        case .scanSurroundings: "Swipe left"
        case .adaReport: "Swipe right"
        case .requestHelp: "Swipe down"
        }
    }

    var icon: String {
        switch self {
        case .navigation: "location.circle.fill"
        case .scanSurroundings: "camera.viewfinder"
        case .adaReport: "exclamationmark.bubble.fill"
        case .requestHelp: "person.wave.2.fill"
        }
    }

    var color: Color {
        switch self {
        case .navigation: AccessAbilityTheme.navigationBlue
        case .scanSurroundings: AccessAbilityTheme.readingGreen
        case .adaReport: AccessAbilityTheme.objectOrange
        case .requestHelp: AccessAbilityTheme.helpRed
        }
    }

    var accessibilityIdentifier: String {
        switch self {
        case .navigation: "home.route.navigation"
        case .scanSurroundings: "home.route.scanSurroundings"
        case .adaReport: "home.route.adaReport"
        case .requestHelp: "home.route.requestHelp"
        }
    }
}

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @State private var announceHome = true
    @State private var path: [HomeRoute] = []
    @State private var isHoldingControl = false
    @State private var dragOffset: CGSize = .zero
    @State private var highlightedRoute: HomeRoute?

    private let swipeDistance: CGFloat = 72
    private let maxControlTravel: CGFloat = 64
    private let routes: [HomeRoute] = [.navigation, .scanSurroundings, .adaReport, .requestHelp]

    var body: some View {
        NavigationStack(path: $path) {
            GeometryReader { proxy in
                ZStack {
                    background

                    VStack(spacing: 0) {
                        header
                        Spacer(minLength: 28)
                        gestureCompass(availableHeight: proxy.size.height)
                        Spacer(minLength: 28)
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 32)
                    .padding(.bottom, 18)
                }
            }
            .navigationDestination(for: HomeRoute.self) { route in
                destination(for: route)
            }
            .accessibilityIdentifier("home.screen")
        }
        .onAppear {
            guard announceHome else { return }
            announceHome = false
            let greeting = appState.userName.isEmpty ? "Home." : "Home. Welcome, \(appState.userName)."
            SpeechManager.shared.speak(
                "\(greeting) Press the center control and swipe up for Navigation, left for Scan Surroundings, right for Report ADA Issue, or down for Request Help.",
                interrupt: true
            )
        }
    }

    private var background: some View {
        return ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.04, blue: 0.08),
                    Color(red: 0.02, green: 0.12, blue: 0.16),
                    Color.black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(AccessAbilityTheme.navigationBlue.opacity(0.28))
                .blur(radius: 70)
                .frame(width: 260, height: 260)
                .offset(x: -150, y: -260)

            Circle()
                .fill(AccessAbilityTheme.accentGold.opacity(0.18))
                .blur(radius: 90)
                .frame(width: 300, height: 300)
                .offset(x: 160, y: 250)
        }
        .ignoresSafeArea()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(appState.userName.isEmpty ? "Home" : "Hi, \(appState.userName)")
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func gestureCompass(availableHeight: CGFloat) -> some View {
        let compassHeight = min(max(availableHeight * 0.56, 410), 440)

        return GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let edgeInset: CGFloat = 12
            let sideCardWidth = min(128, max(112, (width - 150) / 2))
            let verticalCardWidth = min(204, max(184, width - 120))
            let horizontalOffset = max(0, min((width - sideCardWidth) / 2 - edgeInset, width * 0.32))
            let verticalOffset = min(height * 0.32, 146)
            let centerSize = min(92, max(84, width * 0.23))
            let haloSize = centerSize + 14

            ZStack {
                compassRings(width: width, height: height)

                routeChip(.navigation, width: verticalCardWidth, height: 100)
                    .offset(y: -verticalOffset)
                routeChip(.requestHelp, width: verticalCardWidth, height: 100)
                    .offset(y: verticalOffset)
                routeChip(.adaReport, width: sideCardWidth, height: 126)
                    .offset(x: horizontalOffset)
                routeChip(.scanSurroundings, width: sideCardWidth, height: 126)
                    .offset(x: -horizontalOffset)

                ForEach(routes, id: \.self) { route in
                    directionRay(for: route, horizontalOffset: horizontalOffset, verticalOffset: verticalOffset)
                }

                centerControl(size: centerSize, haloSize: haloSize)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: compassHeight)
        .accessibilityElement(children: .contain)
    }

    private func compassRings(width: CGFloat, height: CGFloat) -> some View {
        let outer = min(width - 16, height - 40, 360)
        let middle = max(outer - 84, 200)
        let inner = max(outer - 156, 148)

        return ZStack {
            Circle()
                .stroke(.white.opacity(0.10), lineWidth: 1)
                .frame(width: outer, height: outer)

            Circle()
                .stroke(.white.opacity(0.18), style: StrokeStyle(lineWidth: 1, dash: [8, 12]))
                .frame(width: middle, height: middle)

            Circle()
                .fill(.white.opacity(0.04))
                .frame(width: inner, height: inner)
                .blur(radius: 0.4)
        }
    }

    private func routeChip(_ route: HomeRoute, width: CGFloat, height: CGFloat) -> some View {
        let isHighlighted = highlightedRoute == route

        return VStack(spacing: 7) {
            Image(systemName: route.icon)
                .font(.system(size: 26, weight: .black))
            Text(route.title)
                .font(.callout.weight(.black))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.72)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .frame(width: width, height: height)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(route.color.opacity(isHighlighted ? 0.96 : 0.58))
                .shadow(color: route.color.opacity(isHighlighted ? 0.55 : 0.18), radius: isHighlighted ? 24 : 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(.white.opacity(isHighlighted ? 0.70 : 0.22), lineWidth: isHighlighted ? 2 : 1)
        )
        .scaleEffect(isHighlighted ? 1.04 : 1)
        .animation(.spring(response: 0.22, dampingFraction: 0.72), value: isHighlighted)
        .accessibilityLabel("\(route.title), \(route.gestureHint)")
        .accessibilityIdentifier(route.accessibilityIdentifier)
    }

    private func directionRay(for route: HomeRoute, horizontalOffset: CGFloat, verticalOffset: CGFloat) -> some View {
        let isHighlighted = highlightedRoute == route
        let size = raySize(for: route, horizontalOffset: horizontalOffset, verticalOffset: verticalOffset)

        return Capsule()
            .fill(route.color.opacity(isHighlighted ? 0.95 : 0.22))
            .frame(width: size.width, height: size.height)
            .offset(rayOffset(for: route, horizontalOffset: horizontalOffset, verticalOffset: verticalOffset))
            .shadow(color: route.color.opacity(isHighlighted ? 0.45 : 0), radius: 16)
            .animation(.easeInOut(duration: 0.16), value: isHighlighted)
    }

    private func centerControl(size: CGFloat, haloSize: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(.white.opacity(isHoldingControl ? 0.24 : 0.12))
                .frame(width: haloSize, height: haloSize)
                .blur(radius: isHoldingControl ? 16 : 26)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            .white,
                            AccessAbilityTheme.accentGold,
                            Color(red: 0.86, green: 0.56, blue: 0.18)
                        ],
                        center: .topLeading,
                        startRadius: 4,
                        endRadius: 104
                    )
                )
                .frame(width: size, height: size)
                .shadow(color: AccessAbilityTheme.accentGold.opacity(isHoldingControl ? 0.60 : 0.36), radius: isHoldingControl ? 34 : 18, y: 14)
                .overlay(
                    Circle()
                        .stroke(.white.opacity(0.85), lineWidth: 2)
                )

            VStack(spacing: 8) {
                Image(systemName: isHoldingControl ? "hand.draw.fill" : "hand.point.up.left.fill")
                    .font(.system(size: 24, weight: .black))
                Text(isHoldingControl ? "Swipe" : "Hold")
                    .font(.caption.weight(.black))
            }
            .foregroundStyle(Color.black.opacity(0.82))
        }
        .offset(clampedOffset(dragOffset))
        .scaleEffect(isHoldingControl ? 1.06 : 1)
        .animation(.spring(response: 0.25, dampingFraction: 0.72), value: isHoldingControl)
        .animation(.spring(response: 0.24, dampingFraction: 0.76), value: dragOffset)
        .contentShape(Circle())
        .gesture(controlGesture)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Home control")
        .accessibilityHint("Press the center, then swipe up for Navigation, left for Scan Surroundings, right for Report ADA Issue, or down for Request Help.")
        .accessibilityIdentifier("home.gesturePad")
    }

    private var controlGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if !isHoldingControl {
                    isHoldingControl = true
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }

                dragOffset = value.translation
                highlightedRoute = route(for: value.translation)
            }
            .onEnded { value in
                let route = route(for: value.translation)
                isHoldingControl = false
                dragOffset = .zero
                highlightedRoute = nil

                guard let route else {
                    SpeechManager.shared.speak("Press the center and swipe in a direction to open a feature.", interrupt: true)
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    return
                }

                open(route)
            }
    }

    @ViewBuilder
    private func destination(for route: HomeRoute) -> some View {
        switch route {
        case .navigation:
            IndoorNavigationView()
        case .scanSurroundings:
            ScanSurroundingsView()
        case .adaReport:
            ADAReportView()
        case .requestHelp:
            RequestHelpFlowView()
        }
    }

    private func route(for translation: CGSize) -> HomeRoute? {
        let dx = translation.width
        let dy = translation.height
        guard max(abs(dx), abs(dy)) >= swipeDistance else { return nil }

        if abs(dy) >= abs(dx) {
            return dy < 0 ? .navigation : .requestHelp
        } else {
            return dx > 0 ? .adaReport : .scanSurroundings
        }
    }

    private func open(_ route: HomeRoute) {
        SpeechManager.shared.speak("Opening \(route.title).", interrupt: true)
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        path.append(route)
    }

    private func clampedOffset(_ offset: CGSize) -> CGSize {
        let distance = hypot(offset.width, offset.height)
        guard distance > maxControlTravel, distance > 0 else { return offset }

        let scale = maxControlTravel / distance
        return CGSize(width: offset.width * scale, height: offset.height * scale)
    }

    private func raySize(for route: HomeRoute, horizontalOffset: CGFloat, verticalOffset: CGFloat) -> CGSize {
        switch route {
        case .navigation, .requestHelp:
            CGSize(width: 18, height: max(58, verticalOffset - 70))
        case .scanSurroundings, .adaReport:
            CGSize(width: max(42, horizontalOffset - 54), height: 18)
        }
    }

    private func rayOffset(for route: HomeRoute, horizontalOffset: CGFloat, verticalOffset: CGFloat) -> CGSize {
        switch route {
        case .navigation:
            CGSize(width: 0, height: -(verticalOffset / 2 + 18))
        case .adaReport:
            CGSize(width: horizontalOffset / 2 + 18, height: 0)
        case .scanSurroundings:
            CGSize(width: -(horizontalOffset / 2 + 18), height: 0)
        case .requestHelp:
            CGSize(width: 0, height: verticalOffset / 2 + 18)
        }
    }
}
