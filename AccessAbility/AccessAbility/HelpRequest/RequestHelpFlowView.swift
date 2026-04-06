import SwiftUI
import UIKit

struct RequestHelpFlowView: View {
    var body: some View {
        RequestHelpCategorySelectionView()
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .accessibilityIdentifier("requestHelp.screen")
    }
}

private enum SwipeSelectionDirection: Hashable {
    case up
    case right
    case left
    case down

    var label: String {
        switch self {
        case .up: "Swipe up"
        case .right: "Swipe right"
        case .left: "Swipe left"
        case .down: "Swipe down"
        }
    }

    func offset(horizontal: CGFloat, vertical: CGFloat) -> CGSize {
        switch self {
        case .up: CGSize(width: 0, height: -vertical)
        case .right: CGSize(width: horizontal, height: 0)
        case .left: CGSize(width: -horizontal, height: 0)
        case .down: CGSize(width: 0, height: vertical)
        }
    }

    func rayOffset(horizontal: CGFloat, vertical: CGFloat) -> CGSize {
        switch self {
        case .up: CGSize(width: 0, height: -(vertical / 2 + 16))
        case .right: CGSize(width: horizontal / 2 + 16, height: 0)
        case .left: CGSize(width: -(horizontal / 2 + 16), height: 0)
        case .down: CGSize(width: 0, height: vertical / 2 + 16)
        }
    }

    func raySize(horizontal: CGFloat, vertical: CGFloat) -> CGSize {
        switch self {
        case .up, .down: CGSize(width: 18, height: max(68, vertical - 78))
        case .right, .left: CGSize(width: max(48, horizontal - 58), height: 18)
        }
    }
}

private struct SwipeSelectionOption<Value: Hashable>: Identifiable {
    let id: String
    let value: Value
    let direction: SwipeSelectionDirection
    let title: String
    let detail: String
    let color: Color
    let icon: String
}

private struct SwipeSelectionPad<Value: Hashable>: View {
    let title: String
    let prompt: String
    let accessibilityIdentifier: String
    let options: [SwipeSelectionOption<Value>]
    let onSelect: (Value) -> Void

    @State private var isHoldingControl = false
    @State private var dragOffset: CGSize = .zero
    @State private var highlightedDirection: SwipeSelectionDirection?

