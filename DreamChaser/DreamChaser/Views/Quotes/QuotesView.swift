import SwiftUI

/// Quote of the day plus the full library. Seeded from `quotes-seed.json`
/// (swap in your own database anytime) and refreshed daily from the internet.
struct QuotesView: View {
    @State private var todaysQuote = QuoteStore.shared.todaysQuote()
    @State private var favorites = QuoteStore.shared.favorites
    @State private var isRefreshing = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    heroCard
                    refreshButton
                    if !favorites.isEmpty {
                        quoteList(title: "Favorites", symbol: "heart.fill", quotes: favorites)
                    }
                    quoteList(title: "Library", symbol: "books.vertical.fill", quotes: QuoteStore.shared.seedQuotes)
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .background(AppBackground())
            .navigationTitle("Quotes")
            .onAppear {
                todaysQuote = QuoteStore.shared.todaysQuote()
                favorites = QuoteStore.shared.favorites
            }
        }
    }

    private var heroCard: some View {
        VStack(spacing: 14) {
            Image(systemName: "quote.opening")
                .font(.title2)
                .foregroundStyle(.purple)
            Text(todaysQuote.text)
                .font(.system(.title3, design: .serif).italic())
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Text("— \(todaysQuote.author)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(spacing: 12) {
                Button {
                    QuoteStore.shared.toggleFavorite(todaysQuote)
                    favorites = QuoteStore.shared.favorites
                } label: {
                    Image(systemName: QuoteStore.shared.isFavorite(todaysQuote) ? "heart.fill" : "heart")
                        .foregroundStyle(.pink)
                }
                .buttonStyle(.glass)

                ShareLink(item: "“\(todaysQuote.text)” — \(todaysQuote.author)") {
                    Image(systemName: "square.and.arrow.up")
                }
                .buttonStyle(.glass)
            }
        }
        .frame(maxWidth: .infinity)
        .glassCard(tint: .purple)
    }

    private var refreshButton: some View {
        Button {
            Task {
                isRefreshing = true
                if let fresh = await QuoteStore.shared.refreshFromInternet(force: true) {
                    todaysQuote = fresh
                }
                isRefreshing = false
            }
        } label: {
            Label(isRefreshing ? "Fetching…" : "Fresh quote from the internet", systemImage: "arrow.clockwise")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
        }
        .buttonStyle(.glass)
        .disabled(isRefreshing)
    }

    private func quoteList(title: String, symbol: String, quotes: [Quote]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: symbol)
                .font(.headline)
            ForEach(quotes) { quote in
                VStack(alignment: .leading, spacing: 4) {
                    Text("“\(quote.text)”")
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack {
                        Text("— \(quote.author)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button {
                            QuoteStore.shared.toggleFavorite(quote)
                            favorites = QuoteStore.shared.favorites
                        } label: {
                            Image(systemName: QuoteStore.shared.isFavorite(quote) ? "heart.fill" : "heart")
                                .font(.caption)
                                .foregroundStyle(.pink)
                        }
                        .buttonStyle(.plain)
                    }
                }
                if quote != quotes.last {
                    Divider()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }
}
