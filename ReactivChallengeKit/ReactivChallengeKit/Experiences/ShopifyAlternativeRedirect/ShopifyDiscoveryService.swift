//  ShopifyDiscoveryService.swift
//  ReactivChallengeKit
//
//  Copyright © 2025 Reactiv Technologies Inc. All rights reserved.
//

import Foundation

struct ShopifyDiscoveryService {
    struct DiscoveryResult {
        let products: [AlternativeProduct]
        let pipeline: String?
        let sourceStage: String?
        let localityUsed: String?
        let resultQuality: String?
        let reason: String?
        let retryAfterSeconds: Int?
    }

    enum ServiceError: LocalizedError {
        case invalidResponse
        case requestFailed(statusCode: Int)
        case decodeFailed
        case backendUnreachable(endpoints: [String])
        case requestTimedOut(endpoints: [String])

        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "Invalid response from discovery service."
            case .requestFailed(let statusCode):
                return "Discovery request failed (\(statusCode))."
            case .decodeFailed:
                return "Could not parse Shopify alternatives."
            case .backendUnreachable(let endpoints):
                let tried = endpoints.isEmpty ? "configured endpoint" : endpoints.joined(separator: ", ")
                return "Cannot reach discovery backend. Start scripts/start_shopify_backend.sh or configure SHOPIFY_DISCOVERY_ENDPOINT. Tried: \(tried)."
            case .requestTimedOut(let endpoints):
                let tried = endpoints.isEmpty ? "configured endpoint" : endpoints.joined(separator: ", ")
                return "Discovery backend timed out waiting for Gemini. Tried: \(tried)."
            }
        }
    }

    private struct DiscoveryRequest: Encodable {
        let productURL: String
        let localeIdentifier: String?
        let regionCode: String?
        let currencyCode: String?
        let countryHint: String?
    }

    private struct DiscoveryEnvelope: Decodable {
        struct Meta: Decodable {
            let pipeline: String?
            let sourceStage: String?
            let localityUsed: String?
            let resultQuality: String?
            let reason: String?
            let retryAfterSeconds: Int?
        }

        let alternatives: [AlternativeProduct]?
        let products: [AlternativeProduct]?
        let results: [AlternativeProduct]?
        let meta: Meta?
    }

    private let endpointCandidates: [URL]
    private let session: URLSession

    init(
        endpointCandidates: [URL] = ShopifyDiscoveryService.resolveEndpointCandidates(),
        session: URLSession = ShopifyDiscoveryService.makeSession()
    ) {
        self.endpointCandidates = endpointCandidates
        self.session = session
    }

    func fetchAlternatives(productURL: URL) async throws -> DiscoveryResult {
        let requestBody = try JSONEncoder().encode(discoveryRequest(for: productURL))
        var unreachableEndpoints: [String] = []

        for endpointURL in endpointCandidates {
            do {
                return try await fetchAlternatives(from: endpointURL, body: requestBody)
            } catch ServiceError.backendUnreachable(let endpoints) {
                unreachableEndpoints.append(contentsOf: endpoints)
            } catch {
                throw error
            }
        }

        throw ServiceError.backendUnreachable(endpoints: dedupeLabels(unreachableEndpoints))
    }

    private func fetchAlternatives(from endpointURL: URL, body: Data) async throws -> DiscoveryResult {
        var request = URLRequest(url: endpointURL)
        request.httpMethod = "POST"
        request.timeoutInterval = 12
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError {
            let endpoint = endpointLabel(endpointURL)
            if error.code == .timedOut {
                throw ServiceError.requestTimedOut(endpoints: [endpoint])
            }
            if Self.unreachableURLErrorCodes.contains(error.code) {
                throw ServiceError.backendUnreachable(endpoints: [endpoint])
            }
            throw error
        }

        guard let http = response as? HTTPURLResponse else {
            throw ServiceError.invalidResponse
        }

        guard (200 ... 299).contains(http.statusCode) else {
            throw ServiceError.requestFailed(statusCode: http.statusCode)
        }

        return try decodeResult(from: data)
    }

    private func decodeResult(from data: Data) throws -> DiscoveryResult {
        let decoder = JSONDecoder()

        if let wrapped = try? decoder.decode(DiscoveryEnvelope.self, from: data) {
            let products = wrapped.alternatives ?? wrapped.products ?? wrapped.results ?? []
            let normalizedReason: String? = {
                if let reason = wrapped.meta?.reason, !reason.isEmpty {
                    return reason
                }
                return products.isEmpty ? "no_valid_candidates" : nil
            }()
            let normalizedStage: String? = {
                if let sourceStage = wrapped.meta?.sourceStage, !sourceStage.isEmpty {
                    return sourceStage
                }
                return products.isEmpty ? "none" : "single"
            }()
            return DiscoveryResult(
                products: filterProducts(products),
                pipeline: wrapped.meta?.pipeline,
                sourceStage: normalizedStage,
                localityUsed: wrapped.meta?.localityUsed,
                resultQuality: wrapped.meta?.resultQuality,
                reason: normalizedReason,
                retryAfterSeconds: wrapped.meta?.retryAfterSeconds
            )
        }

        if let products = try? decoder.decode([AlternativeProduct].self, from: data) {
            return DiscoveryResult(
                products: filterProducts(products),
                pipeline: nil,
                sourceStage: nil,
                localityUsed: nil,
                resultQuality: nil,
                reason: nil,
                retryAfterSeconds: nil
            )
        }

        throw ServiceError.decodeFailed
    }

    private func filterProducts(_ products: [AlternativeProduct]) -> [AlternativeProduct] {
        var seen: Set<String> = []
        return products.filter { product in
            guard product.isEligibleShopifyAlternative else { return false }
            return seen.insert(product.productURL).inserted
        }
    }

    private func discoveryRequest(for productURL: URL) -> DiscoveryRequest {
        DiscoveryRequest(
            productURL: productURL.absoluteString,
            localeIdentifier: Locale.current.identifier,
            regionCode: Locale.current.region?.identifier,
            currencyCode: Locale.current.currency?.identifier,
            countryHint: Self.countryHint(from: productURL)
        )
    }

    private static func countryHint(from url: URL) -> String? {
        guard let host = url.host?.lowercased() else { return nil }

        let tld = host.split(separator: ".").last.map(String.init) ?? ""
        switch tld {
        case "ca": return "CA"
        case "us": return "US"
        case "uk": return "GB"
        case "au": return "AU"
        case "nz": return "NZ"
        default: break
        }

        let path = url.path.lowercased()
        if path.hasPrefix("/en-ca") || path.hasPrefix("/ca") { return "CA" }
        if path.hasPrefix("/en-us") || path.hasPrefix("/us") { return "US" }
        return nil
    }

    private static func makeSession() -> URLSession {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 12
        config.timeoutIntervalForResource = 12
        config.waitsForConnectivity = false
        return URLSession(configuration: config)
    }

    private static let unreachableURLErrorCodes: Set<URLError.Code> = [
        .cannotFindHost,
        .dnsLookupFailed,
        .cannotConnectToHost,
        .notConnectedToInternet,
    ]

    private static func resolveEndpointCandidates() -> [URL] {
        let env = ProcessInfo.processInfo.environment["SHOPIFY_DISCOVERY_ENDPOINT"]
        let plist = Bundle.main.object(forInfoDictionaryKey: "SHOPIFY_DISCOVERY_ENDPOINT") as? String
        let defaults = [
            "http://127.0.0.1:8899/discover-shopify-alternatives",
            "http://localhost:8899/discover-shopify-alternatives",
        ]

        var urls: [URL] = []
        for candidate in [env, plist] {
            guard let candidate, let parsed = normalizeEndpointCandidate(candidate) else { continue }
            urls.append(parsed)
        }
        for candidate in defaults {
            guard let parsed = normalizeEndpointCandidate(candidate) else { continue }
            urls.append(parsed)
        }

        var seen: Set<String> = []
        return urls.filter { seen.insert($0.absoluteString).inserted }
    }

    private static func normalizeEndpointCandidate(_ candidate: String) -> URL? {
        guard var components = URLComponents(string: candidate), components.scheme != nil, components.host != nil else {
            return nil
        }
        if components.path.isEmpty || components.path == "/" {
            components.path = "/discover-shopify-alternatives"
        }
        return components.url
    }

    private func dedupeLabels(_ labels: [String]) -> [String] {
        var seen: Set<String> = []
        return labels.filter { seen.insert($0).inserted }
    }

    private func endpointLabel(_ url: URL) -> String {
        let host = url.host ?? "unknown"
        if let port = url.port {
            return "\(host):\(port)"
        }
        return host
    }
}
