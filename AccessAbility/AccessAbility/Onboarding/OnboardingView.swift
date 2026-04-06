import SwiftUI
import UIKit

struct OnboardingView: View {
    let onComplete: (String, String) -> Void

    @StateObject private var voiceInput = VoiceInputService()
    @State private var currentStep: Step = .welcome
    @State private var userNameInput = ""
    @State private var studentIdInput = ""
    @State private var showListeningCue = false
    @State private var listeningField: Field?
    @FocusState private var focusedField: Field?

    private enum Step: Int, CaseIterable {
        case welcome
        case name
        case studentId
        case howItWorks
        case complete
    }

    private enum Field {
        case name
        case studentId
    }

    var body: some View {
        ZStack {
            AccessAbilityTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                progressBar

                ScrollView {
                    VStack(spacing: 24) {
                        stepContent
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(22)
                }

                Button {
                    advance()
                } label: {
                    Text(currentStep == .complete ? "Open AccessAbility" : "Continue")
                        .font(.headline.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(canAdvance ? Color.white : Color.white.opacity(0.22))
                        .foregroundStyle(canAdvance ? Color.black : Color.white.opacity(0.72))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .disabled(!canAdvance)
                .padding(.horizontal, 22)
                .padding(.bottom, 22)
                .accessibilityIdentifier("onboarding.next")
            }
        }
        .accessibilityIdentifier("onboarding.screen")
        .contentShape(Rectangle())
        .simultaneousGesture(
            TapGesture().onEnded {
                if currentStep == .welcome || currentStep == .howItWorks || currentStep == .complete {
                    advance()
                }
            }
        )
        .onAppear {
            announceStep(currentStep)
        }
        .onChange(of: currentStep) { _, step in
            announceStep(step)
        }
        .onDisappear {
            SpeechManager.shared.stop()
            voiceInput.stopListening()
        }
    }

    private var progressBar: some View {
        HStack(spacing: 8) {
            ForEach(0..<Step.allCases.count, id: \.self) { index in
                Capsule()
                    .fill(index <= currentStep.rawValue ? AccessAbilityTheme.accentGold : Color.white.opacity(0.2))
                    .frame(height: 6)
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 18)
        .padding(.bottom, 10)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case .welcome:
            introCard(
                icon: "hand.wave.fill",
                title: "Welcome to AccessAbility",
                body: "We’ll set up your profile, then take you to the home screen where every feature is ready from one simple gesture layout."
            )
        case .name:
            inputCard(
                title: "What should we call you?",
                fieldTitle: "Your name",
                text: $userNameInput,
                field: .name,
                keyboardType: .default
            )
        case .studentId:
            inputCard(
                title: "What is your student ID?",
                fieldTitle: "Student ID",
                text: $studentIdInput,
                field: .studentId,
                keyboardType: .numberPad
            )
        case .howItWorks:
            howItWorksCard
        case .complete:
            introCard(
                icon: "checkmark.circle.fill",
                title: "You’re all set\(userNameInput.isEmpty ? "" : ", \(userNameInput)")",
                body: "Open AccessAbility to choose a feature from the home screen. You can return there after each task."
            )
        }
    }

    private func introCard(icon: String, title: String, body: String) -> some View {
        VStack(spacing: 18) {
            Image(systemName: icon)
                .font(.system(size: 58, weight: .bold))
                .foregroundStyle(AccessAbilityTheme.accentGold)

            Text(title)
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(AccessAbilityTheme.primaryText)
                .multilineTextAlignment(.center)

            Text(body)
                .font(.body)
                .foregroundStyle(AccessAbilityTheme.secondaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(AccessAbilityTheme.cardBackground())
        .accessibilityElement(children: .combine)
    }

    private func inputCard(
        title: String,
        fieldTitle: String,
        text: Binding<String>,
        field: Field,
        keyboardType: UIKeyboardType
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title2.weight(.bold))
                .foregroundStyle(AccessAbilityTheme.primaryText)

            if showListeningCue && listeningField == field {
                listeningCue
            }

            TextField(fieldTitle, text: text)
                .textFieldStyle(.plain)
                .font(.title3.weight(.semibold))
                .padding(16)
                .background(Color.white)
                .foregroundStyle(Color.black)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .keyboardType(keyboardType)
                .focused($focusedField, equals: field)
                .accessibilityIdentifier(field == .name ? "onboarding.name" : "onboarding.studentId")

            pressAndHoldVoiceControl(for: field)
            .accessibilityIdentifier(field == .name ? "onboarding.speakName" : "onboarding.speakStudentId")
        }
        .padding(22)
        .background(AccessAbilityTheme.cardBackground())
    }

    private var howItWorksCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("How AccessAbility works")
                .font(.title2.weight(.bold))
                .foregroundStyle(AccessAbilityTheme.primaryText)

            featureRow("Swipe up for Navigation and get step-by-step route guidance.", icon: "location.circle.fill")
            featureRow("Swipe left for Scan Surroundings to read text and identify nearby objects.", icon: "camera.viewfinder")
            featureRow("Swipe right for Report ADA Issue when a path, curb, ramp, or obstacle needs university review.", icon: "exclamationmark.bubble.fill")
            featureRow("Swipe down for Request Help when you need campus assistance.", icon: "person.wave.2.fill")
        }
        .padding(22)
        .background(AccessAbilityTheme.cardBackground())
    }

