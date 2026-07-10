import SwiftData
import SwiftUI
import WidgetKit

struct SettingsView: View {
    @Environment(\.modelContext) private var context

    @AppStorage(NotificationService.Keys.cleaningEnabled) private var cleaningReminder = true
    @AppStorage(NotificationService.Keys.cleaningWeekday) private var cleaningWeekday = 1
    @AppStorage(NotificationService.Keys.morningKickoff) private var morningKickoff = false

    @State private var showingResetConfirmation = false

    private let weekdays = [
        (1, "Sunday"), (2, "Monday"), (3, "Tuesday"), (4, "Wednesday"),
        (5, "Thursday"), (6, "Friday"), (7, "Saturday"),
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Reminders") {
                    Toggle("Weekly cleaning reminder", isOn: $cleaningReminder)
                    if cleaningReminder {
                        Picker("Reminder day", selection: $cleaningWeekday) {
                            ForEach(weekdays, id: \.0) { value, name in
                                Text(name).tag(value)
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
                Section("Data") {
                    Button("Reset all data", role: .destructive) {
                        showingResetConfirmation = true
                    }
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
        try? context.save()
        SharedStore.seedIfNeeded(in: context.container)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
