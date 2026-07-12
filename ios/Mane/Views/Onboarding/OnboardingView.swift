import SwiftUI

/// Nine-step onboarding: welcome → profile questions → plan generation →
/// personalized results. Produces a `HairProfile` that drives the whole app.
struct OnboardingView: View {
    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var model: AppModel

    @State private var step = 0
    @State private var draft = HairProfile()

    private let questionRange = 1...6
    private let lastStep = 8

    var body: some View {
        VStack(spacing: 0) {
            header
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            footer
        }
        .themedScreen()
    }

    // MARK: - Chrome

    private var header: some View {
        VStack(spacing: 14) {
            HStack {
                if step > 0 && step < 7 {
                    Button {
                        withAnimation(.easeInOut) { step -= 1 }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.headline)
                            .foregroundStyle(theme.palette.textSecondary)
                    }
                }
                Spacer()
                if questionRange.contains(step) {
                    Text("Step \(step) of \(questionRange.upperBound)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(theme.palette.textSecondary)
                }
            }
            .frame(height: 24)

            if questionRange.contains(step) {
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule().fill(theme.palette.surfaceSecondary)
                        Capsule()
                            .fill(theme.palette.accent)
                            .frame(width: proxy.size.width * CGFloat(step) / CGFloat(questionRange.upperBound))
                    }
                }
                .frame(height: 6)
                .animation(.easeInOut, value: step)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
    }

    @ViewBuilder
    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                switch step {
                case 0: WelcomeStep()
                case 1: NameAgeStep(draft: $draft)
                case 2: HairTypeStep(draft: $draft)
                case 3: ScalpStep(draft: $draft)
                case 4: ConcernsStep(draft: $draft)
                case 5: LifestyleStep(draft: $draft)
                case 6: HabitsGoalStep(draft: $draft)
                case 7: BuildingStep(onFinished: { withAnimation(.easeInOut) { step = 8 } })
                default: ResultsStep(draft: draft)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .id(step)
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }

    @ViewBuilder
    private var footer: some View {
        VStack(spacing: 10) {
            switch step {
            case 0:
                Button("Build my routine") {
                    withAnimation(.easeInOut) { step = 1 }
                }
                .buttonStyle(PrimaryButtonStyle(palette: theme.palette))
            case 1...5:
                Button("Continue") {
                    withAnimation(.easeInOut) { step += 1 }
                }
                .buttonStyle(PrimaryButtonStyle(palette: theme.palette))
            case 6:
                Button("Generate my plan") {
                    withAnimation(.easeInOut) { step = 7 }
                }
                .buttonStyle(PrimaryButtonStyle(palette: theme.palette))
            case 8:
                Button("Start my plan") {
                    model.completeOnboarding(with: draft)
                }
                .buttonStyle(PrimaryButtonStyle(palette: theme.palette))
            default:
                EmptyView()
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }
}

// MARK: - Step 0: Welcome

private struct WelcomeStep: View {
    @EnvironmentObject private var theme: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(theme.palette.hero)
                    .frame(height: 220)
                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.15))
                            .frame(width: 84, height: 84)
                        Text("M")
                            .font(.system(size: 44, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    Text("MANE")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .tracking(6)
                        .foregroundStyle(.white)
                    Text("Engineered hair care for men")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                }
            }

            VStack(alignment: .leading, spacing: 18) {
                FeatureRow(symbol: "list.clipboard.fill", title: "A routine built for you",
                           text: "Answer a few questions and get a weekly plan matched to your hair, scalp and lifestyle.")
                FeatureRow(symbol: "camera.metering.center.weighted", title: "Hairline scanner",
                           text: "3–4 photos, analyzed on device, tracked over time — see if your hairline is receding, stable or restoring.")
                FeatureRow(symbol: "sparkles", title: "Products that fit",
                           text: "Recommendations scored against your profile, aggregated from multiple catalog sources.")
                FeatureRow(symbol: "lock.fill", title: "Private by design",
                           text: "Photos and analysis never leave your phone.")
            }
        }
    }
}

private struct FeatureRow: View {
    @EnvironmentObject private var theme: ThemeManager
    let symbol: String
    let title: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(theme.palette.accent)
                .frame(width: 34)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(theme.palette.textPrimary)
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(theme.palette.textSecondary)
            }
        }
    }
}

// MARK: - Step 1: Name & age

