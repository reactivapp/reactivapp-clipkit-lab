//  CacheManager.swift
//  ReactivChallengeKit
//
//  Copyright © 2025 Reactiv Technologies Inc. All rights reserved.
//

import CryptoKit
import Foundation

actor CacheManager {
    static let shared = CacheManager()

    private struct CacheEntry {
        let expiresAt: Date
        let products: [AlternativeProduct]
    }

    private let cacheLifetime: TimeInterval = 10 * 60
    private var storage: [String: CacheEntry] = [:]

    func cachedProducts(for productURL: URL) -> [AlternativeProduct]? {
        pruneExpiredEntries()

        let key = Self.cacheKey(for: productURL)
        guard let entry = storage[key], entry.expiresAt > Date() else {
            storage[key] = nil
            return nil
        }

        return entry.products
    }

    func setCachedProducts(_ products: [AlternativeProduct], for productURL: URL) {
        let key = Self.cacheKey(for: productURL)
        storage[key] = CacheEntry(
            expiresAt: Date().addingTimeInterval(cacheLifetime),
            products: products
        )
    }

    func removeCachedProducts(for productURL: URL) {
        storage[Self.cacheKey(for: productURL)] = nil
    }

    private func pruneExpiredEntries() {
        let now = Date()
        storage = storage.filter { $0.value.expiresAt > now }
    }

    private static func cacheKey(for productURL: URL) -> String {
        let input = Data(productURL.absoluteString.utf8)
        let digest = SHA256.hash(data: input)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
