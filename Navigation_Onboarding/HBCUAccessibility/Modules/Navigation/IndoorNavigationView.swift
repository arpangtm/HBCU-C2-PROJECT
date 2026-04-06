//
//  IndoorNavigationView.swift
//  HBCUAccessibility
//
//  Voice or list for start/destination. Confirm route, then step-by-step navigation.
//  Simulated walking: auto-advance with timed cues. Clear listening feedback.
//

import SwiftUI
import MapKit

struct IndoorNavigationView: View {
    @StateObject private var speech = SpeechService.shared
    @StateObject private var voiceInput = VoiceInputService()
    @Environment(\.dismiss) private var dismiss

    @State private var phase: Phase = .selectStart
    @State private var selectedStart: Landmark?
    @State private var selectedEnd: Landmark?
    @State private var route: IndoorRoute?
    @State private var currentStepIndex = 0
    @State private var walkTimer: Timer?
    @State private var listeningPulse = false
    @State private var showListeningCue = false

    enum Phase {
        case selectStart
        case selectEnd
        case confirm
        case navigating
        case arrived
    }

    private static let defaultStart = Landmark.all.first { $0.id == "cafeteria_front" }!
    private static let defaultEnd = Landmark.all.first { $0.id == "pj_208" }!
    private static let walkStepInterval: TimeInterval = 10

    /// Mock walking path on Apple Maps (outdoor segment). Starts at the true start landmark (e.g. Cafeteria).
    @State private var routePolyline: [CLLocationCoordinate2D] = []
    /// 0...1 along `routePolyline` — matches navigation step progress.
    @State private var outdoorWalkProgress: Double = 0

    var body: some View {
        ZStack {
            Theme.cardBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                switch phase {
                case .selectStart:
                    selectPlaceContent(
                        title: "Where are you now?",
                        prompt: "Say your starting location, or choose below.",
                        selected: selectedStart,
                        onSelect: { showListeningCue = false; selectedStart = $0; phase = .selectEnd; announceSelectEnd() },
                        onVoice: startVoiceForStart
                    )
                case .selectEnd:
                    selectPlaceContent(
                        title: "Where do you want to go?",
                        prompt: "Say your destination, or choose below.",
                        selected: selectedEnd,
                        onSelect: { showListeningCue = false; selectedEnd = $0; tryResolveRoute() },
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
            .overlay {
                if phase == .confirm || phase == .navigating || phase == .arrived {
                    doubleTapOverlay
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            voiceInput.requestAuthorization { _ in }
            announceSelectStart()
        }
        .onDisappear { stopWalkSimulation() }
    }

    // MARK: - Select place

    private func selectPlaceContent(
        title: String,
        prompt: String,
        selected: Landmark?,
        onSelect: @escaping (Landmark) -> Void,
        onVoice: @escaping () -> Void
    ) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Theme.fiskNavy)
                Text(prompt)
                    .font(.subheadline)
                    .foregroundStyle(Theme.subtleText)

                if showListeningCue || voiceInput.isListening {
                    listeningCueView
                }

                Button {
                    speech.stop()
                    showListeningCue = true
                    onVoice()
                } label: {
                    Label(showListeningCue || voiceInput.isListening ? "Listening…" : "Say location", systemImage: "mic.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(showListeningCue || voiceInput.isListening ? Theme.fiskGold.opacity(0.3) : Theme.fiskNavy)
                        .foregroundStyle(showListeningCue || voiceInput.isListening ? Theme.fiskNavy : .white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(showListeningCue || voiceInput.isListening)
                .accessibilityLabel(voiceInput.isListening ? "Listening" : "Say location")
                .accessibilityHint("Double-tap to speak your location")

                Text("Places you can say")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.fiskNavy)
                Text("Say any of these, or tap to choose.")
                    .font(.caption)
                    .foregroundStyle(Theme.subtleText)
                ForEach(Landmark.all) { landmark in
                    Button {
                        speech.stop()
                        onSelect(landmark)
                    } label: {
                        HStack {
                            Text(landmark.name)
                            Spacer()
                            if selected?.id == landmark.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Theme.fiskGold)
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .foregroundStyle(Theme.fiskNavy)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(landmark.name)
                    .accessibilityHint("Double-tap to choose this place")
                }
            }
            .padding(24)
        }
    }

    private var listeningCueView: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Theme.fiskGold.opacity(0.2))
                    .frame(width: 88, height: 88)
                    .scaleEffect(listeningPulse ? 1.15 : 1.0)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: listeningPulse)
                Image(systemName: "mic.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Theme.fiskNavy)
            }
            Text("Listening…")
                .font(.headline)
                .foregroundStyle(Theme.fiskNavy)
            if !voiceInput.recognizedText.isEmpty {
                Text("\"\(voiceInput.recognizedText)\"")
                    .font(.caption)
                    .foregroundStyle(Theme.subtleText)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Theme.fiskGold.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onAppear { listeningPulse = true }
        .onDisappear { listeningPulse = false }
    }

    private func startVoiceForStart() {
        speech.stop()
        listeningPulse = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [self] in
            speech.speak("Listening. Go ahead.", delay: 0)
        }
        var didFinish = false
        let finish: (Landmark?) -> Void = { [self] match in
            guard !didFinish else { return }
            didFinish = true
            showListeningCue = false
            listeningPulse = false
            voiceInput.stopListening()
            if let m = match {
                selectedStart = m
                speech.speak("Got it. \(m.name). Now say your destination.")
                phase = .selectEnd
                announceSelectEnd()
            } else {
                selectedStart = Self.defaultStart
                speech.speak("Using cafeteria as start. Now say your destination.")
                phase = .selectEnd
                announceSelectEnd()
            }
        }
        voiceInput.startListening { text in
            if let m = Landmark.match(from: text) {
                finish(m)
                return
            }
            finish(nil)
        }
    }

