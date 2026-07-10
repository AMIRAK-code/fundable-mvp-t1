import SwiftData
import SwiftUI

struct RootView: View {
    @AppStorage("hasOnboarded.v1") private var hasOnboarded = false
    @Query private var sections: [RoutineSection]

    var body: some View {
        TabView {
            Tab("Today", systemImage: "checkmark.circle.fill") {
                TodayView()
            }
            Tab("Goals", systemImage: "flag.checkered") {
                GoalsView()
            }
            Tab("Wellbeing", systemImage: "heart.fill") {
                WellbeingView()
            }
            Tab("Quotes", systemImage: "quote.opening") {
                QuotesView()
            }
            Tab("Settings", systemImage: "gearshape.fill") {
                SettingsView()
            }
        }
        // Liquid Glass tab bar melts away while scrolling content.
        .tabBarMinimizeBehavior(.onScrollDown)
        .onAppear {
            // Upgrade path: routines already exist, skip onboarding.
            if !hasOnboarded && !sections.isEmpty {
                hasOnboarded = true
            }
        }
        .fullScreenCover(isPresented: needsOnboarding) {
            OnboardingView()
        }
    }

    private var needsOnboarding: Binding<Bool> {
        Binding(
            get: { !hasOnboarded },
            set: { presented in
                if !presented { hasOnboarded = true }
            }
        )
    }
}
