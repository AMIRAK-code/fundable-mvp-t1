import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: PetStore
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if store.pets.isEmpty {
                OnboardingView()
            } else {
                MainTabView()
            }
        }
        .fontDesign(.rounded)
        .tint(CalmPalette.tint)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                store.handleAppActive()
            }
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
            JournalView()
                .tabItem { Label("Journal", systemImage: "book.closed.fill") }
            SymptomCheckerView()
                .tabItem { Label("Health", systemImage: "stethoscope") }
            TrendsView()
                .tabItem { Label("Trends", systemImage: "chart.xyaxis.line") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}
