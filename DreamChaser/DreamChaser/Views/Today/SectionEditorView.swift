import SwiftData
import SwiftUI
import WidgetKit

/// Edit an existing section: name, icon, color, and its daily items.
struct SectionEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var section: RoutineSection

    @State private var newItemTitle = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Section") {
                    TextField("Name", text: $section.name)
                    SymbolPicker(selection: $section.symbol, tint: ThemeColor.color(for: section.colorName))
                    ColorNamePicker(selection: $section.colorName)
                }
                Section("Daily items") {
                    ForEach(section.sortedItems) { item in
                        ItemEditRow(item: item)
                    }
                    .onDelete(perform: deleteItems)
                    HStack {
                        TextField("Add an item", text: $newItemTitle)
                            .onSubmit(addItem)
                        Button("Add", action: addItem)
                            .disabled(newItemTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
                Section {
                    Button("Delete section", role: .destructive) {
                        deleteSection()
                    }
                }
            }
            .navigationTitle("Edit Section")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        save()
                        dismiss()
                    }
                }
            }
        }
    }

    private func addItem() {
        let title = newItemTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return }
        let item = RoutineItem(title: title, sortOrder: (section.items.map(\.sortOrder).max() ?? -1) + 1)
        item.section = section
        context.insert(item)
        newItemTitle = ""
        save()
    }

    private func deleteItems(at offsets: IndexSet) {
        let sorted = section.sortedItems
        for offset in offsets {
            context.delete(sorted[offset])
        }
        save()
    }

    private func deleteSection() {
        context.delete(section)
        save()
        dismiss()
    }

    private func save() {
        try? context.save()
        WidgetCenter.shared.reloadAllTimelines()
    }
}

struct ItemEditRow: View {
    @Bindable var item: RoutineItem

    var body: some View {
        TextField("Item", text: $item.title)
    }
}

/// Create a new section.
struct NewSectionSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \RoutineSection.sortOrder) private var sections: [RoutineSection]

    @State private var name = ""
    @State private var symbol = "star.fill"
    @State private var colorName = "purple"

    var body: some View {
        NavigationStack {
            Form {
                Section("New section") {
                    TextField("Name (e.g. Meditation)", text: $name)
                    SymbolPicker(selection: $symbol, tint: ThemeColor.color(for: colorName))
                    ColorNamePicker(selection: $colorName)
                }
            }
            .navigationTitle("New Section")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { create() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func create() {
        let section = RoutineSection(
            name: name.trimmingCharacters(in: .whitespaces),
            symbol: symbol,
            colorName: colorName,
            sortOrder: (sections.map(\.sortOrder).max() ?? -1) + 1
        )
        context.insert(section)
        try? context.save()
        WidgetCenter.shared.reloadAllTimelines()
        dismiss()
    }
}

// MARK: - Pickers

struct SymbolPicker: View {
    @Binding var selection: String
    var tint: Color

    private static let symbols = [
        "dumbbell", "book.fill", "briefcase.fill", "calendar", "brain.head.profile",
        "laptopcomputer", "paintbrush.fill", "music.note", "figure.run", "bed.double.fill",
        "fork.knife", "drop.fill", "graduationcap.fill", "dollarsign.circle.fill", "globe",
        "camera.fill", "hammer.fill", "leaf.fill", "flame.fill", "moon.stars.fill",
        "star.fill", "bolt.fill", "target", "trophy.fill",
    ]

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 10) {
            ForEach(Self.symbols, id: \.self) { symbol in
                Button {
                    selection = symbol
                } label: {
                    Image(systemName: symbol)
                        .font(.body)
                        .foregroundStyle(selection == symbol ? tint : Color.secondary)
                        .frame(width: 34, height: 34)
                        .background(
                            Circle().fill(selection == symbol ? tint.opacity(0.18) : .clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ColorNamePicker: View {
    @Binding var selection: String

    var body: some View {
        HStack(spacing: 10) {
            ForEach(ThemeColor.names, id: \.self) { name in
                Button {
                    selection = name
                } label: {
                    Circle()
                        .fill(ThemeColor.color(for: name))
                        .frame(width: 26, height: 26)
                        .overlay {
                            if selection == name {
                                Image(systemName: "checkmark")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.white)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
}
