import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: PetStore
    @State private var showingAddPet = false
    @State private var showingResetConfirm = false

    var body: some View {
        NavigationStack {
            Form {
                petsSection
                remindersSection
                dailyTipSection
                vetSection
                watchSection
                dataSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(CalmBackground())
            .navigationTitle("Settings")
            .sheet(isPresented: $showingAddPet) {
                NavigationStack {
                    PetEditorView(pet: nil)
                }
            }
            .confirmationDialog(
                "Remove all pets, logs and settings?",
                isPresented: $showingResetConfirm,
                titleVisibility: .visible
            ) {
                Button("Reset everything", role: .destructive) {
                    store.resetAllData()
                }
            }
        }
    }

    // MARK: - Sections

    private var petsSection: some View {
        Section("Pets") {
            ForEach(store.pets) { pet in
                NavigationLink {
                    PetEditorView(pet: pet)
                } label: {
                    HStack(spacing: 12) {
                        PetAvatar(pet: pet, size: 36)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(pet.name)
                            Text(pet.species.displayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if pet.id == store.selectedPet?.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(CalmPalette.sage)
                        }
                    }
                }
            }
            Button {
                showingAddPet = true
            } label: {
                Label("Add a pet", systemImage: "plus")
            }
        }
    }

    private var remindersSection: some View {
        Section {
            Toggle("Check-in reminders", isOn: $store.settings.remindersEnabled)
            if store.settings.remindersEnabled {
                Picker("Cycle", selection: $store.settings.cadence) {
                    ForEach(CheckInCadence.allCases) { cadence in
                        Text(cadence.displayName).tag(cadence)
                    }
                }
                DatePicker("Time", selection: reminderTime, displayedComponents: .hourAndMinute)
            }
        } header: {
            Text("Check-in cycle")
        } footer: {
            Text("Gentle reminders to log how your pet is doing, on the rhythm you choose.")
        }
    }

    private var dailyTipSection: some View {
        Section {
            Toggle("Daily tip notification", isOn: $store.settings.dailyTipEnabled)
            if store.settings.dailyTipEnabled {
                DatePicker("Time", selection: tipTime, displayedComponents: .hourAndMinute)
            }
        } header: {
            Text("Daily tips")
        }
    }

    private var vetSection: some View {
        Section {
            TextField("Practice or vet's name", text: $store.settings.vetName)
            TextField("Phone number", text: $store.settings.vetPhone)
                .keyboardType(.phonePad)
        } header: {
            Text("Your veterinarian")
        } footer: {
            Text("Used for one-tap calling when the health check finds something urgent.")
        }
    }

    private var watchSection: some View {
        Section {
            Label {
                Text("Vet alerts and reminders appear on a paired Apple Watch automatically when your iPhone is locked — no extra setup needed.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } icon: {
                Image(systemName: "applewatch")
                    .foregroundStyle(CalmPalette.sage)
            }
            Button("Check notification permission") {
                NotificationManager.requestAuthorization()
            }
        } header: {
            Text("Apple Watch & notifications")
        }
    }

    private var dataSection: some View {
        Section {
            ShareLink(item: store.exportJSON()) {
                Label("Export data (JSON)", systemImage: "square.and.arrow.up")
            }
            Button(role: .destructive) {
                showingResetConfirm = true
            } label: {
                Label("Reset all data", systemImage: "trash")
            }
        } header: {
            Text("Data")
        } footer: {
            Text("Everything stays on this device. Export creates a JSON copy you can share with your vet.")
        }
    }

    private var aboutSection: some View {
        Section {
            LabeledContent("Version", value: "1.0")
            Text(VetDisclaimer.full)
                .font(.footnote)
                .foregroundStyle(.secondary)
        } header: {
            Text("About")
        }
    }

    // MARK: - Time bindings

    private var reminderTime: Binding<Date> {
        Binding {
            Calendar.current.date(
                from: DateComponents(hour: store.settings.reminderHour, minute: store.settings.reminderMinute)
            ) ?? Date()
        } set: { newValue in
            let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            store.settings.reminderHour = components.hour ?? 9
            store.settings.reminderMinute = components.minute ?? 0
        }
    }

    private var tipTime: Binding<Date> {
        Binding {
            Calendar.current.date(
                from: DateComponents(hour: store.settings.tipHour, minute: store.settings.tipMinute)
            ) ?? Date()
        } set: { newValue in
            let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            store.settings.tipHour = components.hour ?? 8
            store.settings.tipMinute = components.minute ?? 30
        }
    }
}
