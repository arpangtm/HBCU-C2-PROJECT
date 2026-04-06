import SwiftUI

struct SupportPlaceholderScreen: View {
    let title: String
    let systemImage: String
    let message: String
    let screenIdentifier: String

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color(red: 0.14, green: 0.14, blue: 0.18)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: systemImage)
                    .font(.system(size: 60, weight: .bold))
                    .foregroundStyle(.white)
                Text(title)
                    .font(.title.weight(.bold))
                    .foregroundStyle(.white)
                Text(message)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.86))
                    .padding(.horizontal, 24)
            }
            .padding(28)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.white.opacity(0.08))
            )
            .padding(24)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier(screenIdentifier)
        .onAppear {
            SpeechManager.shared.speak(message, interrupt: true)
        }
        .onDisappear {
            SpeechManager.shared.stop()
        }
    }
}
