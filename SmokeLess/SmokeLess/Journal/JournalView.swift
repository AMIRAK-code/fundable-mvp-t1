import SwiftUI

struct JournalView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showLogSlip = false

    var body: some View {
        NavigationStack {
            List {
                Section("Last 7 days") {
                    WeekChart()
                        .frame(height: 140)
                        .listRowBackground(Color(.secondarySystemGroupedBackground))
                }

                Section {
                    Button {
                        showLogSlip = true
                    } label: {
                        Label("Log a slip", systemImage: "plus.circle.fill")
                    }
                }

                Section("History") {
                    if events.isEmpty {
                        Text("Nothing logged yet. Slips and beaten cravings show up here.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(events) { event in
                        eventRow(event)
                    }
                }
            }
            .navigationTitle("Journal")
            .sheet(isPresented: $showLogSlip) {
                LogSlipSheet()
                    .environmentObject(store)
            }
        }
    }

    // MARK: Events

    private struct JournalEvent: Identifiable {
        enum Kind {
            case slip(SlipEntry)
            case resisted(Date)
        }
        let id: String
        let date: Date
        let kind: Kind
    }

    private var events: [JournalEvent] {
        var all: [JournalEvent] = store.state.slips.map { slip in
            JournalEvent(id: "slip-\(slip.id.uuidString)", date: slip.date, kind: .slip(slip))
        }
        for (index, date) in store.state.resistedCravings.enumerated() {
            all.append(JournalEvent(id: "resist-\(index)-\(date.timeIntervalSince1970)", date: date, kind: .resisted(date)))
        }
        return all.sorted { $0.date > $1.date }
    }

    @ViewBuilder
    private func eventRow(_ event: JournalEvent) -> some View {
        switch event.kind {
        case .slip(let slip):
            HStack {
                Image(systemName: "smoke.fill")
                    .foregroundStyle(.red)
                VStack(alignment: .leading) {
                    Text("\(slip.units.formatted(.number.precision(.fractionLength(0...1)))) \(slip.units == 1 ? store.state.profile.smokingType.unitSingular : store.state.profile.smokingType.unitPlural)")
                        .font(.subheadline)
                    if let note = slip.note, !note.isEmpty {
                        Text(note)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(slip.date, format: .dateTime.day().month().hour().minute())
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
            }
            .swipeActions {
                Button(role: .destructive) {
                    store.removeSlip(id: slip.id)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        case .resisted(let date):
            HStack {
                Image(systemName: "hand.raised.fill")
                    .foregroundStyle(store.theme.primary)
                VStack(alignment: .leading) {
                    Text("Craving beaten")
                        .font(.subheadline)
                    Text(date, format: .dateTime.day().month().hour().minute())
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
            }
        }
    }
}

/// Simple 7-day usage bar chart (no external dependencies).
struct WeekChart: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        let days = store.stats.lastSevenDays
        let maxUnits = max(days.map { $0.units }.max() ?? 0, 1)
        let allowance = store.state.profile.goal == .reduceGradually
            ? store.state.profile.dailyAllowance
            : 0

        HStack(alignment: .bottom, spacing: 10) {
            ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                VStack(spacing: 4) {
                    Text(day.units > 0 ? day.units.formatted(.number.precision(.fractionLength(0))) : "")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Capsule()
                        .fill(barColor(units: day.units, allowance: allowance))
                        .frame(height: max(6, CGFloat(day.units / maxUnits) * 80))
                    Text(day.date, format: .dateTime.weekday(.narrow))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 8)
    }

    private func barColor(units: Double, allowance: Double) -> Color {
        if units == 0 { return store.theme.primary }
        if allowance > 0 && units <= allowance { return store.theme.accent }
        return .red
    }
}

/// Sheet used from Home and Journal to record a slip honestly.
struct LogSlipSheet: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var units: Double = 1
    @State private var date = Date()
    @State private var note = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Stepper(value: $units, in: 0.5...100, step: 0.5) {
                        Text("\(units.formatted(.number.precision(.fractionLength(0...1)))) \(units == 1 ? store.state.profile.smokingType.unitSingular : store.state.profile.smokingType.unitPlural)")
                    }
                    DatePicker("When", selection: $date, in: ...Date())
                    TextField("Note (optional)", text: $note)
                } footer: {
                    Text("Logging honestly keeps your savings and streak real. A slip is data, not failure.")
                }
            }
            .navigationTitle("Log a slip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.logSlip(units: units, date: date, note: note.isEmpty ? nil : note)
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
