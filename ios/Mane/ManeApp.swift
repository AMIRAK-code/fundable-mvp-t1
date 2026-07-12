import SwiftUI

@main
struct ManeApp: App {
    @StateObject private var theme = ThemeManager()
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(theme)
                .environmentObject(model)
                .tint(theme.palette.accent)
                .preferredColorScheme(theme.palette.colorScheme)
        }
    }
}
