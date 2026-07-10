import SwiftData
import SwiftUI
import WidgetKit

/// One glass card per routine section with tappable check rows.
struct RoutineSectionCard: View {
    @Environment(\.modelContext) private var context
    var section: RoutineSection
    var todayKey: String
    var onEdit: () -> Void
    var onFocus: () -> Void

    @State private var completionPulse = 0

    private var color: Color {
        ThemeColor.color(for: section.colorName)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            if section.items.isEmpty {
                Text("No items yet — tap ⋯ to add some.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 10) {
                    ForEach(section.sortedItems) { item in
                        itemRow(item)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
        .sensoryFeedback(.success, trigger: completionPulse)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: section.symbol)
                .font(.headline)
                .foregroundStyle(color)
                .frame(width: 28)
            Text(section.name)
                .font(.headline)
            Spacer()
            Text("\(section.completedCount(on: todayKey))/\(section.items.count)")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
            Menu {
                Button("Start focus session", systemImage: "timer") {
                    onFocus()
                }
                Button("Edit section", systemImage: "pencil") {
                    onEdit()
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(6)
                    .contentShape(.rect)
            }
        }
    }

    private func itemRow(_ item: RoutineItem) -> some View {
        let done = item.isDone(on: todayKey)
        return Button {
            toggle(item)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: done ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(done ? color : Color.secondary)
                    .contentTransition(.symbolEffect(.replace))
                Text(item.title)
                    .strikethrough(done)
                    .foregroundStyle(done ? .secondary : .primary)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    private func toggle(_ item: RoutineItem) {
        withAnimation(.snappy) {
            item.toggle(on: todayKey)
        }
        if item.isDone(on: todayKey) {
            completionPulse += 1
        }
        try? context.save()
        WidgetCenter.shared.reloadAllTimelines()
    }
}
