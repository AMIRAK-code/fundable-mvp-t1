import SwiftUI

struct TipsView: View {
    @Environment(\.dismiss) private var dismiss
    let species: PetSpecies

    var body: some View {
        NavigationStack {
            ZStack {
                CalmBackground()
                ScrollView {
                    VStack(spacing: 14) {
                        dailyTipCard
                        ForEach(TipCategory.allCases) { category in
                            let tips = TipsLibrary.tips(for: species).filter { $0.category == category }
                            if !tips.isEmpty {
                                categoryCard(category, tips: tips)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle("\(species.displayName) tips")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var dailyTipCard: some View {
        let tip = TipsLibrary.dailyTip(for: species)
        return GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Label("Today's tip", systemImage: "leaf.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CalmPalette.sage)
                Text(tip.text)
                    .font(.subheadline)
            }
        }
    }

    private func categoryCard(_ category: TipCategory, tips: [PetTip]) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Label(category.rawValue, systemImage: category.symbolName)
                    .font(.headline)
                    .foregroundStyle(CalmPalette.mist)
                ForEach(tips) { tip in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "leaf.fill")
                            .font(.caption2)
                            .foregroundStyle(CalmPalette.sage)
                            .padding(.top, 3)
                        Text(tip.text)
                            .font(.subheadline)
                    }
                }
            }
        }
    }
}
