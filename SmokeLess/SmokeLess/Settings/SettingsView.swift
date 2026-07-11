import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore
    @StateObject private var health = HealthKitManager.shared

    @State private var showRestartConfirm = false
    @State private var showResetConfirm = false

    private let currencyCodes = ["USD", "EUR", "GBP", "JPY", "AUD", "CAD", "CHF", "SEK", "NOK", "INR", "AED", "TRY"]

    var body: some View {
        NavigationStack {
            Form {
                habitSection
                goalSection
                themeSection
                notificationsSection
                healthSection
                dangerSection
                aboutSection
            }
            .navigationTitle("Settings")
        }
    }

    // MARK: Bindings that persist on every change

    private func profileBinding<T>(_ keyPath: WritableKeyPath<UserProfile, T>) -> Binding<T> {
        Binding(
            get: { store.state.profile[keyPath: keyPath] },
            set: { newValue in
                store.state.profile[keyPath: keyPath] = newValue
                store.save()
            }
        )
    }

    // MARK: Sections

    private var habitSection: some View {
        Section("My habit") {
            Picker("Type", selection: profileBinding(\.smokingType)) {
                ForEach(SmokingType.allCases) { type in
                    Text(type.title).tag(type)
                }
            }
            VStack(alignment: .leading) {
                Text("Baseline: \(store.state.profile.unitsPerDay.formatted(.number.precision(.fractionLength(0...1)))) \(store.state.profile.smokingType.unitPlural)/day")
                Slider(value: profileBinding(\.unitsPerDay), in: 0.5...60, step: 0.5)
            }
            HStack {
                Text("Price per \(store.state.profile.smokingType.unitSingular)")
                Spacer()
                TextField("Price", value: profileBinding(\.pricePerUnit), format: .number.precision(.fractionLength(0...2)))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 90)
            }
            Picker("Currency", selection: profileBinding(\.currencyCode)) {
                let current = store.state.profile.currencyCode
                let codes = currencyCodes.contains(current) ? currencyCodes : [current] + currencyCodes
                ForEach(codes, id: \.self) { code in
                    Text(code).tag(code)
                }
            }
        }
    }

    private var goalSection: some View {
        Section("Goal") {
            Picker("Mode", selection: profileBinding(\.goal)) {
                ForEach(QuitGoal.allCases) { goal in
                    Text(goal.title).tag(goal)
                }
            }
            if store.state.profile.goal == .reduceGradually {
                VStack(alignment: .leading) {
                    Text("Daily allowance: \(store.state.profile.dailyAllowance.formatted(.number.precision(.fractionLength(0...1)))) \(store.state.profile.smokingType.unitPlural)")
                    Slider(value: profileBinding(\.dailyAllowance), in: 0.5...30, step: 0.5)
                }
            }
            DatePicker("Start date", selection: profileBinding(\.startDate), in: ...Date(), displayedComponents: .date)
        }
    }

    private var themeSection: some View {
        Section("Theme") {
            ForEach(AppTheme.all) { theme in
                Button {
                    store.setTheme(theme.id)
                } label: {
                    HStack {
                        HStack(spacing: 4) {
                            Circle().fill(theme.primary).frame(width: 20, height: 20)
                            Circle().fill(theme.secondary).frame(width: 20, height: 20)
                            Circle().fill(theme.accent).frame(width: 20, height: 20)
                        }
                        Text(theme.name)
                            .foregroundStyle(Color.primary)
                            .padding(.leading, 6)
                        Spacer()
                        if store.state.themeID == theme.id {
                            Image(systemName: "checkmark")
                                .foregroundStyle(store.theme.primary)
                        }
                    }
                }
            }
        }
    }

    private var notificationsSection: some View {
        Section {
            Toggle("Daily fact notification", isOn: Binding(
                get: { store.state.notificationsEnabled },
                set: { enabled in
                    if enabled {
                        NotificationManager.requestAndScheduleDailyFact { granted in
                            store.setNotificationsEnabled(granted)
                        }
                    } else {
                        NotificationManager.cancelAll()
                        store.setNotificationsEnabled(false)
                    }
                }
            ))
        } header: {
            Text("Notifications")
        } footer: {
            Text("One notification each morning with a fact about smoking's problems and your progress.")
        }
    }

    private var healthSection: some View {
        Section {
            if health.isAuthorized {
                Label("Apple Health connected", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(store.theme.primary)
            } else {
                Button("Connect Apple Health") {
                    health.requestAccess()
                }
            }
        } header: {
            Text("Apple Health")
        } footer: {
            Text("Reads your daily activity for the dashboard and saves completed breathing exercises as mindful minutes.")
        }
    }

    private var dangerSection: some View {
        Section("Danger zone") {
            Button("Restart quit from today", role: .destructive) {
                showRestartConfirm = true
            }
            .confirmationDialog(
                "Restart from today? Slips are cleared, wishlist and best streak are kept.",
                isPresented: $showRestartConfirm,
                titleVisibility: .visible
            ) {
                Button("Restart", role: .destructive) {
                    store.restartQuit()
                }
            }

            Button("Erase all data", role: .destructive) {
                showResetConfirm = true
            }
            .confirmationDialog(
                "This permanently deletes your profile, history and wishlist.",
                isPresented: $showResetConfirm,
                titleVisibility: .visible
            ) {
                Button("Erase everything", role: .destructive) {
                    NotificationManager.cancelAll()
                    store.resetAllData()
                }
            }
        }
    }

    private var aboutSection: some View {
        Section {
            LabeledContent("Version", value: "1.0")
            Text("SmokeLess is a motivational tracker, not a medical device. If you need help quitting, contact a healthcare professional or your local quitline.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
