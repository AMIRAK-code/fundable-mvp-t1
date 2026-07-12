import SwiftUI

/// Catalog browser: personalized "For you" shelf plus the full multi-source
/// catalog with search and category filters.
struct ProductsView: View {
    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var model: AppModel

    @State private var searchText = ""
    @State private var selectedCategory: ProductCategory?
    @State private var selectedProduct: Product?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    forYouShelf
                    catalogSection
                }
                .padding(20)
            }
            .themedScreen()
            .navigationTitle("Products")
            .searchable(text: $searchText, prompt: "Search products")
            .sheet(item: $selectedProduct) { product in
                ProductDetailView(product: product)
                    .presentationDetents([.medium, .large])
            }
            .refreshable {
                await model.refreshData()
            }
        }
    }

    // MARK: - For you

    @ViewBuilder
    private var forYouShelf: some View {
        let picks = model.recommendedProducts(limit: 6)
        if !picks.isEmpty && searchText.isEmpty && selectedCategory == nil {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "For you", subtitle: "Scored against your onboarding profile")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(picks) { product in
                            Button {
                                selectedProduct = product
                            } label: {
                                VStack(alignment: .leading, spacing: 8) {
                                    Image(systemName: product.category.symbol)
                                        .font(.title2)
                                        .foregroundStyle(theme.palette.accent)
                                    Spacer(minLength: 0)
                                    Text(product.name)
                                        .font(.subheadline.weight(.bold))
                                        .foregroundStyle(theme.palette.textPrimary)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                    Text(product.brand)
                                        .font(.caption)
                                        .foregroundStyle(theme.palette.textSecondary)
                                    HStack(spacing: 6) {
                                        ratingLabel(product.rating)
                                        Text(product.priceLabel)
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(theme.palette.textSecondary)
                                    }
                                }
                                .padding(14)
                                .frame(width: 170, height: 170, alignment: .topLeading)
                                .background(theme.palette.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Catalog

    private var catalogSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Catalog", subtitle: catalogSubtitle)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Chip(label: "All", isSelected: selectedCategory == nil) {
                        selectedCategory = nil
                    }
                    ForEach(ProductCategory.allCases) { category in
                        Chip(
                            label: category.label,
                            symbol: category.symbol,
                            isSelected: selectedCategory == category
                        ) {
                            selectedCategory = selectedCategory == category ? nil : category
                        }
                    }
                }
            }

            if filteredProducts.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.title)
                        .foregroundStyle(theme.palette.textSecondary)
                    Text(model.products.isEmpty ? "Catalog is loading…" : "No products match")
                        .font(.subheadline)
                        .foregroundStyle(theme.palette.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                VStack(spacing: 10) {
                    ForEach(filteredProducts) { product in
                        Button {
                            selectedProduct = product
                        } label: {
                            productRow(product)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var catalogSubtitle: String {
        let sourceCount = model.sources.filter { $0.itemCount > 0 }.count
        return "\(model.products.count) products aggregated from \(max(1, sourceCount)) sources"
    }

    private var filteredProducts: [Product] {
        model.products.filter { product in
            let matchesCategory = selectedCategory == nil || product.category == selectedCategory
            let matchesSearch = searchText.isEmpty
                || product.name.localizedCaseInsensitiveContains(searchText)
                || product.brand.localizedCaseInsensitiveContains(searchText)
                || product.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            return matchesCategory && matchesSearch
        }
    }

    private func productRow(_ product: Product) -> some View {
        HStack(spacing: 14) {
            Image(systemName: product.category.symbol)
                .font(.title3)
                .foregroundStyle(theme.palette.accent)
                .frame(width: 44, height: 44)
                .background(theme.palette.surfaceSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(product.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(theme.palette.textPrimary)
                Text("\(product.brand) · \(product.category.label)")
                    .font(.caption)
                    .foregroundStyle(theme.palette.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                ratingLabel(product.rating)
                Text(product.priceLabel)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(theme.palette.textSecondary)
            }
        }
        .card()
    }

    private func ratingLabel(_ rating: Double) -> some View {
        HStack(spacing: 3) {
            Image(systemName: "star.fill")
                .font(.caption2)
                .foregroundStyle(theme.palette.caution)
            Text(String(format: "%.1f", rating))
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.palette.textPrimary)
        }
    }
}

// MARK: - Detail sheet

struct ProductDetailView: View {
    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var model: AppModel
    let product: Product

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 16) {
                    Image(systemName: product.category.symbol)
                        .font(.largeTitle)
                        .foregroundStyle(theme.palette.accent)
                        .frame(width: 64, height: 64)
                        .background(theme.palette.surfaceSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(product.name)
                            .font(.system(.title3, design: .rounded).weight(.bold))
                            .foregroundStyle(theme.palette.textPrimary)
                        Text("\(product.brand) · \(product.category.label)")
                            .font(.subheadline)
                            .foregroundStyle(theme.palette.textSecondary)
                        HStack(spacing: 8) {
                            HStack(spacing: 3) {
                                Image(systemName: "star.fill")
                                    .font(.caption)
                                    .foregroundStyle(theme.palette.caution)
                                Text(String(format: "%.1f", product.rating))
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(theme.palette.textPrimary)
                            }
                            Text(product.priceLabel)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(theme.palette.textSecondary)
                        }
                    }
                }

                Text(product.summary)
                    .font(.subheadline)
                    .foregroundStyle(theme.palette.textSecondary)

                let reasons = RoutineEngine.reasons(for: product, profile: model.profile)
                if !reasons.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Why it fits you")
                            .font(.headline)
                            .foregroundStyle(theme.palette.textPrimary)
                        ForEach(reasons, id: \.self) { reason in
                            Label {
                                Text(reason)
                                    .font(.subheadline)
                                    .foregroundStyle(theme.palette.textSecondary)
                            } icon: {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(theme.palette.positive)
                            }
                        }
                    }
                    .card()
                }

                if !product.heroIngredients.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Hero ingredients")
                            .font(.headline)
                            .foregroundStyle(theme.palette.textPrimary)
                        FlowChips(data: product.heroIngredients) { ingredient in
                            Text(ingredient)
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(theme.palette.surfaceSecondary)
                                .foregroundStyle(theme.palette.textPrimary)
                                .clipShape(Capsule())
                        }
                    }
                }

                if let source = product.source {
                    Label("Source: \(source)", systemImage: "tray.2")
                        .font(.caption2)
                        .foregroundStyle(theme.palette.textSecondary)
                }
            }
            .padding(24)
        }
        .presentationBackground(theme.palette.background)
    }
}
