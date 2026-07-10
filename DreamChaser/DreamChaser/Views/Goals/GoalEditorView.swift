import SwiftData
import SwiftUI
import WidgetKit

/// Create or edit an ultimate goal. New goals can start with a few mini
/// goals typed inline; existing goals manage their ladder on the GoalCard.
struct GoalEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var goal: UltimateGoal?

    @State private var title = ""
    @State private var why = ""
    @State private var hasTargetDate = false
    @State private var targetDate = Calendar.current.date(byAdding: .month, value: 6, to: .now) ?? .now
    @State private var initialSteps: [String] = []
    @State private var newStep = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("The dream") {
                    TextField("Ultimate goal (e.g. Launch my company)", text: $title)
                    TextField("Why does it matter to you?", text: $why, axis: .vertical)
                        .lineLimit(2...4)
                }
                Section("Deadline") {
                    Toggle("Set a target date", isOn: $hasTargetDate.animation())
                    if hasTargetDate {
                        DatePicker("Target", selection: $targetDate, displayedComponents: .date)
                    }
                }
                if goal == nil {
                    Section("First mini goals (in order)") {
                        ForEach(initialSteps.indices, id: \.self) { index in
                            Text("\(index + 1). \(initialSteps[index])")
                        }
                        .onDelete { initialSteps.remove(atOffsets: $0) }
                        HStack {
                            TextField("Add a mini goal", text: $newStep)
                                .onSubmit(addInitialStep)
                            Button("Add", action: addInitialStep)
                                .disabled(newStep.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }
                }
            }
            .navigationTitle(goal == nil ? "New Goal" : "Edit Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveGoal() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear(perform: prefill)
        }
    }

    private func prefill() {
        guard let goal else { return }
        title = goal.title
        why = goal.why
        if let existing = goal.targetDate {
            hasTargetDate = true
            targetDate = existing
        }
    }

    private func addInitialStep() {
        let step = newStep.trimmingCharacters(in: .whitespaces)
        guard !step.isEmpty else { return }
        initialSteps.append(step)
        newStep = ""
    }

    private func saveGoal() {
        let cleanTitle = title.trimmingCharacters(in: .whitespaces)
        if let goal {
            goal.title = cleanTitle
            goal.why = why.trimmingCharacters(in: .whitespaces)
            goal.targetDate = hasTargetDate ? targetDate : nil
        } else {
            let newGoal = UltimateGoal(
                title: cleanTitle,
                why: why.trimmingCharacters(in: .whitespaces),
                targetDate: hasTargetDate ? targetDate : nil
            )
            context.insert(newGoal)
            for (index, step) in initialSteps.enumerated() {
                let mini = MiniGoal(title: step, sortOrder: index)
                mini.goal = newGoal
                context.insert(mini)
            }
        }
        try? context.save()
        WidgetCenter.shared.reloadAllTimelines()
        dismiss()
    }
}
