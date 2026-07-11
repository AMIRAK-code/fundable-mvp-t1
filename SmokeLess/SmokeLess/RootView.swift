import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        Group {
            if store.state.onboardingComplete {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .sheet(isPresented: $store.showCravingSOS) {
            CravingSOSView()
                .environmentObject(store)
        }
        .animation(.easeInOut, value: store.state.onboardingComplete)
    }
}

struct MainTabView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        TabView(selection: $store.selectedTab) {
            DashboardView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(AppTab.home)

            JournalView()
                .tabItem { Label("Journal", systemImage: "book.fill") }
                .tag(AppTab.journal)

            WishlistView()
                .tabItem { Label("Wishlist", systemImage: "gift.fill") }
                .tag(AppTab.wishlist)

            LearnView()
                .tabItem { Label("Learn", systemImage: "lightbulb.fill") }
                .tag(AppTab.learn)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(AppTab.settings)
        }
    }
}