    private func startVoiceForEnd() {
        speech.stop()
        listeningPulse = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [self] in
            speech.speak("Listening. Go ahead.", delay: 0)
        }
        var didFinish = false
        let finish: (Landmark?) -> Void = { [self] match in
            guard !didFinish else { return }
            didFinish = true
            showListeningCue = false
            listeningPulse = false
            voiceInput.stopListening()
            if let m = match {
                selectedEnd = m
                tryResolveRoute()
            } else {
                selectedStart = selectedStart ?? Self.defaultStart
                selectedEnd = Self.defaultEnd
                if let r = IndoorRoute.find(from: selectedStart!, to: Self.defaultEnd) {
                    route = r
                    syncRoutePolyline(for: r)
                    phase = .confirm
                    speech.speak("Route from Cafeteria to Park Johnson 208. Double-tap anywhere to start navigation.")
                } else {
                    tryResolveRoute()
                }
            }
        }
        voiceInput.startListening { text in
            if let m = Landmark.match(from: text) {
                finish(m)
                return
            }
            finish(nil)
        }
    }

    private func tryResolveRoute() {
        let start = selectedStart ?? Self.defaultStart
        let end = selectedEnd ?? Self.defaultEnd
        if let r = IndoorRoute.find(from: start, to: end) {
            route = r
            syncRoutePolyline(for: r)
            phase = .confirm
            speech.speak("Route from \(r.startName) to \(r.endName). Double-tap anywhere to start navigation.")
        } else {
            selectedStart = Self.defaultStart
            selectedEnd = Self.defaultEnd
            route = IndoorRoute.find(from: Self.defaultStart, to: Self.defaultEnd)
            if let r = route { syncRoutePolyline(for: r) }
            phase = .confirm
            speech.speak("Demo route: Cafeteria to Park Johnson 208. Double-tap anywhere to start.")
        }
    }

    private func syncRoutePolyline(for route: IndoorRoute) {
        routePolyline = CampusMapGeometry.walkingPolyline(from: route.startId, to: route.endId)
        updateOutdoorWalkProgress()
    }

    /// Matches `navigatingContent` map vs scene split.
    private func isIndoorStepInstruction(_ instruction: String) -> Bool {
        let lower = instruction.lowercased()
        return lower.contains("enter park johnson") ||
            lower.contains("inside the lobby") ||
            lower.contains("second floor") ||
            lower.contains("third floor") ||
            lower.contains("hallway") ||
            lower.contains("room 208") ||
            lower.contains("room 308")
    }

    /// Outdoor map dot moves only across steps that use the Map (not indoor scene steps).
    private func updateOutdoorWalkProgress() {
        guard let route = route else {
            outdoorWalkProgress = 0
            return
        }
        let outdoorIndices = route.steps.indices.filter { !isIndoorStepInstruction(route.steps[$0].instruction) }
        guard let firstOutdoor = outdoorIndices.first, let lastOutdoor = outdoorIndices.last else {
            outdoorWalkProgress = 0
            return
        }
        if outdoorIndices.count == 1 {
            let only = firstOutdoor
            if currentStepIndex < only {
                outdoorWalkProgress = 0
            } else if currentStepIndex == only {
                outdoorWalkProgress = 0
            } else {
                outdoorWalkProgress = 1
            }
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

    @ViewBuilder
    private var confirmContent: some View {
        if let route = route {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Image(systemName: "map.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Theme.fiskGold)
                    Text("Route")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Theme.fiskNavy)
                    Text("From \(route.startName)")
                        .font(.body)
                        .foregroundStyle(Theme.subtleText)
                    Text("To \(route.endName)")
                        .font(.body)
                        .foregroundStyle(Theme.subtleText)
                    Text("Double-tap anywhere to start. We'll guide you step by step as you walk.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.fiskNavy)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(24)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Route from \(route.startName) to \(route.endName). Double-tap anywhere to start.")
        }
    }

    @ViewBuilder
    private var navigatingContent: some View {
        if let route = route {
            let step = route.steps[currentStepIndex]
            let isIndoor = isIndoorStepInstruction(step.instruction)
            let progress = route.steps.count > 0 ? Double(currentStepIndex + 1) / Double(route.steps.count) : 0
            VStack(spacing: 0) {
                if !isIndoor {
                    AppleStyleRouteMapView(
                        routeCoordinates: routePolyline,
                        userFraction: outdoorWalkProgress,
                        startLabel: route.startName,
                        endLabel: route.endName
                    )
                    .frame(height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.black.opacity(0.06), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 4)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                } else {
                    if let sceneName = step.sceneImageName {
                        Image(sceneName)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 240)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(radius: 8)
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                    } else {
                        RouteMapView(
                            steps: route.steps,
                            currentIndex: currentStepIndex,
                            startLabel: "Lobby",
                            endLabel: route.endName
                        )
                        .frame(height: 260)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                    }
                }
                VStack(spacing: 0) {
                    HStack {
                        Text("Step \(currentStepIndex + 1) of \(route.steps.count)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.fiskNavy)
                        Spacer()
                        Image(systemName: "figure.walk")
                            .font(.title3)
                            .foregroundStyle(Theme.fiskGold)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    GeometryReader { g in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 8)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Theme.fiskGold)
                                .frame(width: max(0, g.size.width * progress), height: 8)
                        }
                    }
                    .frame(height: 8)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(step.instruction)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.primary)
                        if let detail = step.detail {
                            Text(detail)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                        if let approx = step.approxSteps {
                            Text("About \(approx) small steps for this part.")
                                .font(.caption)
                                .foregroundStyle(Theme.subtleText)
                        }
                        if step.isStairsStart || step.isStairsEnd {
                            HStack(spacing: 8) {
                                if step.isStairsStart {
                                    Label("Change in level ahead", systemImage: "exclamationmark.triangle.fill")
                                        .font(.caption2.weight(.semibold))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.orange.opacity(0.15))
                                        .foregroundStyle(Color.orange)
                                        .clipShape(Capsule())
                                }
                                if step.isStairsEnd {
                                    Label("Back on level ground", systemImage: "checkmark.circle.fill")
                                        .font(.caption2.weight(.semibold))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.green.opacity(0.12))
                                        .foregroundStyle(Color.green)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        Text("Double-tap anywhere for next step.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                }
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.1), radius: 16, x: 0, y: 4)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                Spacer(minLength: 24)
            }
            .background(Color(.systemGroupedBackground))
            .accessibilityElement(children: .combine)
            .accessibilityLabel(stepsAccessibilityLabel(route: route))
            // Do not call startWalkSimulation() here. onAppear can fire again when the map is
            // swapped for indoor scene images (e.g. after step 4), which would reset the timer,
            // re-speak the step, and can overwhelm the main thread — felt like a freeze.
        }
    }

    private func startWalkSimulation() {
        stopWalkSimulation()
        speakCurrentStep()
        // scheduledTimer already adds the timer to the main run loop; adding it again for
        // .common could register it twice and duplicate firings.
        walkTimer = Timer.scheduledTimer(withTimeInterval: Self.walkStepInterval, repeats: true) { [self] _ in
            guard phase == .navigating else {
                stopWalkSimulation()
                return
            }
            advanceToNextStep()
            if phase == .arrived {
                stopWalkSimulation()
            }
        }
    }

    private func stopWalkSimulation() {
        walkTimer?.invalidate()
        walkTimer = nil
    }

    private func stepsAccessibilityLabel(route: IndoorRoute) -> String {
        let step = route.steps[currentStepIndex]
        var s = "Step \(currentStepIndex + 1) of \(route.steps.count). \(step.instruction)"
        if let d = step.detail { s += ". \(d)" }
        s += ". Double-tap to skip to next step."
        return s
    }

    @ViewBuilder
    private var arrivedContent: some View {
        if let route = route {
            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(Theme.fiskGold)
                Text("You've arrived")
                    .font(.title.weight(.bold))
                    .foregroundStyle(Theme.fiskNavy)
                Text(route.endName)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Text("Double-tap anywhere to go back.")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
            .padding(24)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("You've arrived at \(route.endName). Double-tap anywhere to go back.")
        }
    }

    private var doubleTapOverlay: some View {
        Color.clear
            .contentShape(Rectangle())
            .onTapGesture(count: 2) {
                handleDoubleTap()
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(doubleTapAccessibilityLabel)
            .accessibilityAddTraits(.isButton)
            .accessibilityHint("Double-tap to continue")
    }

    private var doubleTapAccessibilityLabel: String {
        switch phase {
        case .confirm: return "Double-tap anywhere to start navigation"
        case .navigating: return "Double-tap for next step"
        case .arrived: return "Double-tap to go back"
        default: return "Double-tap to continue"
        }
    }

    private func handleDoubleTap() {
        speech.stop()
        switch phase {
        case .confirm:
            if route != nil {
                phase = .navigating
                currentStepIndex = 0
                updateOutdoorWalkProgress()
                HapticService.navigationStarted()
                startWalkSimulation()
            }
        case .navigating:
            advanceToNextStep()
        case .arrived:
            dismiss()
        default:
            break
        }
    }

    private func speakCurrentStep() {
        guard let route = route else { return }
        let step = route.steps[currentStepIndex]
        let n = currentStepIndex + 1
        HapticService.stepChanged()
        let needsCaution = step.instruction.lowercased().contains("stairs") || step.instruction.lowercased().contains("curb")
        if needsCaution { HapticService.caution() }
        let full = step.detail.map { "\(step.instruction). \($0)" } ?? step.instruction
        speech.speak("Step \(n). \(full)")
    }

    private func advanceToNextStep() {
        guard phase == .navigating else { return }
        guard let route = route else { return }
        if currentStepIndex + 1 < route.steps.count {
            currentStepIndex += 1
            updateOutdoorWalkProgress()
            speakCurrentStep()
        } else {
            stopWalkSimulation()
            phase = .arrived
            HapticService.arrived()
            speech.speak("You've arrived at \(route.endName). Double-tap anywhere to go back.")
        }
    }

    private func announceSelectStart() {
        speech.speak("Indoor navigation. Say where you are — for example: Cafeteria, Library, or Chapel. Or tap the button to speak.")
    }

    private func announceSelectEnd() {
        if let s = selectedStart {
            speech.speak("Starting from \(s.name). Say where you want to go — for example: Park Johnson 308 or 208. Or tap to speak.")
        }
    }
}

// MARK: - Indoor route map (schematic path + labels for judges)

struct RouteMapView: View {
    let steps: [IndoorRoute.RouteStep]
    let currentIndex: Int
    var startLabel: String = "Start"
    var endLabel: String = "End"

    private let inset: CGFloat = 44
    private let waypointSize: CGFloat = 8
    private let youSize: CGFloat = 32
    private let routeBlue = Color(red: 0.22, green: 0.47, blue: 0.98)

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let stepCount = steps.count
            let points = routePoints(stepCount: stepCount, width: w, height: h)
            let youPos = positionForCurrentStep(points: points)
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                routePath(points: points)
                    .stroke(routeBlue.opacity(0.4), style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
                routePath(points: points)
                    .stroke(routeBlue, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                ForEach(0..<stepCount, id: \.self) { i in
                    let step = steps[i]
                    let isHazard = step.isStairsStart || step.isStairsEnd
                    Circle()
                        .fill(isHazard ? Color.orange : (i <= currentIndex ? routeBlue : Color.gray.opacity(0.25)))
                        .frame(width: waypointSize, height: waypointSize)
                        .position(points[i])
                }
                if !points.isEmpty {
                    Text(startLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(routeBlue)
                        .clipShape(Capsule())
                        .position(x: points[0].x, y: points[0].y - 22)
                    Text(endLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Theme.fiskNavy)
                        .clipShape(Capsule())
                        .position(x: points[points.count - 1].x, y: points[points.count - 1].y + 22)
                }
                Text("Step \(currentIndex + 1) of \(stepCount)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.fiskNavy)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color(.systemBackground))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(routeBlue.opacity(0.6), lineWidth: 2))
                    .position(x: w / 2, y: 28)
                Circle()
                    .fill(routeBlue)
                    .frame(width: youSize, height: youSize)
                    .overlay(Circle().stroke(Color.white, lineWidth: 3))
                    .shadow(color: routeBlue.opacity(0.5), radius: 6, x: 0, y: 2)
                    .position(youPos)
                    .animation(.easeInOut(duration: 0.35), value: currentIndex)
            }
            .frame(width: w, height: h)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.25), lineWidth: 1)
        )
        .accessibilityHidden(true)
    }

    private func routePoints(stepCount: Int, width w: CGFloat, height h: CGFloat) -> [CGPoint] {
        guard stepCount > 0 else { return [] }
        let n = stepCount
        let p0 = CGPoint(x: w / 2, y: h - inset)
        let p1 = CGPoint(x: w * 0.72, y: h / 2 + 16)
        let p2 = CGPoint(x: w / 2, y: inset)
        return (0..<n).map { i in
            let t = n > 1 ? CGFloat(i) / CGFloat(n - 1) : 1
            let t2 = t * t
            let mt = 1 - t
            let mt2 = mt * mt
            return CGPoint(
                x: mt2 * p0.x + 2 * mt * t * p1.x + t2 * p2.x,
                y: mt2 * p0.y + 2 * mt * t * p1.y + t2 * p2.y
            )
        }
    }

    private func routePath(points: [CGPoint]) -> Path {
        var path = Path()
        guard points.count >= 2 else { return path }
        path.move(to: points[0])
        for i in 1..<points.count {
            path.addLine(to: points[i])
        }
        return path
    }

    private func positionForCurrentStep(points: [CGPoint]) -> CGPoint {
        guard !points.isEmpty else { return .zero }
        let i = min(currentIndex, points.count - 1)
        return points[i]
    }

}

#Preview {
    NavigationStack {
        IndoorNavigationView()
    }
}
