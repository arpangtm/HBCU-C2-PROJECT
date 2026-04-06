import SwiftUI

struct ReadSignsView: View {
    var body: some View {
        ScanSurroundingsView()
        .accessibilityIdentifier("readSigns.screen")
    }
}
