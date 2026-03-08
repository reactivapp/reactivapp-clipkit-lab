import Foundation

enum CoppedShopifyPublicConfig {
    // Optional default store. Set this if you want public catalog loading without URL query params.
    // Example: "your-store.myshopify.com"
    static let defaultStoreDomain: String? = nil
    static let productsLimit = 250
}

enum CoppedCatalogSource {
    case shopifyPublic
    case fallback
}

struct CoppedCatalogLoadResult {
    let products: [CoppedProduct]
    let source: CoppedCatalogSource
    let storeDomain: String?
    let message: String?
}

actor CoppedShopifyPublicCatalogService {
    static let shared = CoppedShopifyPublicCatalogService()

    private var cachedProductsByDomain: [String: [CoppedProduct]] = [:]

    func loadCatalog(storeDomainOverride: String?) async -> CoppedCatalogLoadResult {
        let resolvedDomain = normalizeStoreDomain(storeDomainOverride)
            ?? normalizeStoreDomain(CoppedShopifyPublicConfig.defaultStoreDomain)

        guard let resolvedDomain else {
            let fallback = CoppedCatalog.fallbackProducts
            CoppedCatalog.updatePublicProducts(fallback)
            await CoppedMockBackend.shared.prepareDemoCatalog(with: fallback)
            return CoppedCatalogLoadResult(
                products: fallback,
                source: .fallback,
                storeDomain: nil,
                message: "Using fallback catalog. Add ?store=<domain> to load public Shopify products.json."
            )
        }

        if let cached = cachedProductsByDomain[resolvedDomain], !cached.isEmpty {
            CoppedCatalog.updatePublicProducts(cached)
            await CoppedMockBackend.shared.prepareDemoCatalog(with: cached)
            return CoppedCatalogLoadResult(
                products: cached,
                source: .shopifyPublic,
                storeDomain: resolvedDomain,
                message: nil
            )
        }

        do {
            let products = try await fetchProducts(domain: resolvedDomain)
            let mapped = mapProducts(products)

            guard !mapped.isEmpty else {
                throw CatalogError.emptyCatalog
            }

            cachedProductsByDomain[resolvedDomain] = mapped
            CoppedCatalog.updatePublicProducts(mapped)
            await CoppedMockBackend.shared.prepareDemoCatalog(with: mapped)

            return CoppedCatalogLoadResult(
                products: mapped,
                source: .shopifyPublic,
                storeDomain: resolvedDomain,
                message: "Loaded \(mapped.count) public products from \(resolvedDomain)."
            )
        } catch {
            let fallback = CoppedCatalog.fallbackProducts
            CoppedCatalog.updatePublicProducts(fallback)
            await CoppedMockBackend.shared.prepareDemoCatalog(with: fallback)

            return CoppedCatalogLoadResult(
                products: fallback,
                source: .fallback,
                storeDomain: resolvedDomain,
                message: "Public catalog failed (\(error.localizedDescription)). Using fallback products."
            )
        }
    }

    // MARK: - Private

    private func fetchProducts(domain: String) async throws -> [ShopifyProduct] {
        var components = URLComponents()
        components.scheme = "https"
        components.host = domain
        components.path = "/products.json"
        components.queryItems = [
            URLQueryItem(name: "limit", value: String(CoppedShopifyPublicConfig.productsLimit))
        ]

        guard let url = components.url else {
            throw CatalogError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw CatalogError.badResponse
        }

        let decoded = try JSONDecoder().decode(ShopifyProductsResponse.self, from: data)
        return decoded.products
    }

    private func mapProducts(_ products: [ShopifyProduct]) -> [CoppedProduct] {
        products.compactMap { product in
            guard let id = product.id else { return nil }
            let rawPrice = product.variants.first?.price ?? "0"
            let numeric = Double(rawPrice.replacingOccurrences(of: ",", with: "")) ?? 0
            let image = product.image?.src ?? product.images.first?.src

            return CoppedProduct(
                id: String(id),
                name: product.title ?? "Product \(id)",
                price: numeric,
                systemImage: symbol(for: product.title ?? ""),
                imageURL: image.flatMap(URL.init(string:))
            )
        }
    }

    private func symbol(for title: String) -> String {
        let lower = title.lowercased()
        if lower.contains("hoodie") || lower.contains("shirt") || lower.contains("tee") {
            return "tshirt.fill"
        }
        if lower.contains("hat") || lower.contains("cap") {
            return "baseballcap.fill"
        }
        if lower.contains("vinyl") || lower.contains("cd") || lower.contains("album") {
            return "opticaldisc.fill"
        }
        if lower.contains("poster") || lower.contains("print") {
            return "photo.artframe"
        }
        return "shippingbox.fill"
    }

    private func normalizeStoreDomain(_ value: String?) -> String? {
        guard var value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
            return nil
        }

        if value.contains("://"),
           let components = URLComponents(string: value),
           let host = components.host,
           !host.isEmpty {
            value = host
        }

        if value.hasPrefix("www.") {
            value = String(value.dropFirst(4))
        }

        guard value.contains(".") else { return nil }
        return value.lowercased()
    }
}

private enum CatalogError: LocalizedError {
    case invalidURL
    case badResponse
    case emptyCatalog

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid public products URL"
        case .badResponse:
            return "Public products endpoint returned non-200 response"
        case .emptyCatalog:
            return "No products found in public catalog"
        }
    }
}

private struct ShopifyProductsResponse: Decodable {
    let products: [ShopifyProduct]
}

private struct ShopifyProduct: Decodable {
    let id: Int64?
    let title: String?
    let image: ShopifyImage?
    let images: [ShopifyImage]
    let variants: [ShopifyVariant]
}

private struct ShopifyImage: Decodable {
    let src: String?
}

private struct ShopifyVariant: Decodable {
    let price: String?
}
