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
    @State private var youCoordinate = CampusRouteGeometry.coordinateAlongPolyline(
        CampusRouteGeometry.coordinates(for: IndoorRoute.defaultRoute),
        progress: 0
    )
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
                OutdoorRouteMapView(
                    coordinates: CampusRouteGeometry.coordinates(for: route),
                    userCoordinate: youCoordinate
                )
                .frame(height: 250)
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
            phase = .confirm
            SpeechManager.shared.speak("Route from \(resolved.startName) to \(resolved.endName). Press start navigation when ready.", interrupt: true)
        } else {
            selectedStart = Self.defaultStart
            selectedEnd = Self.defaultEnd
            route = IndoorRoute.find(from: Self.defaultStart, to: Self.defaultEnd)
            phase = .confirm
            SpeechManager.shared.speak("I could not find that exact route. Using Cafeteria front door to Park Johnson Room 208. Press start navigation when ready.", interrupt: true)
        }
    }

    private func startNavigation() {
        guard let route else { return }
        stopWalkTimer()
        currentStepIndex = 0
        youCoordinate = CampusRouteGeometry.coordinateAlongPolyline(
            CampusRouteGeometry.coordinates(for: route),
            progress: 0
        )
        phase = .navigating
        HapticService.navigationStarted()
        speakCurrentStep()
        startWalkTimer()
    }

    private func advanceToNextStep() {
        guard let route else { return }

        if currentStepIndex + 1 < route.steps.count {
            currentStepIndex += 1
            updateSimulatedLocation(route: route)
            speakCurrentStep()
        } else {
            stopWalkTimer()
            phase = .arrived
            HapticService.arrived()
            SpeechManager.shared.speak("You've arrived at \(route.endName).", interrupt: true)
        }
    }

    private func updateSimulatedLocation(route: IndoorRoute) {
        let coordinates = CampusRouteGeometry.coordinates(for: route)
        youCoordinate = CampusRouteGeometry.coordinateAlongPolyline(
            coordinates,
            progress: outdoorProgress(route: route, currentIndex: currentStepIndex)
        )
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

    private func outdoorProgress(route: IndoorRoute, currentIndex: Int) -> Double {
        let outdoorIndices = route.steps.indices.filter { isOutdoorStep(route.steps[$0]) }
        guard let firstOutdoor = outdoorIndices.first, let lastOutdoor = outdoorIndices.last else {
            return 1
        }

        if currentIndex <= firstOutdoor { return 0 }
        if currentIndex >= lastOutdoor { return 1 }

        guard let outdoorPosition = outdoorIndices.firstIndex(of: currentIndex) else {
            return 1
        }

        return Double(outdoorPosition) / Double(max(outdoorIndices.count - 1, 1))
    }

    private func isIndoorStep(_ step: IndoorRoute.RouteStep) -> Bool {
        let instruction = step.instruction.lowercased()
        return instruction.contains("inside") ||
            instruction.contains("lobby") ||
            instruction.contains("floor") ||
            instruction.contains("hallway") ||
            instruction.contains("room")
    }

    private func isOutdoorStep(_ step: IndoorRoute.RouteStep) -> Bool {
        step.sceneImageName == nil && !isIndoorStep(step)
    }
}

private struct OutdoorRouteMapView: UIViewRepresentable {
    let coordinates: [CLLocationCoordinate2D]
    let userCoordinate: CLLocationCoordinate2D

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        mapView.delegate = context.coordinator
        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.pointOfInterestFilter = .includingAll
        mapView.isPitchEnabled = false

