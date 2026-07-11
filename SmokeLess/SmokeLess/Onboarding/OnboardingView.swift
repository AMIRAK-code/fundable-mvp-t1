import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var store: AppStore

    @State private var step = 0
    @State private var smokingType: SmokingType = .cigarettes
    @State private var unitsPerDay: Double = 15
    @State private var pricePerUnit: Double = 0.40
    @State private var goal: QuitGoal = .quitCompletely
    @State private var dailyAllowance: Double = 5
    @State private var alreadyQuit = false
    @State private var startDate = Date()

    private let lastStep = 4

    var body: some View {
        VStack(spacing: 0) {
            ProgressView(value: Double(step + 1), total: Double(lastStep + 1))
                .tint(store.theme.primary)
                .padding(.horizontal)
                .padding(.top)

            TabView(selection: $step) {
                welcome.tag(0)
                typePicker.tag(1)
                habits.tag(2)
                goalPicker.tag(3)
                summary.tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: step)

            controls
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: Steps

    private var welcome: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "wind")
                .font(.system(size: 64))
                .foregroundStyle(store.theme.primary)
            Text("Welcome to SmokeLess")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
            Text("Whether it's cigarettes, vape or IQOS — track your streak, watch your savings grow, and spend them on things you actually want.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
        .padding()
    }

    private var typePicker: some View {
        VStack(alignment: .leading, spacing: 16) {
            header(title: "What do you smoke?", subtitle: "We'll tailor units and prices to your habit.")
            ForEach(SmokingType.allCases) { type in
                Button {
                    smokingType = type
                    unitsPerDay = type.defaultUnitsPerDay
                    pricePerUnit = type.defaultPricePerUnit
                } label: {
                    HStack {
                        Image(systemName: type.symbol)
                            .frame(width: 36)
                            .foregroundStyle(store.theme.primary)
                        Text(type.title)
                            .foregroundStyle(Color.primary)
                        Spacer()
                        if smokingType == type {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(store.theme.primary)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(smokingType == type ? store.theme.primary : Color.clear, lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding()
    }

    private var habits: some View {
        VStack(alignment: .leading, spacing: 24) {
            header(title: "Your current habit", subtitle: "Be honest — this is the baseline your savings are measured against.")

            VStack(alignment: .leading, spacing: 8) {
                Text("\(smokingType.unitPlural.capitalized) per day: \(unitsPerDay, format: .number.precision(.fractionLength(0...1)))")
                    .font(.headline)
                Slider(value: $unitsPerDay, in: 0.5...60, step: 0.5)
                    .tint(store.theme.primary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Price per \(smokingType.unitSingular)")
                    .font(.headline)
                HStack {
                    TextField("Price", value: $pricePerUnit, format: .number.precision(.fractionLength(0...2)))
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 120)
                    Text(Locale.current.currency?.identifier ?? "USD")
                        .foregroundStyle(.secondary)
                }
                Text("Tip: for cigarettes, divide the pack price by how many are inside.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("That's about")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(unitsPerDay * pricePerUnit, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                        .font(.title.bold())
                        .foregroundStyle(store.theme.primary)
                    Text("per day")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.secondarySystemGroupedBackground))
            )

            Spacer()
        }
        .padding()
    }

    private var goalPicker: some View {
        VStack(alignment: .leading, spacing: 16) {
            header(title: "Pick your path", subtitle: "Both count your streak, avoided units and money saved.")

            ForEach(QuitGoal.allCases) { option in
                Button {
                    goal = option
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(option.title)
                                .font(.headline)
                                .foregroundStyle(Color.primary)
                            Spacer()
                            if goal == option {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(store.theme.primary)
                            }
                        }
                        Text(option.detail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(goal == option ? store.theme.primary : Color.clear, lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)
            }

            if goal == .reduceGradually {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Daily allowance: \(dailyAllowance, format: .number.precision(.fractionLength(0...1))) \(smokingType.unitPlural)")
                        .font(.headline)
                    Slider(value: $dailyAllowance, in: 0.5...30, step: 0.5)
                        .tint(store.theme.primary)
                }
                .padding(.top, 8)
            }

            Toggle("I already quit earlier", isOn: $alreadyQuit)
                .tint(store.theme.primary)
                .padding(.top, 8)

            if alreadyQuit {
                DatePicker("Quit date", selection: $startDate, in: ...Date(), displayedComponents: .date)
            }

            Spacer()
        }
        .padding()
    }

    private var summary: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(store.theme.primary)
            Text("You're all set")
                .font(.largeTitle.bold())
            VStack(alignment: .leading, spacing: 10) {
                summaryRow(symbol: smokingType.symbol, text: smokingType.title)
                summaryRow(symbol: "chart.bar.fill", text: "\(unitsPerDay.formatted(.number.precision(.fractionLength(0...1)))) \(smokingType.unitPlural)/day baseline")
                summaryRow(symbol: "target", text: goal.title)
                summaryRow(symbol: "banknote.fill", text: "Saving ~\((unitsPerDay * pricePerUnit).formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))) per day")
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .padding(.horizontal)
            Text("We'll also ask to send one daily fact about smoking — you can turn this off anytime.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
        .padding()
    }

    private func summaryRow(symbol: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .frame(width: 28)
                .foregroundStyle(store.theme.primary)
            Text(text)
        }
    }

    private func header(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.title.bold())
            Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
        }
    }

    // MARK: Controls

    private var controls: some View {
        HStack {
            if step > 0 {
                Button("Back") {
                    step -= 1
                }
                .buttonStyle(.bordered)
            }
            Spacer()
            Button(step == lastStep ? "Start my journey" : "Continue") {
                if step == lastStep {
                    finish()
                } else {
                    step += 1
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(store.theme.primary)
        }
        .padding()
    }

    private func finish() {
        var profile = UserProfile()
        profile.smokingType = smokingType
        profile.unitsPerDay = max(0.5, unitsPerDay)
        profile.pricePerUnit = max(0, pricePerUnit)
        profile.currencyCode = Locale.current.currency?.identifier ?? "USD"
        profile.startDate = alreadyQuit ? startDate : Date()
        profile.goal = goal
        profile.dailyAllowance = dailyAllowance
        store.completeOnboarding(profile: profile)

        NotificationManager.requestAndScheduleDailyFact { granted in
            store.setNotificationsEnabled(granted)
        }
    }
}
