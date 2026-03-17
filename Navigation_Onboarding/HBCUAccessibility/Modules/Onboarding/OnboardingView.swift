//
//  OnboardingView.swift
//  HBCUAccessibility
//
//  Voice-guided onboarding. Double-tap anywhere on the screen to continue.
//  Name and student ID from text fields. Warm, welcoming TTS.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var speech = SpeechService.shared
    @StateObject private var voiceInput = VoiceInputService()

    @State private var currentStep: Step = .welcome
    @State private var userNameInput = ""
    @State private var studentIdInput = ""
    @State private var showHome = false
    @State private var showListeningCue = false
    @State private var listeningPulse = false
    @FocusState private var focusedField: Field?

    enum Step: Int, CaseIterable {
        case welcome
        case name
        case studentId
        case howItWorks
        case complete
    }

    enum Field {
        case name, studentId
    }

    var body: some View {
        ZStack {
            Theme.cardBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                progressBar
                ScrollView {
                    VStack(spacing: 28) {
                        stepContent
                    }
                    .padding(24)
                    .padding(.bottom, 24)
                }
                continueHint
            }
        }
        .onAppear { speakWelcome() }
        .onChange(of: currentStep) { step in announceStep(step) }
        .simultaneousGesture(
            TapGesture(count: 2).onEnded {
                handleDoubleTap()
            }
        )
        .fullScreenCover(isPresented: $showHome) {
            HomePlaceholderView()
                .environmentObject(appState)
        }
    }

    private var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(0..<Step.allCases.count - 1, id: \.self) { i in
                Capsule()
                    .fill(i <= currentStep.rawValue ? Theme.fiskGold : Theme.fiskNavy.opacity(0.2))
                    .frame(height: 5)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 8)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case .welcome:
            welcomeContent
        case .name:
            nameContent
        case .studentId:
            studentIdContent
        case .howItWorks:
            howItWorksContent
        case .complete:
            completeContent
        }
    }

    private var welcomeContent: some View {
        VStack(spacing: 20) {
            Image(systemName: "hand.wave.fill")
                .font(.system(size: 56))
                .foregroundStyle(Theme.fiskGold)
            Text("Welcome to Fisk Accessibility")
                .font(.title.weight(.bold))
                .foregroundStyle(Theme.fiskNavy)
                .multilineTextAlignment(.center)
            Text("We're so glad you're here. This app will help you get around campus and get help when you need it. Let's get you set up — it'll only take a moment.")
                .font(.body)
                .foregroundStyle(Theme.subtleText)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Welcome to Fisk Accessibility. We're so glad you're here. When you're ready, double-tap anywhere on the screen to continue.")
    }

    private var nameContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("What should we call you?")
                .font(.title2.weight(.bold))
                .foregroundStyle(Theme.fiskNavy)
            if showListeningCue || voiceInput.isListening {
                listeningCueView
            }
            TextField("Your name", text: $userNameInput)
                .textFieldStyle(.plain)
                .padding(14)
                .background(Color.white.opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.fiskNavy.opacity(0.3), lineWidth: 1))
                .textContentType(.name)
                .focused($focusedField, equals: .name)
                .accessibilityLabel("Your name")
                .accessibilityHint("Enter your name. Double-tap anywhere on the screen when done to continue.")
            Button {
                startVoiceForName()
            } label: {
                Text(showListeningCue || voiceInput.isListening ? "Listening…" : "Tap to speak")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(showListeningCue || voiceInput.isListening ? Theme.fiskGold.opacity(0.3) : Theme.fiskNavy)
                    .foregroundStyle(showListeningCue || voiceInput.isListening ? Theme.fiskNavy : .white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .disabled(showListeningCue || voiceInput.isListening)
            .accessibilityLabel("Tap to speak your name")
            .accessibilityHint("Double-tap to start listening and say your name")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 20)
        .accessibilityElement(children: .contain)
    }

    private var studentIdContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("What's your student ID?")
                .font(.title2.weight(.bold))
                .foregroundStyle(Theme.fiskNavy)
            if showListeningCue || voiceInput.isListening {
                listeningCueView
            }
            TextField("Student ID", text: $studentIdInput)
                .textFieldStyle(.plain)
                .padding(14)
                .background(Color.white.opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.fiskNavy.opacity(0.3), lineWidth: 1))
                .keyboardType(.numberPad)
                .textContentType(.username)
                .focused($focusedField, equals: .studentId)
                .accessibilityLabel("Student I D")
                .accessibilityHint("Enter your student I D. Double-tap anywhere on the screen when done to continue.")
            Button {
                startVoiceForStudentId()
            } label: {
                Text(showListeningCue || voiceInput.isListening ? "Listening…" : "Tap to speak")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(showListeningCue || voiceInput.isListening ? Theme.fiskGold.opacity(0.3) : Theme.fiskNavy)
                    .foregroundStyle(showListeningCue || voiceInput.isListening ? Theme.fiskNavy : .white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .disabled(showListeningCue || voiceInput.isListening)
            .accessibilityLabel("Tap to speak your student ID")
            .accessibilityHint("Double-tap to start listening and say your student ID")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 20)
        .accessibilityElement(children: .contain)
    }

    private var howItWorksContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Here's how the app works")
                .font(.title2.weight(.bold))
                .foregroundStyle(Theme.fiskNavy)
            VStack(alignment: .leading, spacing: 14) {
                bullet("Swipe right to request help from campus security or a volunteer. Your location is sent so someone can find you.")
                bullet("Swipe up to open the camera to scan signs and hear what's around you.")
                bullet("Swipe down for indoor navigation. Choose a building or use your location; we'll guide you step by step with voice.")
                bullet("Press and hold anywhere to talk to the voice assistant.")
            }
            .font(.body)
            .foregroundStyle(Theme.subtleText)
        }
        .padding(.top, 20)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Here's how the app works. Swipe right for help. Swipe up for camera. Swipe down for indoor navigation. Press and hold for voice assistant. When you're ready, double-tap anywhere on the screen to continue.")
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "circle.fill")
                .font(.system(size: 6))
                .foregroundStyle(Theme.fiskGold)
            Text(text)
        }
    }

    private var completeContent: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(Theme.fiskGold)
            Text("You're all set, \(userNameInput.isEmpty ? "there" : userNameInput)")
                .font(.title2.weight(.bold))
                .foregroundStyle(Theme.fiskNavy)
                .multilineTextAlignment(.center)
            Text("Double-tap anywhere on the screen to open the app.")
                .font(.body)
                .foregroundStyle(Theme.subtleText)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 24)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("You're all set. Double-tap anywhere on the screen to open the app.")
    }

    private var continueHint: some View {
        Text("Double-tap anywhere to continue")
            .font(.subheadline)
            .foregroundStyle(Theme.subtleText)
            .padding(.bottom, 20)
            .accessibilityHidden(true)
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

    private func handleDoubleTap() {
        speech.stop()
        voiceInput.stopListening()
        showListeningCue = false

        switch currentStep {
        case .welcome:
            currentStep = .name
        case .name:
            guard !userNameInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
            currentStep = .studentId
        case .studentId:
            guard !studentIdInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
            currentStep = .howItWorks
        case .howItWorks:
            currentStep = .complete
        case .complete:
            appState.completeOnboarding(name: userNameInput, studentId: studentIdInput)
            showHome = true
        }
    }

    private func startVoiceForName() {
        speech.stop()
        voiceInput.requestAuthorization { _ in }
        showListeningCue = true
        focusedField = nil
        // Don't speak while listening (TTS can get transcribed).
        voiceInput.startListening { [self] text in
            showListeningCue = false
            let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !cleaned.isEmpty {
                userNameInput = cleaned
                speech.speak("Thank you. I heard \(cleaned).")
            } else {
                speech.speak("Sorry, I didn't catch that. Please try again.")
            }
        }
    }

    private func startVoiceForStudentId() {
        speech.stop()
        voiceInput.requestAuthorization { _ in }
        showListeningCue = true
        focusedField = nil
        voiceInput.startListening { [self] text in
            showListeningCue = false
            // Keep only digits from transcription (e.g. \"one two three\" may come as \"123\" or words).
            let digits = text.compactMap { $0.isNumber ? $0 : nil }
            let cleaned = String(digits)
            if !cleaned.isEmpty {
                studentIdInput = cleaned
                speech.speak("Got it.")
            } else {
                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    studentIdInput = trimmed
                    speech.speak("Got it.")
                } else {
                    speech.speak("Sorry, I didn't catch that. Please try again.")
                }
            }
        }
    }

    private func speakWelcome() {
        speech.speak("Welcome to Fisk Accessibility. We're so glad you're here. This app will help you get around campus. When you're ready, double-tap anywhere on the screen to continue.")
    }

    private func announceStep(_ step: Step) {
        switch step {
        case .welcome:
            break
        case .name:
            voiceInput.requestAuthorization { _ in }
            speech.speak("We'd love to know what to call you. Tap to speak your name. When you're ready, double-tap anywhere on the screen to continue.")
            focusedField = .name
        case .studentId:
            voiceInput.requestAuthorization { _ in }
            speech.speak("Now we need your student I D. Tap to speak your student I D. When you're ready, double-tap anywhere on the screen to continue.")
            focusedField = .studentId
        case .howItWorks:
            speech.speak("Here's how the app works. Swipe right for help. Swipe up for the camera. Swipe down for indoor navigation. Press and hold for the voice assistant. When you're ready, double-tap anywhere on the screen to continue.")
        case .complete:
            speech.speak("You're all set. Double-tap anywhere on the screen to open the app.")
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState.shared)
}
