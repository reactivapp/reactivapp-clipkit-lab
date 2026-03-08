//  ShopifyAlternativeViewModel.swift
//  ReactivChallengeKit
//
//  Copyright © 2025 Reactiv Technologies Inc. All rights reserved.
//

internal import Combine
import Foundation

@MainActor
final class ShopifyAlternativeViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case loading
        case loaded
        case error(String)
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var products: [AlternativeProduct] = []
    @Published private(set) var sourceProductURL: URL?
    @Published private(set) var sourceStage: String?
    @Published private(set) var emptyReason: String?
    @Published private(set) var discoveryNote: String?
    @Published private(set) var retryAfterSeconds: Int?
    @Published var inputURLText: String = ""

    private let service: ShopifyDiscoveryService
    private let cache: CacheManager

    init(
        service: ShopifyDiscoveryService? = nil,
        cache: CacheManager = .shared
    ) {
        self.service = service ?? ShopifyDiscoveryService()
        self.cache = cache
    }

    var isLoading: Bool {
        if case .loading = state {
            return true
        }
        return false
    }

    func loadIfNeeded(from context: ClipContext) async {
        if inputURLText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            inputURLText = context.queryParameters["url"] ?? ""
        }
        guard case .idle = state else { return }
        await loadFromInput(forceRefresh: false)
    }

    func submitURL() async {
        guard !isLoading else { return }
        await loadFromInput(forceRefresh: true)
    }

    private func loadFromInput(forceRefresh: Bool) async {
        guard !isLoading else { return }

        guard let productURL = parseProductURL(rawValue: inputURLText) else {
            sourceProductURL = nil
            products = []
            emptyReason = nil
            sourceStage = nil
            discoveryNote = nil
            retryAfterSeconds = nil
            state = .error("Paste a valid product URL to continue.")
            return
        }

        sourceProductURL = productURL

        if !forceRefresh, let cached = await cache.cachedProducts(for: productURL) {
            products = cached
            emptyReason = nil
            sourceStage = nil
            discoveryNote = nil
            retryAfterSeconds = nil
            state = .loaded
            return
        }

        state = .loading

        do {
            let result = try await service.fetchAlternatives(productURL: productURL)
            if shouldCacheResult(result) {
                await cache.setCachedProducts(result.products, for: productURL)
            } else {
                await cache.removeCachedProducts(for: productURL)
            }
            products = result.products
            sourceStage = result.sourceStage
            emptyReason = result.reason
            discoveryNote = note(for: result)
            retryAfterSeconds = result.retryAfterSeconds
            state = .loaded
        } catch {
            products = []
            sourceStage = nil
            emptyReason = nil
            discoveryNote = nil
            retryAfterSeconds = nil
            state = .error(error.localizedDescription)
        }
    }

    var emptyStateMessage: String {
        guard let reason = emptyReason?.lowercased(), !reason.isEmpty else {
            if sourceStage?.lowercased() == "single_rescue" {
                return "No close alternatives were found after broadened search."
            }
            return "No matching alternatives were returned."
        }

        if reason.contains("sparse_local_matches") {
            return "Only a few nearby matches were found."
        }
        if reason.contains("sparse_matches") {
            if sourceStage?.lowercased() == "single_rescue" {
                return "Showing broadened comparable alternatives."
            }
            return "Only a few matching alternatives were found."
        }
        if reason.contains("fallback_recent_category_matches") {
            return "Showing recent comparable alternatives while live search catches up."
        }
        if reason.contains("no_valid_candidates") {
            return "No usable retailer alternatives were found."
        }
        if reason.contains("no_candidates_from_gemini") {
            if sourceStage?.lowercased() == "single_rescue" {
                return "Gemini could not find usable alternatives for this product."
            }
            return "No matching alternatives were returned."
        }
        if reason.contains("gemini_rate_limited") {
            if let retryAfterSeconds {
                return "Gemini quota is currently exceeded. Try again in about \(retryAfterSeconds)s."
            }
            return "Gemini quota is currently exceeded. Try again shortly."
        }
        if reason.contains("gemini_not_configured") {
            return "Discovery backend is not configured."
        }
        if reason.contains("gemini_timeout") {
            return "Discovery timed out. Try again."
        }
        if reason.contains("gemini_unavailable") {
            return "Gemini is currently unavailable."
        }

        return "No matching alternatives were returned."
    }

    private func shouldCacheResult(_ result: ShopifyDiscoveryService.DiscoveryResult) -> Bool {
        guard !result.products.isEmpty else { return false }
        guard let reason = result.reason?.lowercased(), !reason.isEmpty else { return true }
        return !reason.hasPrefix("gemini_")
    }

    private func note(for result: ShopifyDiscoveryService.DiscoveryResult) -> String? {
        if result.products.isEmpty {
            return nil
        }

        if result.sourceStage?.lowercased() == "single_rescue" {
            return "Showing broadened comparable retailer matches."
        }

        guard let reason = result.reason?.lowercased() else {
            return nil
        }

        if reason.contains("fallback_recent_category_matches") {
            return "Showing recent comparable retailer matches from cached discovery."
        }
        if reason.contains("sparse_local_matches") {
            return "Showing the strongest nearby retailer matches."
        }
        if reason.contains("sparse_matches") {
            return "Showing the strongest comparable retailer matches."
        }
        return nil
    }

    private func parseProductURL(rawValue: String) -> URL? {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let direct = URL(string: trimmed), direct.scheme != nil {
            return unwrapInvocationURLIfNeeded(direct)
        }

        if let decoded = trimmed.removingPercentEncoding,
           let decodedURL = URL(string: decoded),
           decodedURL.scheme != nil {
            return unwrapInvocationURLIfNeeded(decodedURL)
        }

        let withScheme = "https://\(trimmed)"
        guard let url = URL(string: withScheme) else { return nil }
        return unwrapInvocationURLIfNeeded(url)
    }

    private func unwrapInvocationURLIfNeeded(_ url: URL) -> URL {
        guard
            let host = url.host?.lowercased(),
            host.contains("localclip.ai"),
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let embedded = components.queryItems?.first(where: { $0.name == "url" })?.value,
            let decoded = embedded.removingPercentEncoding,
            let parsed = URL(string: decoded),
            parsed.scheme != nil
        else {
            return url
        }
        return parsed
    }
}
