//
//  AppState.swift
//  HBCUAccessibility
//

import SwiftUI

final class AppState: ObservableObject {
    static let shared = AppState()

    private let defaults = UserDefaults.standard
    private let keyOnboardingComplete = "hasCompletedOnboarding"
    private let keyUserName = "userName"
    private let keyStudentId = "studentId"

    @Published var hasCompletedOnboarding: Bool {
        didSet { defaults.set(hasCompletedOnboarding, forKey: keyOnboardingComplete) }
    }

    @Published var userName: String {
        didSet { defaults.set(userName, forKey: keyUserName) }
    }

    @Published var studentId: String {
        didSet { defaults.set(studentId, forKey: keyStudentId) }
    }

    init() {
        self.hasCompletedOnboarding = defaults.bool(forKey: keyOnboardingComplete)
        self.userName = defaults.string(forKey: keyUserName) ?? ""
        self.studentId = defaults.string(forKey: keyStudentId) ?? ""
    }

    func completeOnboarding(name: String, studentId: String) {
        userName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.studentId = studentId.trimmingCharacters(in: .whitespacesAndNewlines)
        // Demo mode: do not persist skipping onboarding across app relaunches.
        hasCompletedOnboarding = false
    }

    func signOut() {
        hasCompletedOnboarding = false
        userName = ""
        studentId = ""
    }
}
