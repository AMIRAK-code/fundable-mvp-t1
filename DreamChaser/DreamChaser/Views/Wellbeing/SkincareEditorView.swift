import SwiftData
import SwiftUI

/// Manage skincare steps for morning and evening.
struct SkincareEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \SkincareStep.sortOrder) private var steps: [SkincareStep]

    @State private var newMorningStep = ""
    @State private var newEveningStep = ""

    var body: some View {
        NavigationStack {
            Form {
                editorSection(title: "Morning", timeOfDay: "morning", newTitle: $newMorningStep)
                editorSection(title: "Evening", timeOfDay: "evening", newTitle: $newEveningStep)
            }
            .navigationTitle("Skincare Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        try? context.save()
                        dismiss()
                    }
                }
            }
        }
    }

    private func editorSection(title: String, timeOfDay: String, newTitle: Binding<String>) -> some View {
        let group = steps.filter { $0.timeOfDay == timeOfDay }
        return Section(title) {
            ForEach(group) { step in
                SkincareStepRow(step: step)
            }
            .onDelete { offsets in
                for offset in offsets {
                    context.delete(group[offset])
                }
                try? context.save()
            }
            HStack {
                TextField("Add a step", text: newTitle)
                    .onSubmit { addStep(timeOfDay: timeOfDay, title: newTitle) }
                Button("Add") {
                    addStep(timeOfDay: timeOfDay, title: newTitle)
                }
                .disabled(newTitle.wrappedValue.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    private func addStep(timeOfDay: String, title: Binding<String>) {
        let clean = title.wrappedValue.trimmingCharacters(in: .whitespaces)
        guard !clean.isEmpty else { return }
        let maxOrder = steps.filter { $0.timeOfDay == timeOfDay }.map(\.sortOrder).max() ?? -1
        context.insert(SkincareStep(title: clean, timeOfDay: timeOfDay, sortOrder: maxOrder + 1))
        title.wrappedValue = ""
        try? context.save()
    }
}

struct SkincareStepRow: View {
    @Bindable var step: SkincareStep

    var body: some View {
        TextField("Step", text: $step.title)
    }
}
