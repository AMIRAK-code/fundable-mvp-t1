import ActivityKit
import SwiftData
import SwiftUI

/// Deep-focus timer for a routine section. Runs a Live Activity so the
/// countdown lives on the Lock Screen and in the Dynamic Island; completed
/// minutes are logged as a FocusSession and feed the weekly review.
struct FocusTimerView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let sectionName: String
    let symbol: String
    let colorName: String

    @State private var minutes = 25
    @State private var startDate: Date?
    @State private var endDate: Date?
    @State private var activity: Activity<FocusActivityAttributes>?
    @State private var finishedPulse = 0

    private var color: Color { ThemeColor.color(for: colorName) }

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Spacer()
                Image(systemName: symbol)
                    .font(.system(size: 44))
                    .foregroundStyle(color)
                Text(sectionName)
                    .font(.title2.bold())

                if let startDate, let endDate {
                    Text(timerInterval: startDate...endDate, countsDown: true)
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .multilineTextAlignment(.center)
                    Text("Phone down. Eyes forward.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button("End session early") {
                        endSession(completed: false)
                    }
                    .buttonStyle(.glass)
                } else {
                    Picker("Length", selection: $minutes) {
                        Text("25 min").tag(25)
                        Text("50 min").tag(50)
                        Text("90 min").tag(90)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 24)
                    Button {
                        start()
                    } label: {
                        Label("Start focus session", systemImage: "timer")
                            .font(.headline)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.glassProminent)
                }
                Spacer()
                Spacer()
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(AppBackground())
            .navigationTitle("Focus")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        if endDate != nil {
                            endSession(completed: false)
                        }
                        dismiss()
                    }
                }
            }
            .task(id: endDate) {
                // Auto-finish when the countdown hits zero.
                guard let endDate else { return }
                let remaining = endDate.timeIntervalSinceNow
                if remaining > 0 {
                    try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
                }
                if !Task.isCancelled, self.endDate == endDate {
                    endSession(completed: true)
                }
            }
            .sensoryFeedback(.success, trigger: finishedPulse)
        }
        .interactiveDismissDisabled(endDate != nil)
    }

    private func start() {
        let now = Date.now
        let end = now.addingTimeInterval(Double(minutes) * 60)
        startDate = now
        endDate = end

        let attributes = FocusActivityAttributes(sectionName: sectionName, symbol: symbol, colorName: colorName)
        let state = FocusActivityAttributes.ContentState(startDate: now, endDate: end)
        // Live Activities can be disabled system-wide; the in-app timer works either way.
        activity = try? Activity.request(
            attributes: attributes,
            content: ActivityContent(state: state, staleDate: end)
        )
    }

    private func endSession(completed: Bool) {
        if let startDate {
            let elapsed = min(Date.now.timeIntervalSince(startDate), Double(minutes) * 60)
            let loggedMinutes = completed ? minutes : Int(elapsed / 60)
            if loggedMinutes >= 1 {
                context.insert(FocusSession(sectionName: sectionName, minutes: loggedMinutes))
                try? context.save()
            }
        }
        if let activity {
            let finalState = FocusActivityAttributes.ContentState(
                startDate: startDate ?? .now,
                endDate: .now
            )
            Task {
                await activity.end(ActivityContent(state: finalState, staleDate: nil), dismissalPolicy: .immediate)
            }
        }
        activity = nil
        startDate = nil
        endDate = nil
        if completed {
            finishedPulse += 1
        }
    }
}
