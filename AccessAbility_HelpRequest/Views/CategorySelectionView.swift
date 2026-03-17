import SwiftUI

struct CategorySelectionView: View {
    @State private var selectedCategory: String?
    @State private var navigateToUrgency = false

    let categories = [
        ("Finding a Location",    "Navigation and wayfinding to classrooms, offices, dorms, or building entrances"),
        ("Reading Materials",     "Visual assistance for syllabi, whiteboard notes, flyers, or library materials"),
        ("Dining Hall Assistance","Navigate cafeteria, read menus, identify food stations, or find seating"),
        ("Other Request",         "Any assistance not covered by the other categories")
    ]

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        CategoryButton(title: categories[0].0, hint: categories[0].1, color: .blue) {
                            selectCategory(categories[0].0)
                        }
                        CategoryButton(title: categories[1].0, hint: categories[1].1, color: Color(red: 0.1, green: 0.4, blue: 0.8)) {
                            selectCategory(categories[1].0)
                        }
                    }
                    .frame(height: geo.size.height / 2)

                    HStack(spacing: 0) {
                        CategoryButton(title: categories[2].0, hint: categories[2].1, color: Color(red: 0.0, green: 0.5, blue: 0.7)) {
                            selectCategory(categories[2].0)
                        }
                        CategoryButton(title: categories[3].0, hint: categories[3].1, color: Color(red: 0.2, green: 0.3, blue: 0.7)) {
                            selectCategory(categories[3].0)
                        }
                    }
                    .frame(height: geo.size.height / 2)
                }
            }
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
    let title: String
    let hint: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(12)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(color)
                .border(Color.white, width: 2)
        }
        .accessibilityLabel(title)
        .accessibilityHint(hint)
    }
}