private struct NameAgeStep: View {
    @EnvironmentObject private var theme: ThemeManager
    @Binding var draft: HairProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            SectionHeader(title: "First things first", subtitle: "What should we call you?")
            TextField("Your name (optional)", text: $draft.name)
                .textInputAutocapitalization(.words)
                .padding(14)
                .background(theme.palette.surface)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .foregroundStyle(theme.palette.textPrimary)

            SectionHeader(title: "Age range", subtitle: "Hair changes with age — this tunes the plan.")
            FlowChips(data: AgeRange.allCases) { range in
                Chip(label: range.rawValue, isSelected: draft.ageRange == range) {
                    draft.ageRange = range
                }
            }
        }
    }
}

// MARK: - Step 2: Hair type & length

private struct HairTypeStep: View {
    @Binding var draft: HairProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            SectionHeader(title: "Your hair type", subtitle: "Pick the closest match when dry.")
            FlowChips(data: HairType.allCases) { type in
                Chip(label: type.label, symbol: type.symbol, isSelected: draft.hairType == type) {
                    draft.hairType = type
                }
            }

            SectionHeader(title: "Current length")
            FlowChips(data: HairLength.allCases) { length in
                Chip(label: length.label, isSelected: draft.hairLength == length) {
                    draft.hairLength = length
                }
            }
        }
    }
}

// MARK: - Step 3: Scalp

private struct ScalpStep: View {
    @EnvironmentObject private var theme: ThemeManager
    @Binding var draft: HairProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            SectionHeader(title: "How's your scalp?", subtitle: "The scalp drives wash frequency and product picks.")
            VStack(spacing: 12) {
                ForEach(ScalpCondition.allCases) { condition in
                    Button {
                        draft.scalp = condition
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(condition.label)
                                    .font(.headline)
                                    .foregroundStyle(theme.palette.textPrimary)
                                Text(condition.blurb)
                                    .font(.subheadline)
                                    .foregroundStyle(theme.palette.textSecondary)
                            }
                            Spacer()
                            Image(systemName: draft.scalp == condition ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(draft.scalp == condition ? theme.palette.accent : theme.palette.textSecondary)
                        }
                        .card()
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .strokeBorder(
                                    draft.scalp == condition ? theme.palette.accent : Color.clear,
                                    lineWidth: 2
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Step 4: Concerns

private struct ConcernsStep: View {
    @Binding var draft: HairProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            SectionHeader(title: "Any concerns?", subtitle: "Select all that apply — or none.")
            FlowChips(data: Concern.allCases) { concern in
                Chip(
                    label: concern.label,
                    symbol: concern.symbol,
                    isSelected: draft.concerns.contains(concern)
                ) {
                    if draft.concerns.contains(concern) {
                        draft.concerns.remove(concern)
                    } else {
                        draft.concerns.insert(concern)
                    }
                }
            }
        }
    }
}

// MARK: - Step 5: Lifestyle

private struct LifestyleStep: View {
    @EnvironmentObject private var theme: ThemeManager
    @Binding var draft: HairProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            SectionHeader(title: "Lifestyle", subtitle: "Sweat, chlorine and heat all change the plan.")

            VStack(alignment: .leading, spacing: 12) {
                Text("How often do you work out?")
                    .font(.headline)
                    .foregroundStyle(theme.palette.textPrimary)
                FlowChips(data: ExerciseFrequency.allCases) { freq in
                    Chip(label: freq.label, isSelected: draft.lifestyle.exercise == freq) {
                        draft.lifestyle.exercise = freq
                    }
                }
            }

            VStack(spacing: 4) {
                lifestyleToggle("Swim regularly (pool)", symbol: "figure.pool.swim", isOn: $draft.lifestyle.swims)
                lifestyleToggle("Hard water at home", symbol: "aqi.medium", isOn: $draft.lifestyle.hardWater)
                lifestyleToggle("Blow-dry or use hot tools", symbol: "flame", isOn: $draft.lifestyle.heatStyling)
                lifestyleToggle("Wear hats most days", symbol: "graduationcap", isOn: $draft.lifestyle.wearsHats)
            }
            .card()
        }
    }

    private func lifestyleToggle(_ title: String, symbol: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Label {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(theme.palette.textPrimary)
            } icon: {
                Image(systemName: symbol)
                    .foregroundStyle(theme.palette.accent)
            }
        }
        .tint(theme.palette.accent)
        .padding(.vertical, 6)
    }
}

// MARK: - Step 6: Habits & goal

