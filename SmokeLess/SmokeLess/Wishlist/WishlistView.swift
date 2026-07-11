import SwiftUI

/// Wishlist funded by not smoking: each item fills up as savings accumulate,
/// and buying an item deducts its price from the available pool.
struct WishlistView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showAddItem = false

    private var currency: String { store.state.profile.currencyCode }
    private var activeItems: [WishlistItem] {
        store.state.wishlist.filter { $0.purchasedAt == nil }
    }
    private var purchasedItems: [WishlistItem] {
        store.state.wishlist.filter { $0.purchasedAt != nil }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    poolHeader
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                }

                Section("Saving for") {
                    if activeItems.isEmpty {
                        Text("Add something you want — every \(store.state.profile.smokingType.unitSingular) you skip pays for it.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(activeItems) { item in
                        itemRow(item)
                    }
                }

                if !purchasedItems.isEmpty {
                    Section("Bought with saved money 🎉") {
                        ForEach(purchasedItems) { item in
                            HStack {
                                Text(item.emoji)
                                VStack(alignment: .leading) {
                                    Text(item.name)
                                        .strikethrough()
                                    if let purchased = item.purchasedAt {
                                        Text(purchased, format: .dateTime.day().month().year())
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                Text(item.price, format: .currency(code: currency))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Wishlist")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddItem = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddItem) {
                AddWishlistItemSheet()
                    .environmentObject(store)
            }
        }
    }

    private var poolHeader: some View {
        VStack(spacing: 6) {
            Text("Available to spend")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
            Text(store.stats.availableSavings, format: .currency(code: currency))
                .font(.system(size: 38, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
            Text("Total saved: \(store.stats.moneySaved.formatted(.currency(code: currency))) · Spent: \(store.stats.wishlistSpent.formatted(.currency(code: currency)))")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(RoundedRectangle(cornerRadius: 20).fill(store.theme.gradient))
        .padding(.vertical, 8)
    }

    private func itemRow(_ item: WishlistItem) -> some View {
        let funded = item.price > 0
            ? min(1, store.stats.availableSavings / item.price)
            : 1
        let ready = funded >= 1
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.emoji)
                    .font(.title3)
                Text(item.name)
                    .font(.headline)
                Spacer()
                Text(item.price, format: .currency(code: currency))
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: funded)
                .tint(ready ? store.theme.primary : store.theme.accent)
            HStack {
                Text(ready ? "Fully funded — treat yourself!" : "\(Int(funded * 100))% funded")
                    .font(.caption)
                    .foregroundStyle(ready ? store.theme.primary : .secondary)
                Spacer()
                if ready {
                    Button("Buy it") {
                        store.markPurchased(item)
                    }
                    .font(.caption.bold())
                    .buttonStyle(.borderedProminent)
                    .tint(store.theme.primary)
                }
            }
        }
        .padding(.vertical, 4)
        .swipeActions {
            Button(role: .destructive) {
                store.removeWishlistItem(id: item.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

struct AddWishlistItemSheet: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var price: Double = 50
    @State private var emoji = "🎁"

    private let emojis = ["🎁", "🎧", "👟", "📱", "⌚️", "🎮", "✈️", "🏋️", "📚", "🍽️", "🚲", "💆"]

    var body: some View {
        NavigationStack {
            Form {
                Section("What are you saving for?") {
                    TextField("Name (e.g. Wireless earbuds)", text: $name)
                    HStack {
                        Text("Price")
                        Spacer()
                        TextField("Price", value: $price, format: .number.precision(.fractionLength(0...2)))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                        Text(store.state.profile.currencyCode)
                            .foregroundStyle(.secondary)
                    }
                }
                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6)) {
                        ForEach(emojis, id: \.self) { candidate in
                            Button {
                                emoji = candidate
                            } label: {
                                Text(candidate)
                                    .font(.title2)
                                    .padding(6)
                                    .background(
                                        Circle().fill(emoji == candidate ? store.theme.primary.opacity(0.25) : Color.clear)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle("New wish")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        store.addWishlistItem(name: name, price: max(0, price), emoji: emoji)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || price <= 0)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
