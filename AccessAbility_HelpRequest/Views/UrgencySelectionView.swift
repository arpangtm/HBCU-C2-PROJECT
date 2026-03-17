import SwiftUI

struct UrgencySelectionView: View {
    let category: String
    @State private var selectedUrgency: String?
    @State private var navigateToDetails = false

    var body: some View {
        VStack(spacing: 0) {
            UrgencyButton(
                title: "Urgent",
                hint: "For immediate needs, active disorientation, safety concerns, or help needed right now",
                color: .red
            ) {
                selectUrgency("Urgent")
            }

            UrgencyButton(
                title: "Not Urgent",
                hint: "For lower priority tasks or scheduling future help",
                color: .green
            ) {
                selectUrgency("Not Urgent")
            }
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(false)
        .navigationDestination(isPresented: $navigateToDetails) {
            AudioDetailsView(category: category, urgency: selectedUrgency ?? "")
        }
        .onAppear {
            ScreenVoiceGuide.shared.speak(
                "If urgent, tap the top half of the screen. If not urgent, tap the bottom half of the screen."
            )
        }
        .onDisappear {
            ScreenVoiceGuide.shared.stop()
        }
    }

    private func selectUrgency(_ urgency: String) {
        selectedUrgency = urgency
        navigateToDetails = true
    }
}

struct UrgencyButton: View {
    let title: String
    let hint: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(color)
        }
        .accessibilityLabel(title)
        .accessibilityHint(hint)
    }
}