    private let swipeDistance: CGFloat = 70
    private let maxControlTravel: CGFloat = 62

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                header
                Spacer(minLength: 24)
                selectionCompass
                Spacer(minLength: 24)
            }
            .padding(.horizontal, 12)
            .padding(.top, 30)
            .padding(.bottom, 16)
        }
        .accessibilityIdentifier(accessibilityIdentifier)
    }

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color(red: 0.04, green: 0.08, blue: 0.13), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Circle()
                .fill(AccessAbilityTheme.helpRed.opacity(0.18))
                .blur(radius: 70)
                .frame(width: 280, height: 280)
                .offset(x: -170, y: -240)
            Circle()
                .fill(AccessAbilityTheme.accentGold.opacity(0.14))
                .blur(radius: 90)
                .frame(width: 300, height: 300)
                .offset(x: 160, y: 250)
        }
        .ignoresSafeArea()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.72)
            Text(prompt)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white.opacity(0.78))
                .lineLimit(2)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var selectionCompass: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let edgeInset: CGFloat = 12
            let sideCardWidth = min(132, max(116, (width - 128) / 2))
            let verticalCardWidth = min(204, max(178, width - 118))
            let horizontalOffset = max(0, min((width - sideCardWidth) / 2 - edgeInset, width * 0.30))
            let verticalOffset = min(height * 0.32, 138)
            let centerSize = min(108, max(96, width * 0.27))
            let haloSize = centerSize + 20

            ZStack {
                compassRings(width: width, height: height)

                ForEach(options) { option in
                    directionRay(for: option, horizontalOffset: horizontalOffset, verticalOffset: verticalOffset)
                    optionChip(option, width: option.direction == .up || option.direction == .down ? verticalCardWidth : sideCardWidth)
                        .offset(option.direction.offset(horizontal: horizontalOffset, vertical: verticalOffset))
                }

                centerControl(size: centerSize, haloSize: haloSize)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 420)
    }

    private func compassRings(width: CGFloat, height: CGFloat) -> some View {
        let outer = min(width - 24, height - 32, 318)
        let inner = max(outer - 136, 134)

        return ZStack {
            Circle()
                .stroke(.white.opacity(0.10), lineWidth: 1)
                .frame(width: outer, height: outer)
            Circle()
                .fill(.white.opacity(0.04))
                .frame(width: inner, height: inner)
        }
    }

    private func directionRay(for option: SwipeSelectionOption<Value>, horizontalOffset: CGFloat, verticalOffset: CGFloat) -> some View {
        let isHighlighted = highlightedDirection == option.direction

        return Capsule()
            .fill(option.color.opacity(isHighlighted ? 0.92 : 0.20))
            .frame(
                width: option.direction.raySize(horizontal: horizontalOffset, vertical: verticalOffset).width,
                height: option.direction.raySize(horizontal: horizontalOffset, vertical: verticalOffset).height
            )
            .offset(option.direction.rayOffset(horizontal: horizontalOffset, vertical: verticalOffset))
            .shadow(color: option.color.opacity(isHighlighted ? 0.40 : 0), radius: 16)
            .animation(.easeInOut(duration: 0.16), value: isHighlighted)
    }

    private func optionChip(_ option: SwipeSelectionOption<Value>, width: CGFloat) -> some View {
        let isHighlighted = highlightedDirection == option.direction

        return VStack(spacing: 7) {
            Image(systemName: option.icon)
                .font(.system(size: 24, weight: .black))
            Text(option.title)
                .font(.callout.weight(.black))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.72)
        }
        .foregroundStyle(.white)
        .padding(10)
        .frame(width: width, height: 100)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(option.color.opacity(isHighlighted ? 0.98 : 0.58))
                .shadow(color: option.color.opacity(isHighlighted ? 0.54 : 0.18), radius: isHighlighted ? 24 : 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(.white.opacity(isHighlighted ? 0.72 : 0.22), lineWidth: isHighlighted ? 2 : 1)
        )
        .scaleEffect(isHighlighted ? 1.04 : 1)
        .animation(.spring(response: 0.22, dampingFraction: 0.72), value: isHighlighted)
        .accessibilityLabel("\(option.title), \(option.direction.label)")
        .accessibilityHint(option.detail)
        .accessibilityIdentifier(option.id)
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
                        colors: [.white, AccessAbilityTheme.accentGold, Color(red: 0.86, green: 0.56, blue: 0.18)],
                        center: .topLeading,
                        startRadius: 4,
                        endRadius: 102
                    )
                )
                .frame(width: size, height: size)
                .shadow(color: AccessAbilityTheme.accentGold.opacity(isHoldingControl ? 0.60 : 0.36), radius: isHoldingControl ? 34 : 18, y: 14)
                .overlay(Circle().stroke(.white.opacity(0.85), lineWidth: 2))

            VStack(spacing: 8) {
                Image(systemName: isHoldingControl ? "hand.draw.fill" : "hand.point.up.left.fill")
                    .font(.system(size: 26, weight: .black))
                Text(isHoldingControl ? "Swipe" : "Hold")
                    .font(.subheadline.weight(.black))
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
        .accessibilityLabel("Selection control")
        .accessibilityHint("Press the center, then swipe in the direction of your choice.")
        .accessibilityIdentifier("\(accessibilityIdentifier).control")
    }

    private var controlGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if !isHoldingControl {
                    isHoldingControl = true
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }

                dragOffset = value.translation
                highlightedDirection = direction(for: value.translation)
            }
            .onEnded { value in
                let direction = direction(for: value.translation)
                isHoldingControl = false
                dragOffset = .zero
                highlightedDirection = nil

                guard
                    let direction,
                    let option = options.first(where: { $0.direction == direction })
                else {
                    SpeechManager.shared.speak("Press the center and swipe toward one of the choices.", interrupt: true)
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    return
                }

                SpeechManager.shared.speak("Selected \(option.title).", interrupt: true)
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                onSelect(option.value)
            }
    }

    private func direction(for translation: CGSize) -> SwipeSelectionDirection? {
        let dx = translation.width
        let dy = translation.height
        guard max(abs(dx), abs(dy)) >= swipeDistance else { return nil }

        let direction: SwipeSelectionDirection = abs(dy) >= abs(dx)
            ? (dy < 0 ? .up : .down)
            : (dx > 0 ? .right : .left)

        return options.contains { $0.direction == direction } ? direction : nil
    }

    private func clampedOffset(_ offset: CGSize) -> CGSize {
        let distance = hypot(offset.width, offset.height)
        guard distance > maxControlTravel, distance > 0 else { return offset }

        let scale = maxControlTravel / distance
        return CGSize(width: offset.width * scale, height: offset.height * scale)
    }
}

