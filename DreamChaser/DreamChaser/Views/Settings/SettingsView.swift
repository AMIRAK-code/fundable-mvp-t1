import SwiftData
import SwiftUI
import WidgetKit

struct SettingsView: View {
    @Environment(\.modelContext) private var context

    @AppStorage(NotificationService.Keys.cleaningEnabled) private var cleaningReminder = true
    @AppStorage(NotificationService.Keys.cleaningWeekday) private var cleaningWeekday = 1
    @AppStorage(NotificationService.Keys.morningKickoff) private var morningKickoff = false
    @AppStorage("hasOnboarded.v1") private var hasOnboarded = false

    @State private var showingResetConfirmation = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Reminders") {
                    Toggle("Weekly cleaning reminder", isOn: $cleaningReminder)
                    if cleaningReminder {
                        Picker("Reminder day", selection: $cleaningWeekday) {
                            ForEach(1...7, id: \.self) { weekday in
                                Text(Calendar.current.weekdaySymbols[weekday - 1]).tag(weekday)
                            }
                        }
                    }
                    Toggle("Morning kickoff quote (7 AM)", isOn: $morningKickoff)
                }
                Section("Apple Health") {
                    Text("Dream Chaser reads steps, active energy, exercise minutes, and sleep. Manage access in the Health app → Sharing → Apps.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Section("Quotes") {
                    Text("The daily quote comes from the bundled library (Shared/Quotes/quotes-seed.json — replace it with your own database) and refreshes from the internet once a day.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Section("Momentum") {
                    LabeledContent("Streak freeze tokens", value: "\(MomentumEngine.tokens)")
                    Text("Earn one per perfect week (max 3). A token is spent automatically to protect your streak when you miss a day.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Section("Siri & Shortcuts") {
                    Text("Try: “Log my diet”, “I cleaned my room”, or “Complete my next step” — followed by “in Dream Chaser”.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Section("Data") {
                    Button("Reset all data", role: .destructive) {
                        showingResetConfirmation = true
                    }
                    Text("Everything is stored on this device. To sync across devices later, enable the iCloud capability and CloudKit-ready models — see DESIGN.md.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Section("About") {
                    LabeledContent("App", value: "Dream Chaser")
                    LabeledContent("Version", value: "0.1 (MVP)")
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog(
                "This deletes every section, goal, and check-in, then restores the defaults.",
                isPresented: $showingResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Reset everything", role: .destructive, action: resetAllData)
            }
            .onChange(of: cleaningReminder) { syncNotifications() }
            .onChange(of: cleaningWeekday) { syncNotifications() }
            .onChange(of: morningKickoff) { syncNotifications() }
        }
    }

    private func syncNotifications() {
        Task {
            if await NotificationService.requestPermission() {
                await NotificationService.syncSchedules()
            }
        }
    }

    private func resetAllData() {
        try? context.delete(model: RoutineSection.self)
        try? context.delete(model: RoutineItem.self)
        try? context.delete(model: UltimateGoal.self)
        try? context.delete(model: MiniGoal.self)
        try? context.delete(model: DietDay.self)
        try? context.delete(model: SkincareStep.self)
        try? context.delete(model: CleaningTask.self)
        try? context.delete(model: JournalEntry.self)
        try? context.delete(model: FocusSession.self)
        try? context.delete(model: ProgressPhoto.self)
        try? context.save()
        SharedStore.seedIfNeeded(in: context.container)
        MomentumEngine.tokens = 0
        MomentumEngine.protectedDates = []
        // Send the user back through the template picker.
        hasOnboarded = false
        WidgetCenter.shared.reloadAllTimelines()
    }
}
