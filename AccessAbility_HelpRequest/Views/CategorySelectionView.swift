import SwiftUI

struct CategorySelectionView: View {
    @State private var selectedCategory: String?
    @State private var navigateToUrgency = false

    let categories = [
        ("location",      "Finding a Location",     "Navigation and wayfinding to classrooms, offices, dorms, or building entrances"),
        ("doc.text",      "Reading Materials",       "Visual assistance for syllabi, whiteboard notes, flyers, or library materials"),
        ("fork.knife",    "Dining Hall Assistance",  "Navigate cafeteria, read menus, identify food stations, or find seating"),
        ("ellipsis.circle","Other Request",          "Any assistance not covered by the other categories")
    ]

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        CategoryButton(icon: categories[0].0, title: categories[0].1, hint: categories[0].2) {
                            selectCategory(categories[0].1)
                        }
                        Divider()
                        CategoryButton(icon: categories[1].0, title: categories[1].1, hint: categories[1].2) {
                            selectCategory(categories[1].1)
                        }
                    }
                    .frame(height: geo.size.height / 2)

                    Divider()

                    HStack(spacing: 0) {
                        CategoryButton(icon: categories[2].0, title: categories[2].1, hint: categories[2].2) {
                            selectCategory(categories[2].1)
                        }
                        Divider()
                        CategoryButton(icon: categories[3].0, title: categories[3].1, hint: categories[3].2) {
                            selectCategory(categories[3].1)
                        }
                    }
                    .frame(height: geo.size.height / 2)
                }
            }
            .background(Color(.systemBackground))
            .ignoresSafeArea()
            .navigationDestination(isPresented: $navigateToUrgency) {
                UrgencySelectionView(category: selectedCategory ?? "")
            }
        }
        .onAppear {
            ScreenVoiceGuide.shared.speak(
                "There are 4 sections. Tap top left for Finding a Location. Tap top right for Reading Materials. Tap bottom left for Dining Hall Assistance. Tap bottom right for Other Request."
            )
        }
        .onDisappear {
            ScreenVoiceGuide.shared.stop()
        }
    }

    private func selectCategory(_ category: String) {
        selectedCategory = category
        navigateToUrgency = true
    }
}

struct CategoryButton: View {
    let icon: String
    let title: String
    let hint: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 36, weight: .light))
                    .foregroundColor(.accentColor)
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityHint(hint)
    }
}
