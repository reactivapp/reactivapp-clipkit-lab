//  ProductModels.swift
//  ReactivChallengeKit
//
//  Copyright © 2025 Reactiv Technologies Inc. All rights reserved.
//

import Foundation

struct AlternativeProduct: Codable, Hashable, Identifiable {
    enum PlaceholderCategory: String {
        case electronics
        case audio
        case outdoors
        case apparel
        case home
        case defaultCategory
    }

    let storeName: String
    let productName: String
    let price: String
    let productURL: String
    let imageURL: String?

    var id: String { productURL }

    var resolvedProductURL: URL? {
        URL(string: productURL)
    }

    var resolvedImageURL: URL? {
        guard let imageURL else { return nil }
        return URL(string: imageURL)
    }

    var placeholderCategory: PlaceholderCategory {
        let text = "\(productName) \(storeName)".lowercased()
        if text.contains("headphone") || text.contains("earbud") || text.contains("speaker") || text.contains("audio") {
            return .audio
        }
        if text.contains("laptop") || text.contains("notebook") || text.contains("computer") || text.contains("desktop") || text.contains("monitor") {
            return .electronics
        }
        if text.contains("backpack") || text.contains("bag") || text.contains("hiking") || text.contains("trail") || text.contains("camp") {
            return .outdoors
        }
        if text.contains("shirt") || text.contains("hoodie") || text.contains("jacket") || text.contains("shoe") || text.contains("pant") {
            return .apparel
        }
        if text.contains("kitchen") || text.contains("home") || text.contains("cookware") || text.contains("furniture") || text.contains("bedding") {
            return .home
        }
        return .defaultCategory
    }

    var placeholderSeed: Int {
        stableSeed(for: "\(productName)|\(storeName)")
    }

    var isEligibleShopifyAlternative: Bool {
        !isBlockedMarketplace && resolvedProductURL != nil
    }

    private var isBlockedMarketplace: Bool {
        let normalizedStore = storeName.lowercased()
        let host = resolvedProductURL?.host?.lowercased() ?? ""

        return Self.blockedKeywords.contains { keyword in
            normalizedStore.contains(keyword) || host.contains(keyword)
        }
    }

    private static let blockedKeywords: [String] = [
        "amazon",
        "walmart",
        "target",
        "bestbuy",
        "best-buy",
        "ebay",
        "temu",
        "aliexpress",
        "costco",
        "home depot",
        "homedepot",
        "lowes",
    ]

    private func stableSeed(for value: String) -> Int {
        value.unicodeScalars.reduce(5381) { partial, scalar in
            ((partial << 5) &+ partial) &+ Int(scalar.value)
        }
    }
}
