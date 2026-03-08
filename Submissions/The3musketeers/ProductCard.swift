//
//  ProductCard.swift
//  ReactivChallengeKit
//
//  Edited by Jiamin Gu on 2026-03-07.
//

import SwiftUI

/// Displays a single merch product with name, price, add-to-cart action, quantity
struct ProductCard: View {
    let product: Product
    let onAddToCart: () -> Void
    
    @State private var amount = 1
    @State private var added = false

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: product.systemImage)
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
                .frame(height: 50)

            Text(product.name)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            Text(product.formattedPrice)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.primary)
            
            HStack {
                
                Stepper("Quantity: \(amount)", value: $amount, in: 1...10)
                        .padding()
                
                Button {
                    added = true
                    for _ in 1...amount {
                        onAddToCart()
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        amount = 1
                        added = false
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: added ? "checkmark" : "plus")
                            .font(.system(size: 9, weight: .bold))
                        Text(added ? "Added" : "Add")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(added ? .green : .blue)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .glassEffect(.regular.interactive(), in: .capsule)
                }
                .animation(.easeInOut(duration: 0.2), value: added)
            }
            .padding(.horizontal,8)

        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    ProductCard(
        product: ChallengeMockData.products[0],
        onAddToCart: {}
    )
}
