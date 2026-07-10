import AppIntents

/// Siri / Shortcuts phrases. These surface automatically in the Shortcuts
/// app and Spotlight; the intents live in Shared/Intents.
struct DreamChaserShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogDietIntent(),
            phrases: [
                "Log my diet in \(.applicationName)",
                "Log my eating in \(.applicationName)",
            ],
            shortTitle: "Log diet",
            systemImageName: "fork.knife"
        )
        AppShortcut(
            intent: MarkCleaningDoneIntent(),
            phrases: [
                "I cleaned my room in \(.applicationName)",
                "Mark my space reset in \(.applicationName)",
            ],
            shortTitle: "Space reset",
            systemImageName: "sparkles"
        )
        AppShortcut(
            intent: CompleteNextMiniGoalIntent(),
            phrases: [
                "Complete my next step in \(.applicationName)",
                "Check off my next goal in \(.applicationName)",
            ],
            shortTitle: "Next mini goal",
            systemImageName: "flag.checkered"
        )
    }
}
