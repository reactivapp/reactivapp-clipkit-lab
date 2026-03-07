import SwiftUI

struct StageswagCheckoutView: View {
    let cartItems: [StageswagCartItem]
    let theme: StageswagTheme
    let onBack: () -> Void
    let onPay: () -> Void

    private var subtotal: Double {
        cartItems.reduce(0) { $0 + $1.merchItem.price }
    }

    var body: some View {
        VStack(spacing: 18) {
            Spacer()

            ClipHeader(
                title: "Checkout",
                subtitle: "Pick up at the merch booth after the show",
                systemImage: "bag.fill"
            )
            .padding(.horizontal, 24)

            GlassEffectContainer {
                VStack(spacing: 6) {
                    ForEach(cartItems) { item in
                        checkoutRow(
                            label: item.merchItem.name,
                            detail: item.size.map { "Size: \($0)" },
                            value: String(format: "$%.2f", item.merchItem.price),
                            color: item.merchItem.accentColor
                        )
                    }

                    Divider()
                        .padding(.vertical, 4)

                    summaryRow(label: "Items", value: "\(cartItems.count)")
                    summaryRow(label: "Subtotal", value: String(format: "$%.2f", subtotal))
                    summaryRow(label: "Pickup", value: "Merch Booth #2")
                    summaryRow(label: "Payment", value: "Apple Pay (Mock)")
                }
            }
            .padding(.horizontal, 20)

            HStack(spacing: 10) {
                ClipActionButton(title: "Back", icon: "chevron.left", style: .secondary) {
                    onBack()
                }

                ClipActionButton(title: "Pay Now", icon: "checkmark.circle.fill") {
                    onPay()
                }
            }
            .padding(.horizontal, 0)

            Spacer()
        }
    }

    @ViewBuilder
    private func checkoutRow(label: String, detail: String?, value: String, color: Color) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                if let detail {
                    Text(detail)
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func summaryRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
    }
}