private struct HabitsGoalStep: View {
    @EnvironmentObject private var theme: ThemeManager
    @Binding var draft: HairProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            SectionHeader(title: "Current habits", subtitle: "No judgment — this is the before picture.")
            VStack(alignment: .leading, spacing: 8) {
                Text("You shampoo about \(draft.currentWashesPerWeek)×/week")
                    .font(.headline)
                    .foregroundStyle(theme.palette.textPrimary)
                Slider(
                    value: Binding(
                        get: { Double(draft.currentWashesPerWeek) },
                        set: { draft.currentWashesPerWeek = Int($0.rounded()) }
                    ),
                    in: 1...7, step: 1
                )
                .tint(theme.palette.accent)
                HStack {
                    Text("1×").font(.caption)
                    Spacer()
                    Text("Daily").font(.caption)
                }
                .foregroundStyle(theme.palette.textSecondary)
            }
            .card()

            SectionHeader(title: "Main goal", subtitle: "One priority keeps the plan sharp.")
            FlowChips(data: Goal.allCases) { goal in
                Chip(label: goal.label, symbol: goal.symbol, isSelected: draft.goal == goal) {
                    draft.goal = goal
                }
            }
        }
    }
}

// MARK: - Step 7: Building animation

private struct BuildingStep: View {
    @EnvironmentObject private var theme: ThemeManager
    let onFinished: () -> Void

    @State private var messageIndex = 0
    private let messages = [
        "Reading your profile…",
        "Balancing wash frequency…",
        "Matching products from all sources…",
        "Assembling your weekly plan…"
    ]

    var body: some View {
        VStack(spacing: 26) {
            Spacer(minLength: 60)
            ProgressView()
                .controlSize(.large)
                .tint(theme.palette.accent)
            Text(messages[min(messageIndex, messages.count - 1)])
                .font(.headline)
                .foregroundStyle(theme.palette.textPrimary)
                .animation(.easeInOut, value: messageIndex)
            Spacer(minLength: 60)
        }
        .frame(maxWidth: .infinity)
        .task {
            for index in 1..<messages.count {
                try? await Task.sleep(nanoseconds: 550_000_000)
                messageIndex = index
            }
            try? await Task.sleep(nanoseconds: 550_000_000)
            onFinished()
        }
    }
}

// MARK: - Step 8: Results

private struct ResultsStep: View {
    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var model: AppModel
    let draft: HairProfile

    private var routine: HairRoutine { RoutineEngine.buildRoutine(for: draft) }
    private var picks: [Product] { RoutineEngine.recommend(products: model.products, for: draft, limit: 3) }

    var body: some View {
        let routine = self.routine
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 8) {
                Text("\(draft.displayName), your plan is ready")
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundStyle(theme.palette.textPrimary)
                Text(routine.headline)
                    .font(.headline)
                    .foregroundStyle(theme.palette.accent)
            }

            VStack(alignment: .leading, spacing: 10) {
                ForEach(routine.rationale, id: \.self) { line in
                    Label {
                        Text(line)
                            .font(.subheadline)
                            .foregroundStyle(theme.palette.textSecondary)
                    } icon: {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(theme.palette.positive)
                    }
                }
            }
            .card()

            SectionHeader(title: "Your week at a glance")
            VStack(spacing: 10) {
                ForEach(routine.steps) { step in
                    HStack(spacing: 12) {
                        Image(systemName: step.icon)
                            .foregroundStyle(theme.palette.accent)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(step.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(theme.palette.textPrimary)
                            Text("\(step.timeOfDay.label) · \(step.frequencyLabel)")
                                .font(.caption)
                                .foregroundStyle(theme.palette.textSecondary)
                        }
                        Spacer()
                    }
                }
            }
            .card()

            if !picks.isEmpty {
                SectionHeader(title: "Starter picks", subtitle: "Matched to your profile — more in the Products tab.")
                VStack(spacing: 10) {
                    ForEach(picks) { product in
                        HStack(spacing: 12) {
                            Image(systemName: product.category.symbol)
                                .foregroundStyle(theme.palette.accent)
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(product.name)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(theme.palette.textPrimary)
                                Text(product.brand)
                                    .font(.caption)
                                    .foregroundStyle(theme.palette.textSecondary)
                            }
                            Spacer()
                            Text(product.priceLabel)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(theme.palette.textSecondary)
                        }
                    }
                }
                .card()
            }

            DisclaimerFooter()
        }
    }
}