    private func pressAndHoldVoiceControl(for field: Field) -> some View {
        let isActive = showListeningCue && listeningField == field

        return Label(isActive ? "Listening... release to enter text" : "Press and hold to speak", systemImage: isActive ? "waveform.circle.fill" : "mic.fill")
            .font(.headline.weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isActive ? Color.white : AccessAbilityTheme.accentGold)
            .foregroundStyle(Color.black)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .scaleEffect(isActive ? 1.02 : 1)
            .animation(.easeInOut(duration: 0.15), value: isActive)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        beginVoiceInput(for: field)
                    }
                    .onEnded { _ in
                        finishVoiceInput(for: field)
                    }
            )
            .accessibilityLabel(isActive ? "Listening, release to enter text" : "Press and hold to speak")
            .accessibilityHint("Hold your finger down while speaking, then release to fill the field.")
    }

    private func featureRow(_ text: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3.weight(.bold))
                .foregroundStyle(AccessAbilityTheme.accentGold)
                .frame(width: 28)

            Text(text)
                .font(.body)
                .foregroundStyle(AccessAbilityTheme.secondaryText)
                .lineSpacing(3)
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
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var canAdvance: Bool {
        switch currentStep {
        case .welcome, .howItWorks, .complete:
            true
        case .name:
            !userNameInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .studentId:
            !studentIdInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    private func advance() {
        guard canAdvance else {
            SpeechManager.shared.speak("Please enter this field before continuing.", interrupt: true)
            return
        }

        SpeechManager.shared.stop()
        voiceInput.stopListening()
        showListeningCue = false

        switch currentStep {
        case .welcome:
            currentStep = .name
        case .name:
            currentStep = .studentId
        case .studentId:
            currentStep = .howItWorks
        case .howItWorks:
            currentStep = .complete
        case .complete:
            onComplete(userNameInput, studentIdInput)
        }
    }

    private func beginVoiceInput(for field: Field) {
        guard !(showListeningCue && listeningField == field) else { return }
        focusedField = nil
        listeningField = field
        showListeningCue = true
        SpeechManager.shared.stop()

        voiceInput.requestAuthorization { granted in
            guard listeningField == field, showListeningCue else { return }
            guard granted else {
                showListeningCue = false
                listeningField = nil
                SpeechManager.shared.speak("Microphone and speech recognition permission are needed to use voice input.", interrupt: true)
                return
            }

            voiceInput.startListening { text in
                handleVoiceInput(text, for: field)
            }
        }
    }

    private func finishVoiceInput(for field: Field) {
        guard listeningField == field else { return }
        guard voiceInput.isListening else {
            showListeningCue = false
            listeningField = nil
            voiceInput.stopListening()
            return
        }

        _ = voiceInput.finishListening()
    }

    private func handleVoiceInput(_ text: String, for field: Field) {
        showListeningCue = false
        listeningField = nil

        let cleaned = cleanVoiceInput(text, for: field)
        guard !cleaned.isEmpty else {
            SpeechManager.shared.speak("Sorry, I did not catch that. Please try again or type it.", interrupt: true)
            return
        }

        switch field {
        case .name:
            userNameInput = cleaned
            SpeechManager.shared.speak("Thank you. I heard \(cleaned).", interrupt: true)
        case .studentId:
            studentIdInput = cleaned
            SpeechManager.shared.speak("Got it.", interrupt: true)
        }
    }

    private func cleanVoiceInput(_ text: String, for field: Field) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard field == .studentId else { return trimmed }

        let digits = trimmed.filter(\.isNumber)
        return digits.isEmpty ? trimmed : String(digits)
    }

    private func announceStep(_ step: Step) {
        switch step {
        case .welcome:
            SpeechManager.shared.speak("Welcome to AccessAbility. Press anywhere on the screen or press continue to begin.", interrupt: true, delay: 0.3)
        case .name:
            SpeechManager.shared.speak("What should we call you? Type your name, or press and hold to speak it.", interrupt: true, delay: 0.2)
            focusedField = .name
        case .studentId:
            SpeechManager.shared.speak("What is your student I D? Type it, or press and hold to speak it.", interrupt: true, delay: 0.2)
            focusedField = .studentId
        case .howItWorks:
            SpeechManager.shared.speak("The home screen uses swipe gestures. Swipe up for Navigation, left for Scan Surroundings, right for Report ADA Issue, and down for Request Help. Press anywhere on the screen or press continue when ready.", interrupt: true, delay: 0.2)
        case .complete:
            SpeechManager.shared.speak("You're all set. Press open AccessAbility to go to the home screen.", interrupt: true, delay: 0.2)
        }
    }
}

#Preview {
    OnboardingView { _, _ in }
}
