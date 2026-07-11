import SwiftUI

/// Quick true/false quiz busting common myths about smoking, vaping and
/// heated tobacco.
struct QuizView: View {
    @EnvironmentObject private var store: AppStore

    private struct Question {
        let text: String
        let isTrue: Bool
        let explanation: String
    }

    private let questions: [Question] = [
        Question(
            text: "Vaping is completely harmless.",
            isTrue: false,
            explanation: "Vape aerosol usually contains nicotine plus irritants and metals. Less harmful than cigarettes is not the same as harmless."
        ),
        Question(
            text: "IQOS and other heated tobacco products still deliver toxic chemicals.",
            isTrue: true,
            explanation: "Heated tobacco aerosol contains many of the same harmful substances as cigarette smoke."
        ),
        Question(
            text: "Within about 48 hours of quitting, taste and smell start to improve.",
            isTrue: true,
            explanation: "Nerve endings begin recovering within days — food genuinely tastes better."
        ),
        Question(
            text: "Light or 'slim' cigarettes are significantly safer.",
            isTrue: false,
            explanation: "Smokers compensate by inhaling deeper or smoking more. There is no safe cigarette."
        ),
        Question(
            text: "A typical craving passes in about 5–10 minutes.",
            isTrue: true,
            explanation: "Cravings crest like a wave and fade whether or not you smoke — outlasting them works."
        ),
        Question(
            text: "Just one cigarette a day carries almost no health risk.",
            isTrue: false,
            explanation: "One a day still carries around half the excess heart-disease risk of a full pack. The only safe number is zero."
        ),
        Question(
            text: "Exercise can reduce the urge to smoke.",
            isTrue: true,
            explanation: "Even a brisk 5-minute walk measurably reduces craving intensity."
        ),
        Question(
            text: "Quitting before age 40 avoids most of smoking's excess death risk.",
            isTrue: true,
            explanation: "Quitting before 40 avoids about 90% of the excess risk — and it's never too late to benefit."
        )
    ]

    @State private var index = 0
    @State private var score = 0
    @State private var answered: Bool? = nil
    @State private var finished = false

    var body: some View {
        VStack(spacing: 24) {
            if finished {
                results
            } else {
                quiz
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Myth check")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var quiz: some View {
        let question = questions[index]
        return VStack(spacing: 20) {
            Text("Question \(index + 1) of \(questions.count)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(question.text)
                .font(.title3.bold())
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemGroupedBackground))
                )

            if let answered {
                let correct = answered == question.isTrue
                VStack(spacing: 8) {
                    Text(correct ? "Correct ✅" : "Not quite ❌")
                        .font(.headline)
                        .foregroundStyle(correct ? store.theme.primary : .red)
                    Text(question.explanation)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button(index == questions.count - 1 ? "See results" : "Next question") {
                        advance()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(store.theme.primary)
                }
            } else {
                HStack(spacing: 16) {
                    Button {
                        answer(true)
                    } label: {
                        Text("True")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(store.theme.primary)

                    Button {
                        answer(false)
                    } label: {
                        Text("False")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(store.theme.secondary)
                }
            }
        }
    }

    private var results: some View {
        VStack(spacing: 16) {
            Image(systemName: score == questions.count ? "crown.fill" : "graduationcap.fill")
                .font(.system(size: 56))
                .foregroundStyle(store.theme.accent)
            Text("\(score) / \(questions.count)")
                .font(.system(size: 44, weight: .heavy, design: .rounded))
            Text(score == questions.count
                 ? "Perfect — you can't be fooled."
                 : "The tobacco industry counts on these myths. Now you know better.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Try again") {
                index = 0
                score = 0
                answered = nil
                finished = false
            }
            .buttonStyle(.bordered)
            .tint(store.theme.primary)
        }
        .padding(.top, 40)
    }

    private func answer(_ value: Bool) {
        answered = value
        if value == questions[index].isTrue {
            score += 1
        }
    }

    private func advance() {
        if index == questions.count - 1 {
            finished = true
        } else {
            index += 1
            answered = nil
        }
    }
}
