import MapKit
import SwiftUI

struct IndoorNavigationView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var voiceInput = VoiceInputService()

    @State private var phase: Phase = .selectStart
    @State private var selectedStart: Landmark?
    @State private var selectedEnd: Landmark?
    @State private var route: IndoorRoute?
    @State private var currentStepIndex = 0
    @State private var showListeningCue = false
    @State private var routePolyline: [CLLocationCoordinate2D] = []
    @State private var outdoorWalkProgress: Double = 0
    @State private var walkTimer: Timer?

    private let walkStepInterval: TimeInterval = 10

    private enum Phase {
        case selectStart
        case selectEnd
        case confirm
        case navigating
        case arrived
    }

    private static let defaultStart = Landmark.all.first { $0.id == "cafeteria_front" }!
    private static let defaultEnd = Landmark.all.first { $0.id == "pj_208" }!
    var body: some View {
        ZStack {
            AccessAbilityTheme.background.ignoresSafeArea()

            switch phase {
            case .selectStart:
                selectPlaceContent(
                    title: "Where are you now?",
                    prompt: "Choose your starting location, or use voice input.",
                    selected: selectedStart,
                    buttonTitle: "Say starting location",
                    onSelect: chooseStart,
                    onVoice: startVoiceForStart
                )
            case .selectEnd:
                selectPlaceContent(
                    title: "Where do you want to go?",
                    prompt: "Choose a destination, or use voice input.",
                    selected: selectedEnd,
                    buttonTitle: "Say destination",
                    onSelect: chooseEnd,
                    onVoice: startVoiceForEnd
                )
            case .confirm:
                confirmContent
            case .navigating:
                navigatingContent
            case .arrived:
                arrivedContent
            }
        }
        .navigationTitle("Navigation")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("navigation.screen")
        .onAppear {
            voiceInput.requestAuthorization { _ in }
            SpeechManager.shared.speak("Indoor navigation. Choose where you are now, or press say starting location.", interrupt: true, delay: 0.3)
        }
        .onDisappear {
            voiceInput.stopListening()
            stopWalkTimer()
            SpeechManager.shared.stop()
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            handleDoubleTap()
        }
    }

    private func selectPlaceContent(
        title: String,
        prompt: String,
        selected: Landmark?,
        buttonTitle: String,
        onSelect: @escaping (Landmark) -> Void,
        onVoice: @escaping () -> Void
    ) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(title)
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(AccessAbilityTheme.primaryText)

                Text(prompt)
                    .font(.body)
                    .foregroundStyle(AccessAbilityTheme.secondaryText)

                if showListeningCue || voiceInput.isListening {
                    listeningCue
                }

                Button {
                    onVoice()
                } label: {
                    Label(showListeningCue || voiceInput.isListening ? "Listening..." : buttonTitle, systemImage: "mic.fill")
                        .font(.headline.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(AccessAbilityTheme.accentGold)
                        .foregroundStyle(Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .disabled(showListeningCue || voiceInput.isListening)

                Text("Available Places")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AccessAbilityTheme.primaryText)
                    .padding(.top, 8)

                ForEach(Landmark.all) { landmark in
                    Button {
                        onSelect(landmark)
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: selected?.id == landmark.id ? "checkmark.circle.fill" : "circle")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(selected?.id == landmark.id ? AccessAbilityTheme.accentGold : AccessAbilityTheme.mutedText)

                            Text(landmark.name)
                                .font(.headline)
                                .foregroundStyle(AccessAbilityTheme.primaryText)

                            Spacer()
                        }
                        .padding(18)
                        .background(AccessAbilityTheme.cardBackground(cornerRadius: 18))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(landmark.name)
                    .accessibilityHint("Press to choose this place")
                }
            }
            .padding(22)
        }
    }

    private var listeningCue: some View {
        HStack(spacing: 14) {
            ProgressView()
                .tint(AccessAbilityTheme.accentGold)

            VStack(alignment: .leading, spacing: 4) {
                Text("Listening...")
                    .font(.headline)
                    .foregroundStyle(AccessAbilityTheme.primaryText)
                if !voiceInput.recognizedText.isEmpty {
                    Text(voiceInput.recognizedText)
                        .font(.caption)
                        .foregroundStyle(AccessAbilityTheme.mutedText)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AccessAbilityTheme.cardBackground(cornerRadius: 18))
    }

    @ViewBuilder
    private var confirmContent: some View {
        if let route {
            VStack(alignment: .leading, spacing: 20) {
                Image(systemName: "map.fill")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundStyle(AccessAbilityTheme.accentGold)

                Text("Route Ready")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(AccessAbilityTheme.primaryText)

                Text("From \(route.startName)")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AccessAbilityTheme.secondaryText)

                Text("To \(route.endName)")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AccessAbilityTheme.secondaryText)

                Text("Press start navigation. AccessAbility will speak each step and continue at a walking pace.")
                    .font(.body)
                    .foregroundStyle(AccessAbilityTheme.secondaryText)
                    .lineSpacing(4)

                Button {
                    startNavigation()
                } label: {
                    Label("Start Navigation", systemImage: "figure.walk")
                        .font(.headline.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.white)
                        .foregroundStyle(Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .padding(.top, 10)

                Spacer()
            }
            .padding(22)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Route from \(route.startName) to \(route.endName). Press start navigation.")
        }
    }

    @ViewBuilder
    private var navigatingContent: some View {
        if let route {
            let step = route.steps[currentStepIndex]
            let progress = Double(currentStepIndex + 1) / Double(route.steps.count)

            ScrollView {
                VStack(spacing: 18) {
                    stepVisual(for: step, route: route)

                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Step \(currentStepIndex + 1) of \(route.steps.count)")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(AccessAbilityTheme.primaryText)

                            Spacer()

                            Image(systemName: "figure.walk")
                                .font(.title2.weight(.bold))
                                .foregroundStyle(AccessAbilityTheme.accentGold)
                        }

                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white.opacity(0.18))
                                    .frame(height: 8)

                                Capsule()
                                    .fill(AccessAbilityTheme.accentGold)
                                    .frame(width: geometry.size.width * progress, height: 8)
                            }
                        }
                        .frame(height: 8)

                        Text(step.instruction)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(AccessAbilityTheme.primaryText)
                            .lineSpacing(4)

                        if let detail = step.detail {
                            Text(detail)
                                .font(.body)
                                .foregroundStyle(AccessAbilityTheme.secondaryText)
                        }

                        if let approxSteps = step.approxSteps {
                            Label("About \(approxSteps) small steps", systemImage: "shoeprints.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AccessAbilityTheme.mutedText)
                        }

                        if step.isStairsStart || step.isStairsEnd {
                            cautionLabels(for: step)
                        }

                        Button {
                            advanceToNextStep()
                        } label: {
                            Text(currentStepIndex + 1 == route.steps.count ? "Finish Route" : "Next Step")
                                .font(.headline.weight(.bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.white)
                                .foregroundStyle(Color.black)
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                    }
                    .padding(20)
                    .background(AccessAbilityTheme.cardBackground())
                }
                .padding(22)
            }
            .accessibilityElement(children: .contain)
        }
    }

    private func stepVisual(for step: IndoorRoute.RouteStep, route: IndoorRoute) -> some View {
        Group {
            if isOutdoorStep(step) {
                AppleStyleRouteMapView(
                    routeCoordinates: routePolyline,
                    userFraction: outdoorWalkProgress,
                    startLabel: route.startName,
                    endLabel: route.endName
                )
                .frame(height: 300)
                .shadow(color: .black.opacity(0.18), radius: 14, x: 0, y: 8)
            } else if let sceneImageName = step.sceneImageName {
                Image(sceneImageName)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 250)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .overlay(alignment: .bottomLeading) {
                        Label("Indoor scene", systemImage: "photo.fill")
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.black.opacity(0.62), in: Capsule())
                            .foregroundStyle(.white)
                            .padding(14)
                    }
            } else {
                RouteMapView(steps: route.steps, currentIndex: currentStepIndex, startLabel: "Lobby", endLabel: route.endName)
                    .frame(height: 250)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(AccessAbilityTheme.cardStroke, lineWidth: 1)
        )
    }

    private func cautionLabels(for step: IndoorRoute.RouteStep) -> some View {
        HStack(spacing: 8) {
            if step.isStairsStart {
                Label("Change in level ahead", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.22), in: Capsule())
                    .foregroundStyle(Color.orange)
            }

            if step.isStairsEnd {
                Label("Level ground", systemImage: "checkmark.circle.fill")
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.22), in: Capsule())
                    .foregroundStyle(Color.green)
            }
        }
    }

    private var arrivedContent: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 78, weight: .bold))
                .foregroundStyle(AccessAbilityTheme.accentGold)

            Text("You've Arrived")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(AccessAbilityTheme.primaryText)

            Text(route?.endName ?? "Destination")
                .font(.title3.weight(.semibold))
                .foregroundStyle(AccessAbilityTheme.secondaryText)
                .multilineTextAlignment(.center)

            Button {
                dismiss()
            } label: {
                Text("Back to Home")
                    .font(.headline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.white)
                    .foregroundStyle(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .padding(.top, 10)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("You've arrived at \(route?.endName ?? "your destination").")
    }

    private func chooseStart(_ landmark: Landmark) {
        selectedStart = landmark
        showListeningCue = false
        phase = .selectEnd
        SpeechManager.shared.speak("Starting from \(landmark.name). Choose your destination.", interrupt: true)
    }

    private func chooseEnd(_ landmark: Landmark) {
        selectedEnd = landmark
        showListeningCue = false
        resolveRoute()
    }

    private func startVoiceForStart() {
        listenForLandmark(fallback: Self.defaultStart) { landmark in
            chooseStart(landmark)
        }
    }

    private func startVoiceForEnd() {
        listenForLandmark(fallback: Self.defaultEnd) { landmark in
            chooseEnd(landmark)
        }
    }

    private func listenForLandmark(fallback: Landmark, completion: @escaping (Landmark) -> Void) {
        showListeningCue = true
        SpeechManager.shared.stop()

        voiceInput.requestAuthorization { granted in
            guard granted else {
                showListeningCue = false
                SpeechManager.shared.speak("Microphone and speech recognition permission are needed to choose a place by voice.", interrupt: true)
                return
            }

            SpeechManager.shared.speak("Listening. Go ahead.", interrupt: true)
            voiceInput.startListening { text in
                showListeningCue = false
                let landmark = Landmark.match(from: text) ?? fallback
                SpeechManager.shared.speak("Using \(landmark.name).", interrupt: true)
                completion(landmark)
            }
        }
    }

    private func resolveRoute() {
        let start = selectedStart ?? Self.defaultStart
        let end = selectedEnd ?? Self.defaultEnd

        if let resolved = IndoorRoute.find(from: start, to: end) {
            route = resolved
            syncRoutePolyline(for: resolved)
            phase = .confirm
            SpeechManager.shared.speak("Route from \(resolved.startName) to \(resolved.endName). Press start navigation when ready.", interrupt: true)
        } else {
            selectedStart = Self.defaultStart
            selectedEnd = Self.defaultEnd
            route = IndoorRoute.find(from: Self.defaultStart, to: Self.defaultEnd)
            if let route {
                syncRoutePolyline(for: route)
            }
            phase = .confirm
            SpeechManager.shared.speak("I could not find that exact route. Using Cafeteria front door to Park Johnson Room 208. Press start navigation when ready.", interrupt: true)
        }
    }

    private func startNavigation() {
        guard let route else { return }
        stopWalkTimer()
        currentStepIndex = 0
        if routePolyline.isEmpty {
            syncRoutePolyline(for: route)
        } else {
            updateOutdoorWalkProgress()
        }
        phase = .navigating
        HapticService.navigationStarted()
        speakCurrentStep()
        startWalkTimer()
    }

    private func advanceToNextStep() {
        guard let route else { return }

        if currentStepIndex + 1 < route.steps.count {
            currentStepIndex += 1
            updateOutdoorWalkProgress()
            speakCurrentStep()
        } else {
            stopWalkTimer()
            phase = .arrived
            HapticService.arrived()
            SpeechManager.shared.speak("You've arrived at \(route.endName).", interrupt: true)
        }
    }

    private func syncRoutePolyline(for route: IndoorRoute) {
        routePolyline = CampusRouteGeometry.walkingPolyline(from: route.startId, to: route.endId)
        updateOutdoorWalkProgress()
    }

    private func updateOutdoorWalkProgress() {
        guard let route else {
            outdoorWalkProgress = 0
            return
        }

        let outdoorIndices = route.steps.indices.filter { isOutdoorStep(route.steps[$0]) }
        guard let firstOutdoor = outdoorIndices.first, let lastOutdoor = outdoorIndices.last else {
            outdoorWalkProgress = 0
            return
        }

        if outdoorIndices.count == 1 {
            let onlyOutdoor = firstOutdoor
            outdoorWalkProgress = currentStepIndex > onlyOutdoor ? 1 : 0
            return
        }

        guard lastOutdoor > firstOutdoor else {
            outdoorWalkProgress = 0
            return
        }

        if outdoorIndices.contains(currentStepIndex) {
            let segment = Double(currentStepIndex - firstOutdoor) / Double(lastOutdoor - firstOutdoor)
            outdoorWalkProgress = min(max(segment, 0), 1)
        } else if currentStepIndex < firstOutdoor {
            outdoorWalkProgress = 0
        } else {
            outdoorWalkProgress = 1
        }
    }

    private func speakCurrentStep() {
        guard let route else { return }
        let step = route.steps[currentStepIndex]
        let needsCaution = step.isStairsStart || step.isStairsEnd || step.instruction.lowercased().contains("curb")

        HapticService.stepChanged()
        if needsCaution { HapticService.caution() }

        let detail = step.detail.map { ". \($0)" } ?? ""
        SpeechManager.shared.speak("Step \(currentStepIndex + 1). \(step.instruction)\(detail)", interrupt: true)
    }

    private func handleDoubleTap() {
        switch phase {
        case .confirm:
            startNavigation()
        case .navigating:
            advanceToNextStep()
        case .arrived:
            dismiss()
        case .selectStart, .selectEnd:
            break
        }
    }

    private func startWalkTimer() {
        stopWalkTimer()
        let timer = Timer(timeInterval: walkStepInterval, repeats: true) { _ in
            advanceToNextStep()
        }
        walkTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func stopWalkTimer() {
        walkTimer?.invalidate()
        walkTimer = nil
    }

    private func isOutdoorStep(_ step: IndoorRoute.RouteStep) -> Bool {
        !step.usesIndoorScene
    }
}

private struct RouteMapView: View {
    let steps: [IndoorRoute.RouteStep]
    let currentIndex: Int
    let startLabel: String
    let endLabel: String

    private let routeBlue = Color(red: 0.22, green: 0.47, blue: 0.98)

    var body: some View {
        GeometryReader { geometry in
            let points = routePoints(stepCount: steps.count, width: geometry.size.width, height: geometry.size.height)

            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(AccessAbilityTheme.card)

                routePath(points: points)
                    .stroke(routeBlue.opacity(0.4), style: StrokeStyle(lineWidth: 9, lineCap: .round, lineJoin: .round))

                routePath(points: points)
                    .stroke(routeBlue, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))

                ForEach(points.indices, id: \.self) { index in
                    Circle()
                        .fill(index <= currentIndex ? routeBlue : Color.white.opacity(0.35))
                        .frame(width: 10, height: 10)
                        .position(points[index])
                }

                if let first = points.first, let last = points.last {
                    routeLabel(startLabel, color: routeBlue)
                        .position(x: first.x, y: max(first.y - 24, 24))

                    routeLabel(endLabel, color: AccessAbilityTheme.helpRed)
                        .position(x: last.x, y: min(last.y + 24, geometry.size.height - 24))

                    Circle()
                        .fill(AccessAbilityTheme.accentGold)
                        .frame(width: 34, height: 34)
                        .overlay(Circle().stroke(Color.white, lineWidth: 3))
                        .position(points[min(currentIndex, points.count - 1)])
                        .animation(.easeInOut(duration: 0.35), value: currentIndex)
                }
            }
        }
        .accessibilityHidden(true)
    }

    private func routeLabel(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption.weight(.bold))
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color, in: Capsule())
            .foregroundStyle(.white)
    }

    private func routePoints(stepCount: Int, width: CGFloat, height: CGFloat) -> [CGPoint] {
        guard stepCount > 0 else { return [] }

        let start = CGPoint(x: width / 2, y: height - 44)
        let middle = CGPoint(x: width * 0.72, y: height / 2)
        let end = CGPoint(x: width / 2, y: 44)

        return (0..<stepCount).map { index -> CGPoint in
            let t: CGFloat
            if stepCount > 1 {
                t = CGFloat(index) / CGFloat(stepCount - 1)
            } else {
                t = 1
            }

            let inverse: CGFloat = 1 - t
            let two: CGFloat = 2

            let x = inverse * inverse * start.x
                  + two * inverse * t * middle.x
                  + t * t * end.x

            let y = inverse * inverse * start.y
                  + two * inverse * t * middle.y
                  + t * t * end.y

            return CGPoint(x: x, y: y)
        }
    }

    private func routePath(points: [CGPoint]) -> Path {
        var path = Path()
        guard let first = points.first else { return path }

        path.move(to: first)
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        return path
    }
}

#Preview {
    NavigationStack {
        IndoorNavigationView()
    }
}
