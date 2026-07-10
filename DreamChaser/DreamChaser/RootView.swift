import SwiftUI

struct RootView: View {
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
    }
}
