import SwiftData
import SwiftUI

/// Weekly "reset your space" prompt. Appears on Today when the task is due;
/// the user can log it as done now, say they already did it, or snooze.
struct CleaningPromptCard: View {
    @Environment(\.modelContext) private var context
    var task: CleaningTask

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Time to reset your space", systemImage: "sparkles")
                .font(.headline)
            Text("A clean environment keeps your mind sharp. 20 minutes is all it takes.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(spacing: 10) {
                Button("Done today") {
                    task.markDone()
                    save()
                }
                .buttonStyle(.glassProminent)

                Button("Already did it") {
                    let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now
                    task.markDone(on: yesterday)
                    save()
                }
                .buttonStyle(.glass)

                Button("Later") {
                    task.snooze(days: 1)
                    save()
                }
                .buttonStyle(.glass)
            }
            .font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(tint: .teal)
    }

    private func save() {
        try? context.save()
    }
}
