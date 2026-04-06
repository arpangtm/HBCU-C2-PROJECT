import SwiftUI

struct IdentifyObjectView: View {
    var body: some View {
        ScanSurroundingsView()
        .accessibilityIdentifier("identifyObject.screen")
    }
}
