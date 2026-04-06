import Combine
import Foundation

final class AppState: ObservableObject {
    static let shared = AppState()

    private let defaults = UserDefaults.standard
    private let userNameKey = "accessAbility.userName"
    private let studentIdKey = "accessAbility.studentId"

    @Published var userName: String {
        didSet { defaults.set(userName, forKey: userNameKey) }
    }

    @Published var studentId: String {
        didSet { defaults.set(studentId, forKey: studentIdKey) }
    }

    private init() {
        userName = defaults.string(forKey: userNameKey) ?? ""
        studentId = defaults.string(forKey: studentIdKey) ?? ""
    }

    func completeOnboarding(name: String, studentId: String) {
        userName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.studentId = studentId.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func resetProfile() {
        userName = ""
        studentId = ""
    }
}
