import SwiftData
import SwiftUI

/// Ultimate goals, each broken into an ordered ladder of mini goals that
/// unlock one at a time.
struct GoalsView: View {
    @Query(sort: \UltimateGoal.createdAt) private var goals: [UltimateGoal]

    @State private var showingNewGoal = false
    @State private var editingGoal: UltimateGoal?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if goals.isEmpty {
                        emptyState
                    }
                    ForEach(goals) { goal in
                        GoalCard(goal: goal) {
                            editingGoal = goal
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .background(AppBackground())
            .navigationTitle("Goals")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingNewGoal = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewGoal) {
                GoalEditorView()
            }
            .sheet(item: $editingGoal) { goal in
                GoalEditorView(goal: goal)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "mountain.2.fill")
                .font(.system(size: 44))
                .foregroundStyle(.purple)
            Text("What are you chasing?")
                .font(.title3.bold())
            Text("Set your ultimate goal, break it into mini goals, and climb them in order.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Set your ultimate goal") {
                showingNewGoal = true
            }
            .buttonStyle(.glassProminent)
        }
        .frame(maxWidth: .infinity)
        .glassCard()
        .padding(.top, 40)
    }
}
