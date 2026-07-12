import Foundation

// MARK: - Source status (surfaced in Settings)

struct DataSourceStatus: Identifiable, Hashable {
    let id: String
    let name: String
    /// "Bundled" or "Remote"
    let kind: String
    var itemCount: Int
    var state: String
    var lastUpdated: Date?
}

// MARK: - DataHub

/// Aggregates the product catalog and tips library from multiple sources:
///  1. Bundled curated catalog (`products.json`)
///  2. Bundled tips library (`tips.json`)
///  3. An optional remote catalog (any URL serving `CatalogPayload` JSON),
///     cached on disk for offline use. Remote entries override bundled ones
///     with the same id, so a hosted feed can update products between releases.
final class DataHub {
    static let shared = DataHub()

    static let remoteURLKey = "mane.remoteCatalogURL"

    struct LoadResult {
        var products: [Product] = []
        var tips: [Tip] = []
        var sources: [DataSourceStatus] = []
    }

    private let decoder = JSONDecoder()

    private var cacheURL: URL? {
        guard let dir = try? FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask,
            appropriateFor: nil, create: true
        ) else { return nil }
        return dir.appendingPathComponent("mane-remote-catalog.json")
    }

    func loadAll() async -> LoadResult {
        var result = LoadResult()
        var productMap: [String: Product] = [:]
        var tipMap: [String: Tip] = [:]

        // 1. Bundled curated catalog
        if let payload = decodeBundle(resource: "products") {
            merge(payload, source: "Curated catalog", into: &productMap, tips: &tipMap)
            result.sources.append(DataSourceStatus(
                id: "bundle-products", name: "Curated catalog", kind: "Bundled",
                itemCount: payload.products?.count ?? 0, state: "Loaded", lastUpdated: nil
            ))
        } else {
            result.sources.append(DataSourceStatus(
                id: "bundle-products", name: "Curated catalog", kind: "Bundled",
                itemCount: 0, state: "Missing from bundle", lastUpdated: nil
            ))
        }

        // 2. Bundled tips library
        if let payload = decodeBundle(resource: "tips") {
            merge(payload, source: "Tips library", into: &productMap, tips: &tipMap)
            result.sources.append(DataSourceStatus(
                id: "bundle-tips", name: "Grooming tips library", kind: "Bundled",
                itemCount: payload.tips?.count ?? 0, state: "Loaded", lastUpdated: nil
            ))
        } else {
            result.sources.append(DataSourceStatus(
                id: "bundle-tips", name: "Grooming tips library", kind: "Bundled",
                itemCount: 0, state: "Missing from bundle", lastUpdated: nil
            ))
        }

        // 3. Remote community catalog (optional, cached)
        let urlString = UserDefaults.standard.string(forKey: Self.remoteURLKey) ?? ""
        if let url = URL(string: urlString), !urlString.isEmpty {
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                let payload = try decoder.decode(CatalogPayload.self, from: data)
                if let cacheURL { try? data.write(to: cacheURL) }
                merge(payload, source: "Community feed", into: &productMap, tips: &tipMap)
                result.sources.append(DataSourceStatus(
                    id: "remote", name: "Community feed", kind: "Remote",
                    itemCount: (payload.products?.count ?? 0) + (payload.tips?.count ?? 0),
                    state: "Live", lastUpdated: Date()
                ))
            } catch {
                if let cached = loadCachedRemote() {
                    merge(cached, source: "Community feed (cached)", into: &productMap, tips: &tipMap)
                    result.sources.append(DataSourceStatus(
                        id: "remote", name: "Community feed", kind: "Remote",
                        itemCount: (cached.products?.count ?? 0) + (cached.tips?.count ?? 0),
                        state: "Offline — using cache", lastUpdated: cacheDate()
                    ))
                } else {
                    result.sources.append(DataSourceStatus(
                        id: "remote", name: "Community feed", kind: "Remote",
                        itemCount: 0, state: "Unreachable", lastUpdated: nil
                    ))
                }
            }
        } else {
            result.sources.append(DataSourceStatus(
                id: "remote", name: "Community feed", kind: "Remote",
                itemCount: 0, state: "Not configured — add a URL in Settings", lastUpdated: nil
            ))
        }

        result.products = productMap.values.sorted {
            ($0.category.rawValue, $0.name) < ($1.category.rawValue, $1.name)
        }
        result.tips = tipMap.values.sorted { $0.id < $1.id }
        return result
    }

    // MARK: - Internals

    private func decodeBundle(resource: String) -> CatalogPayload? {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? decoder.decode(CatalogPayload.self, from: data)
    }

    private func loadCachedRemote() -> CatalogPayload? {
        guard let cacheURL, let data = try? Data(contentsOf: cacheURL) else { return nil }
        return try? decoder.decode(CatalogPayload.self, from: data)
    }

    private func cacheDate() -> Date? {
        guard let cacheURL else { return nil }
        let attrs = try? FileManager.default.attributesOfItem(atPath: cacheURL.path)
        return attrs?[.modificationDate] as? Date
    }

    private func merge(
        _ payload: CatalogPayload,
        source: String,
        into products: inout [String: Product],
        tips: inout [String: Tip]
    ) {
        for var product in payload.products ?? [] {
            product.source = source
            products[product.id] = product
        }
        for tip in payload.tips ?? [] {
            tips[tip.id] = tip
        }
    }
}
