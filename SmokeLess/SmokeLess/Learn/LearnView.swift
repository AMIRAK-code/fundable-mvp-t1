import SwiftUI

struct LearnView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        NavigationStack {
            List {
                Section {
                    DailyFactCard()
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                }

                Section("Explore") {
                    NavigationLink {
                        HealthTimelineView()
                    } label: {
                        Label("Body recovery timeline", systemImage: "heart.text.square.fill")
                    }
                    NavigationLink {
                        QuizView()
                    } label: {
                        Label("Myth check quiz", systemImage: "questionmark.circle.fill")
                    }
                }

                Section("Fact library") {
                    ForEach(DailyFact.categories, id: \.self) { category in
                        DisclosureGroup(category) {
                            ForEach(DailyFact.all.filter { $0.category == category }) { fact in
                                Text(fact.text)
                                    .font(.callout)
                                    .padding(.vertical, 4)
                            }
                        }
                    }
                }

                Section {
                    Text("SmokeLess is a motivational tool, not medical advice. For quitting support, talk to a doctor or a local quitline.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Learn")
        }
    }
}
