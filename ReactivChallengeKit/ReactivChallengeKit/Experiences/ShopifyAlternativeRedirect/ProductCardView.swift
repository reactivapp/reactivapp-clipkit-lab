//  ProductCardView.swift
//  ReactivChallengeKit
//
//  Copyright © 2025 Reactiv Technologies Inc. All rights reserved.
//

import SwiftUI

struct ProductCardView: View {
    let product: AlternativeProduct
    let onVisitStore: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            imageSection

            VStack(alignment: .leading, spacing: 8) {
                Text(product.productName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text(product.storeName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text(product.price)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.primary)

                Button(action: onVisitStore) {
                    HStack(spacing: 8) {
                        Image(systemName: "safari.fill")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Visit Store")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.blue, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
            .padding(16)
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.12), radius: 14, x: 0, y: 8)
    }

    private var imageSection: some View {
        AsyncImage(url: product.resolvedImageURL) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            case .empty:
                fallbackArt
            default:
                fallbackArt
            }
        }
        .frame(height: 190)
        .frame(maxWidth: .infinity)
        .clipped()
    }

    private var fallbackArt: some View {
        ProductFallbackArt(product: product)
    }
}

private struct ProductFallbackArt: View {
    let product: AlternativeProduct

    private var palette: [Color] {
        let palettes: [[Color]] = [
            [Color(red: 0.18, green: 0.48, blue: 0.94), Color(red: 0.05, green: 0.17, blue: 0.44)],
            [Color(red: 0.12, green: 0.62, blue: 0.42), Color(red: 0.03, green: 0.26, blue: 0.18)],
            [Color(red: 0.93, green: 0.47, blue: 0.18), Color(red: 0.42, green: 0.14, blue: 0.05)],
            [Color(red: 0.73, green: 0.33, blue: 0.21), Color(red: 0.30, green: 0.11, blue: 0.09)],
            [Color(red: 0.28, green: 0.54, blue: 0.55), Color(red: 0.09, green: 0.22, blue: 0.27)],
        ]
        return palettes[abs(product.placeholderSeed) % palettes.count]
    }

    private var symbolName: String {
        switch product.placeholderCategory {
        case .electronics:
            return "laptopcomputer"
        case .audio:
            return "headphones"
        case .outdoors:
            return "backpack"
        case .apparel:
            return "tshirt"
        case .home:
            return "lamp.table"
        case .defaultCategory:
            return "shippingbox"
        }
    }

    private var accentOffset: CGSize {
        let x = CGFloat((abs(product.placeholderSeed) % 48) - 24)
        let y = CGFloat(((abs(product.placeholderSeed) / 7) % 36) - 18)
        return CGSize(width: x, height: y)
    }

    private var categoryLabel: String {
        switch product.placeholderCategory {
        case .electronics:
            return "Tech"
        case .audio:
            return "Audio"
        case .outdoors:
            return "Outdoor"
        case .apparel:
            return "Apparel"
        case .home:
            return "Home"
        case .defaultCategory:
            return "Product"
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [palette[0], palette[1]],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(.white.opacity(0.10))
                .frame(width: 168, height: 168)
                .offset(x: -70 + accentOffset.width, y: -48)

            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.white.opacity(0.10))
                .frame(width: 132, height: 132)
                .rotationEffect(.degrees(Double(product.placeholderSeed % 18) - 9))
                .offset(x: 84, y: 44 + accentOffset.height)

            VStack(spacing: 12) {
                Image(systemName: symbolName)
                    .font(.system(size: 54, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.92))
                    .frame(width: 92, height: 92)
                    .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 24, style: .continuous))

                Text(categoryLabel.uppercased())
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(.white.opacity(0.84))
            }
        }
    }
}
