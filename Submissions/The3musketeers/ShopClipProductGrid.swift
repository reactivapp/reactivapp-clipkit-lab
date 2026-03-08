//  ShopClipProductGrid.swift
//  ReactivChallengeKit
//
//  Copyright © 2025 Reactiv Technologies Inc. All rights reserved.
//
//  Edited by Jiamin Gu on 2026-03-07.
//

import SwiftUI

/// A 1-column grid of products. Embeds in a parent ScrollView.
struct ShopClipProductGrid: View {
    let products: [Product]
    let onAddToCart: (Product) -> Void

    var body: some View {
        VStack {
            ForEach(products) { product in
                ProductCard(product: product) {
                    onAddToCart(product)
                }
            }
        }
        .padding(.horizontal, 16)
    }
}