        if #available(iOS 16.0, *) {
            mapView.preferredConfiguration = MKStandardMapConfiguration(emphasisStyle: .muted)
        } else {
            mapView.mapType = .mutedStandard
        }

        context.coordinator.update(
            mapView: mapView,
            coordinates: coordinates,
            userCoordinate: userCoordinate,
            animated: false
        )
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        context.coordinator.update(
            mapView: mapView,
            coordinates: coordinates,
            userCoordinate: userCoordinate,
            animated: true
        )
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        private let startAnnotation = MKPointAnnotation()
        private let destinationAnnotation = MKPointAnnotation()
        private let userAnnotation = MKPointAnnotation()
        private var routePolyline: MKPolyline?
        private var routeSignature = ""

        func update(
            mapView: MKMapView,
            coordinates: [CLLocationCoordinate2D],
            userCoordinate: CLLocationCoordinate2D,
            animated: Bool
        ) {
            guard coordinates.count >= 2 else { return }

            let signature = coordinates
                .map { "\($0.latitude),\($0.longitude)" }
                .joined(separator: "|")

            if signature != routeSignature {
                rebuildRoute(on: mapView, coordinates: coordinates)
                routeSignature = signature
                fitRoute(on: mapView, animated: animated)
            }

            userAnnotation.coordinate = userCoordinate
            mapView.setCenter(userCoordinate, animated: animated)
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let polyline = overlay as? MKPolyline else {
                return MKOverlayRenderer(overlay: overlay)
            }

            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = .systemBlue
            renderer.lineWidth = 6
            renderer.lineCap = .round
            renderer.lineJoin = .round
            return renderer
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let pointAnnotation = annotation as? MKPointAnnotation else { return nil }

            if pointAnnotation === userAnnotation {
                let identifier = "user-dot"
                let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) ??
                    MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.annotation = annotation
                view.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
                view.backgroundColor = .systemBlue
                view.layer.cornerRadius = 10
                view.layer.borderWidth = 3
                view.layer.borderColor = UIColor.white.cgColor
                view.layer.shadowColor = UIColor.black.cgColor
                view.layer.shadowOpacity = 0.25
                view.layer.shadowRadius = 4
                view.layer.shadowOffset = CGSize(width: 0, height: 2)
                view.canShowCallout = false
                return view
            }

            let identifier = pointAnnotation === startAnnotation ? "start-marker" : "destination-marker"
            let view = (mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView) ??
                MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.annotation = annotation
            view.canShowCallout = true

            if pointAnnotation === startAnnotation {
                view.markerTintColor = .systemGreen
                view.glyphImage = UIImage(systemName: "figure.walk")
            } else {
                view.markerTintColor = .systemRed
                view.glyphImage = UIImage(systemName: "mappin")
            }

            return view
        }

        private func rebuildRoute(on mapView: MKMapView, coordinates: [CLLocationCoordinate2D]) {
            if let routePolyline {
                mapView.removeOverlay(routePolyline)
            }

            mapView.removeAnnotations([startAnnotation, destinationAnnotation, userAnnotation])

            let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
            routePolyline = polyline

            startAnnotation.title = "Start"
            startAnnotation.coordinate = coordinates[0]

            destinationAnnotation.title = "Destination"
            destinationAnnotation.coordinate = coordinates[coordinates.count - 1]

            userAnnotation.title = "You"
            userAnnotation.coordinate = coordinates[0]

            mapView.addOverlay(polyline)
            mapView.addAnnotations([startAnnotation, destinationAnnotation, userAnnotation])
        }

        private func fitRoute(on mapView: MKMapView, animated: Bool) {
            guard let routePolyline else { return }

            mapView.setVisibleMapRect(
                routePolyline.boundingMapRect,
                edgePadding: UIEdgeInsets(top: 32, left: 32, bottom: 32, right: 32),
                animated: animated
            )
        }
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

        return (0..<stepCount).map { index in
            let t = stepCount > 1 ? CGFloat(index) / CGFloat(stepCount - 1) : 1
            let inverse = 1 - t
            return CGPoint(
                x: inverse * inverse * start.x + 2 * inverse * t * middle.x + t * t * end.x,
                y: inverse * inverse * start.y + 2 * inverse * t * middle.y + t * t * end.y
            )
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
