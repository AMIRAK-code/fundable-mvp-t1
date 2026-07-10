import SwiftData
import SwiftUI
import WidgetKit

/// A single ultimate goal rendered as a glass card with its mini-goal ladder.
/// Mini goals must be completed in order: only the current rung is tappable.
struct GoalCard: View {
    @Environment(\.modelContext) private var context
    var goal: UltimateGoal
    var onEdit: () -> Void

    @State private var newStepTitle = ""
    @State private var celebration = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            if goal.isAchieved {
                Label("Goal achieved. Set the next summit. 🏆", systemImage: "trophy.fill")
                    .font(.subheadline.bold())
                    .foregroundStyle(.orange)
            }
            ladder
            addStepField
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
        .sensoryFeedback(.success, trigger: celebration)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(goal.title)
                    .font(.title3.bold())
                if !goal.why.isEmpty {
                    Text(goal.why)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if let target = goal.targetDate {
                    Label(countdownText(to: target), systemImage: "hourglass")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(spacing: 6) {
                ZStack {
                    ProgressRing(progress: goal.progress, lineWidth: 6, tint: .purple)
                    Text(goal.progress, format: .percent.precision(.fractionLength(0)))
                        .font(.system(.caption, design: .rounded).bold())
                }
                .frame(width: 52, height: 52)
                Menu {
                    Button("Edit goal", systemImage: "pencil") { onEdit() }
                    Button("Delete goal", systemImage: "trash", role: .destructive) {
                        context.delete(goal)
                        save()
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(4)
                        .contentShape(.rect)
                }
            }
        }
    }

    private var ladder: some View {
        let minis = goal.sortedMiniGoals
        return VStack(spacing: 8) {
            ForEach(Array(minis.enumerated()), id: \.element.id) { index, mini in
                miniGoalRow(mini, index: index, minis: minis)
            }
        }
    }

    private func miniGoalRow(_ mini: MiniGoal, index: Int, minis: [MiniGoal]) -> some View {
        let isCurrent = !mini.isCompleted && (index == 0 || minis[index - 1].isCompleted)
        let isLocked = !mini.isCompleted && !isCurrent
        let canUncheck = mini.isCompleted && (index == minis.count - 1 || !minis[index + 1].isCompleted)

        return Button {
            if isCurrent {
                withAnimation(.snappy) {
                    mini.isCompleted = true
                    mini.completedAt = .now
                }
                celebration += 1
                save()
            } else if canUncheck {
                withAnimation(.snappy) {
                    mini.isCompleted = false
                    mini.completedAt = nil
                }
                save()
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: mini.isCompleted
                      ? "checkmark.circle.fill"
                      : isLocked ? "lock.circle" : "circle")
                    .font(.title3)
                    .foregroundStyle(mini.isCompleted ? Color.purple : isLocked ? Color.secondary.opacity(0.5) : Color.secondary)
                    .contentTransition(.symbolEffect(.replace))
                Text("\(index + 1). \(mini.title)")
                    .strikethrough(mini.isCompleted)
                    .foregroundStyle(mini.isCompleted || isLocked ? .secondary : .primary)
                    .multilineTextAlignment(.leading)
                Spacer()
                if isCurrent {
                    Text("NEXT")
                        .font(.caption2.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.purple.opacity(0.18)))
                        .foregroundStyle(.purple)
                }
            }
            .contentShape(.rect)
            .opacity(isLocked ? 0.55 : 1)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Delete step", systemImage: "trash", role: .destructive) {
                context.delete(mini)
                save()
            }
        }
    }

    private var addStepField: some View {
        HStack {
            TextField("Add the next mini goal", text: $newStepTitle)
                .textFieldStyle(.plain)
                .onSubmit(addStep)
            Button("Add", action: addStep)
                .buttonStyle(.glass)
                .disabled(newStepTitle.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .font(.subheadline)
    }

    private func addStep() {
        let title = newStepTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return }
        let mini = MiniGoal(title: title, sortOrder: (goal.miniGoals.map(\.sortOrder).max() ?? -1) + 1)
        mini.goal = goal
        context.insert(mini)
        newStepTitle = ""
        save()
    }

    private func countdownText(to target: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: .now, to: target).day ?? 0
        return days >= 0 ? "\(days) days left" : "\(-days) days past target"
    }

    private func save() {
        try? context.save()
        WidgetCenter.shared.reloadAllTimelines()
    }
}