private struct RequestHelpCategorySelectionView: View {
    @State private var selectedCategory: HelpCategory?

    private let categories: [SwipeSelectionOption<HelpCategory>] = [
        SwipeSelectionOption(
            id: "requestHelp.category.location",
            value: HelpCategory(title: "Escort", detail: "In-person guidance to classrooms, offices, dorms, or building entrances", color: AccessAbilityTheme.navigationBlue, icon: "figure.walk.circle.fill"),
            direction: .up,
            title: "Escort",
            detail: "In-person guidance to classrooms, offices, dorms, or building entrances",
            color: AccessAbilityTheme.navigationBlue,
            icon: "figure.walk.circle.fill"
        ),
        SwipeSelectionOption(
            id: "requestHelp.category.reading",
            value: HelpCategory(title: "Reading", detail: "Visual assistance for syllabi, whiteboard notes, flyers, or library materials", color: AccessAbilityTheme.readingGreen, icon: "text.viewfinder"),
            direction: .right,
            title: "Reading",
            detail: "Visual assistance for syllabi, whiteboard notes, flyers, or library materials",
            color: AccessAbilityTheme.readingGreen,
            icon: "text.viewfinder"
        ),
        SwipeSelectionOption(
            id: "requestHelp.category.dining",
            value: HelpCategory(title: "Dining", detail: "Navigate cafeteria, read menus, identify food stations, or find seating", color: Color(red: 0.04, green: 0.48, blue: 0.60), icon: "fork.knife.circle.fill"),
            direction: .left,
            title: "Dining",
            detail: "Navigate cafeteria, read menus, identify food stations, or find seating",
            color: Color(red: 0.04, green: 0.48, blue: 0.60),
            icon: "fork.knife.circle.fill"
        ),
        SwipeSelectionOption(
            id: "requestHelp.category.other",
            value: HelpCategory(title: "Other", detail: "Any assistance not covered by the other categories", color: AccessAbilityTheme.helpRed, icon: "person.wave.2.fill"),
            direction: .down,
            title: "Other",
            detail: "Any assistance not covered by the other categories",
            color: AccessAbilityTheme.helpRed,
            icon: "person.wave.2.fill"
        )
    ]

    var body: some View {
        SwipeSelectionPad(
            title: "What kind of Assistance",
            prompt: "Choose a category.",
            accessibilityIdentifier: "requestHelp.categoryPad",
            options: categories
        ) { category in
            selectedCategory = category
        }
        .navigationDestination(item: $selectedCategory) { category in
            RequestHelpUrgencySelectionView(category: category)
        }
        .onAppear {
            SpeechManager.shared.speak(
                "Request Help. Press the center, then swipe up for Escort, right for Reading, left for Dining, or down for Other.",
                interrupt: true
            )
        }
    }
}

private struct RequestHelpUrgencySelectionView: View {
    let category: HelpCategory
    @State private var selectedUrgency: HelpUrgency?

    private var urgencyOptions: [SwipeSelectionOption<HelpUrgency>] {
        [
            SwipeSelectionOption(
                id: "requestHelp.urgency.urgent",
                value: .urgent,
                direction: .up,
                title: HelpUrgency.urgent.title,
                detail: HelpUrgency.urgent.detail,
                color: HelpUrgency.urgent.color,
                icon: HelpUrgency.urgent.icon
            ),
            SwipeSelectionOption(
                id: "requestHelp.urgency.notUrgent",
                value: .notUrgent,
                direction: .down,
                title: HelpUrgency.notUrgent.title,
                detail: HelpUrgency.notUrgent.detail,
                color: HelpUrgency.notUrgent.color,
                icon: HelpUrgency.notUrgent.icon
            )
        ]
    }

