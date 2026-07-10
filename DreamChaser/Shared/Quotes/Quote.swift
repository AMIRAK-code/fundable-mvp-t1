import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

struct Quote: Codable, Identifiable, Hashable {
    let text: String
    let author: String

    var id: String { text + "—" + author }
}

/// Quote engine: a bundled seed library (swap `quotes-seed.json` for your own
/// database at any time) plus a once-a-day fetch from the internet. The
/// fetched quote is cached in the App Group so widgets show it too.
final class QuoteStore: @unchecked Sendable {
    static let shared = QuoteStore()

    private let defaults: UserDefaults
    private static let remoteQuoteKey = "remoteQuote.v1"
    private static let remoteQuoteDayKey = "remoteQuoteDay.v1"
    private static let favoritesKey = "favoriteQuotes.v1"

    init(defaults: UserDefaults = AppGroup.defaults) {
        self.defaults = defaults
    }

    // MARK: Seed library

    private(set) lazy var seedQuotes: [Quote] = {
        guard
            let url = Bundle.main.url(forResource: "quotes-seed", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let quotes = try? JSONDecoder().decode([Quote].self, from: data),
            !quotes.isEmpty
        else {
            return [Quote(text: "Discipline is the bridge between goals and accomplishment.", author: "Jim Rohn")]
        }
        return quotes
    }()

    // MARK: Quote of the day

    /// Today's quote: the freshly fetched one if we have it, otherwise a
    /// deterministic pick from the seed library (same quote all day).
    func todaysQuote(on date: Date = .now) -> Quote {
        if let remote = remoteQuote(for: date) {
            return remote
        }
        let day = Int(date.timeIntervalSinceReferenceDate / 86_400)
        let index = ((day % seedQuotes.count) + seedQuotes.count) % seedQuotes.count
        return seedQuotes[index]
    }

    func remoteQuote(for date: Date) -> Quote? {
        guard
            defaults.string(forKey: Self.remoteQuoteDayKey) == Dates.key(for: date),
            let data = defaults.data(forKey: Self.remoteQuoteKey),
            let quote = try? JSONDecoder().decode(Quote.self, from: data)
        else { return nil }
        return quote
    }

    /// Pulls today's quote from ZenQuotes (https://zenquotes.io). To plug in a
    /// different source — or your own backend once you have one — change the
    /// URL and the `RemotePayload` decoding here; nothing else needs to know.
    @discardableResult
    func refreshFromInternet(force: Bool = false) async -> Quote? {
        if !force, let cached = remoteQuote(for: .now) {
            return cached
        }
        struct RemotePayload: Decodable {
            let q: String
            let a: String
        }
        guard let url = URL(string: "https://zenquotes.io/api/today") else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let payload = try JSONDecoder().decode([RemotePayload].self, from: data).first else { return nil }
            let quote = Quote(text: payload.q, author: payload.a)
            store(remote: quote)
            return quote
        } catch {
            return nil // Offline or API down — seed library covers the day.
        }
    }

    private func store(remote quote: Quote) {
        defaults.set(try? JSONEncoder().encode(quote), forKey: Self.remoteQuoteKey)
        defaults.set(Dates.key(), forKey: Self.remoteQuoteDayKey)
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }

    // MARK: Favorites

    var favorites: [Quote] {
        guard
            let data = defaults.data(forKey: Self.favoritesKey),
            let quotes = try? JSONDecoder().decode([Quote].self, from: data)
        else { return [] }
        return quotes
    }

    func isFavorite(_ quote: Quote) -> Bool {
        favorites.contains(quote)
    }

    func toggleFavorite(_ quote: Quote) {
        var current = favorites
        if let index = current.firstIndex(of: quote) {
            current.remove(at: index)
        } else {
            current.append(quote)
        }
        defaults.set(try? JSONEncoder().encode(current), forKey: Self.favoritesKey)
    }
}
