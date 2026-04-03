import SwiftUI

struct UrgencySelectionView: View {
    let category: String
    @State private var selectedUrgency: String?
    @State private var navigateToDetails = false

    var body: some View {
        VStack(spacing: 0) {
            UrgencyButton(
                icon: "exclamationmark.circle",
                title: "Urgent",
                subtitle: "Immediate help needed",
                hint: "For immediate needs, active disorientation, safety concerns, or help needed right now",
                tint: .red
            ) {
                selectUrgency("Urgent")
            }

            Divider()

            UrgencyButton(
                icon: "clock",
                title: "Not Urgent",
                subtitle: "Lower priority or future help",
                hint: "For lower priority tasks or scheduling future help",
                tint: Color(.systemGreen)
            ) {
                selectUrgency("Not Urgent")
            }
        }
        .background(Color(.systemBackground))
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
    let icon: String
    let title: String
    let subtitle: String
    let hint: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 44, weight: .light))
                    .foregroundColor(tint)
                Text(title)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityHint(hint)
    }
}