    var body: some View {
        SwipeSelectionPad(
            title: "How urgent is it?",
            prompt: "Choose urgency.",
            accessibilityIdentifier: "requestHelp.urgencyPad",
            options: urgencyOptions
        ) { urgency in
            selectedUrgency = urgency
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedUrgency) { urgency in
            RequestHelpAudioDetailsView(category: category, urgency: urgency)
        }
        .onAppear {
            SpeechManager.shared.speak(
                "Choose urgency. Press the center, then swipe up for urgent, or down for not urgent.",
                interrupt: true
            )
        }
    }
}

private struct RequestHelpAudioDetailsView: View {
    let category: HelpCategory
    let urgency: HelpUrgency

    @StateObject private var audioRecorder = AudioRecorder()
    @State private var isPressing = false
    @State private var pulse = false
    @State private var submittedRequest: AssistanceRequest?
    @State private var showingSubmitConfirmation = false

    var body: some View {
        ZStack {
            (isPressing ? Color.gray.opacity(0.7) : urgency.color)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                ZStack {
                    Circle()
                        .stroke(.white.opacity(isPressing ? 0.36 : 0.12), lineWidth: 10)
                        .frame(width: 164, height: 164)
                        .scaleEffect(isPressing && pulse ? 1.18 : 1)
                        .opacity(isPressing && pulse ? 0.35 : 1)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulse)

                    Image(systemName: isPressing ? "mic.fill" : (audioRecorder.hasRecording ? "checkmark.circle.fill" : "mic.circle.fill"))
                        .font(.system(size: 112, weight: .bold))
                        .foregroundStyle(.white)
                        .scaleEffect(isPressing ? 1.12 : 1)
                        .animation(.easeInOut(duration: 0.15), value: isPressing)
                }

                Text(isPressing ? "Recording...\nRelease to send" : "Press and hold anywhere to record")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)
                    .padding(.horizontal, 24)

                Text("\(urgency.title) request: \(category.title)")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.84))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Text("Your audio note will be attached to the request when you release.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.78))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)

                Spacer()
            }
        }
        .contentShape(Rectangle())
        .highPriorityGesture(recordingGesture)
        .navigationTitle("Record Details")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("requestHelp.audioDetails")
        .alert("Request Submitted", isPresented: $showingSubmitConfirmation) {
            Button("OK") { }
        } message: {
            Text("Your \(urgency.title.lowercased()) request for \(category.title.lowercased()) has been submitted.")
        }
        .onAppear {
            audioRecorder.requestPermission()
            SpeechManager.shared.speak(
                "Press and hold anywhere on the screen to record details. Release to submit your request.",
                interrupt: true
            )
        }
        .onDisappear {
            SpeechManager.shared.stop()
        }
    }

    private var recordingGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                guard !isPressing else { return }
                isPressing = true
                pulse = true
                SpeechManager.shared.stop()
                audioRecorder.startRecording()
            }
            .onEnded { _ in
                guard isPressing else { return }
                isPressing = false
                pulse = false
                let audioURL = audioRecorder.stopRecording()
                submitRequest(audioURL: audioURL)
            }
    }

    private func submitRequest(audioURL: URL?) {
        submittedRequest = AssistanceRequest(category: category.title, urgency: urgency.title, audioFileURL: audioURL)
        showingSubmitConfirmation = true
        SpeechManager.shared.speak("Your request has been submitted.", interrupt: true)
    }
}

private struct HelpCategory: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let detail: String
    let color: Color
    let icon: String

    static func == (lhs: HelpCategory, rhs: HelpCategory) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

private enum HelpUrgency: String, Identifiable, Hashable {
    case urgent
    case notUrgent

    var id: String { rawValue }

    var title: String {
        switch self {
        case .urgent: "Urgent"
        case .notUrgent: "Not Urgent"
        }
    }

    var detail: String {
        switch self {
        case .urgent: "For immediate needs, active disorientation, safety concerns, or help needed right now"
        case .notUrgent: "For lower priority tasks or scheduling future help"
        }
    }

    var color: Color {
        switch self {
        case .urgent: AccessAbilityTheme.helpRed
        case .notUrgent: AccessAbilityTheme.readingGreen
        }
    }

    var icon: String {
        switch self {
        case .urgent: "exclamationmark.triangle.fill"
        case .notUrgent: "calendar.badge.clock"
        }
    }
}

#Preview {
    NavigationStack {
        RequestHelpFlowView()
    }
}
