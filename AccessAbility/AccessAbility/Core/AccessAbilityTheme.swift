import SwiftUI

enum AccessAbilityTheme {
    static let background = Color.black.opacity(0.96)
    static let card = Color.white.opacity(0.09)
    static let cardStroke = Color.white.opacity(0.18)
    static let primaryText = Color.white
    static let secondaryText = Color.white.opacity(0.78)
    static let mutedText = Color.white.opacity(0.62)
    static let navigationBlue = Color(red: 0.14, green: 0.33, blue: 0.78)
    static let readingGreen = Color(red: 0.14, green: 0.54, blue: 0.28)
    static let objectOrange = Color(red: 0.83, green: 0.45, blue: 0.14)
    static let helpRed = Color(red: 0.74, green: 0.18, blue: 0.22)
    static let accentGold = Color(red: 0.93, green: 0.76, blue: 0.31)

    static func cardBackground(cornerRadius: CGFloat = 22) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(card)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(cardStroke, lineWidth: 1)
            )
    }
}
