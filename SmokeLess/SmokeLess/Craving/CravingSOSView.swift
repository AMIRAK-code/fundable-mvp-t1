import SwiftUI

/// Full-screen helper for the moment a craving hits: a guided breathing
/// exercise, rotating distraction tips, and a "resisted" button that logs the
/// win and (optionally) saves a mindful session to Apple Health.
struct CravingSOSView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var sessionStart = Date()
    @State private var tipIndex = 0

    private let tips = [
        "Drink a glass of cold water slowly.",
        "Cravings peak and fade in 5–10 minutes. You only need to outlast this one.",
        "Do 10 push-ups or take a brisk 2-minute walk.",
        "Text a friend and tell them you're beating a craving right now.",
        "Brush your teeth — the fresh taste kills the urge.",
        "Play the tape forward: how will you feel 10 minutes after smoking?",
        "Chew gum or snack on carrot sticks, nuts or seeds.",
        "Remember why you started: check your wishlist and savings."
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Text("This craving will pass.")
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)

                    BreathingView(theme: store.theme)
                        .frame(height: 300)

                    tipCard

                    Button {
                        store.logResistedCraving()
                        HealthKitManager.shared.logMindfulSession(start: sessionStart, end: Date())
                        dismiss()
                    } label: {
                        Label("I beat it 💪", systemImage: "hand.raised.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(store.theme.primary)

                    Text("Beaten so far: \(store.stats.resistedCount) cravings")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Craving SOS")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear { sessionStart = Date() }
        }
    }

    private var tipCard: some View {
        VStack(spacing: 12) {
            Text(tips[tipIndex])
                .font(.callout)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .animation(.none, value: tipIndex)
            Button {
                tipIndex = (tipIndex + 1) % tips.count
            } label: {
                Label("Another idea", systemImage: "arrow.triangle.2.circlepath")
                    .font(.footnote)
            }
            .tint(store.theme.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}
