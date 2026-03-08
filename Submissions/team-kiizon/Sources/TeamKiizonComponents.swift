// TeamKiizonComponents.swift
import SwiftUI

// MARK: - Menu Item Card

private struct BistroMenuItemCard: View {
    let item: BistroMenuItem
    let language: Language
    let onAdd: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.displayName(language))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.primary)
                        if language == .en || language == .fr {
                            Text(item.nameZH)
                                .font(.system(size: 11))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    Spacer()
                    Text(String(format: "$%.2f", item.price))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.primary)
                }

                Text(item.displayDescription(language))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                HStack(spacing: 4) {
                    ForEach(item.allergens.prefix(3), id: \.self) { allergen in
                        Text(allergen)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(.quaternarySystemFill), in: Capsule())
                    }
                    Spacer()
                    Text("\(item.calories) cal")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }

                Button(action: onAdd) {
                    Label(
                        language == .zh ? "加入订单" : language == .fr ? "Ajouter" : "Add to order",
                        systemImage: "plus.circle.fill"
                    )
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.orange)
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            }

            itemThumbnail
        }
        .padding(14)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)
    }

    @ViewBuilder
    private var itemThumbnail: some View {
        if let assetName = item.localImagePath,
           let uiImage = UIImage(named: assetName) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        } else {
            Image(systemName: item.systemImage)
                .font(.system(size: 20))
                .foregroundStyle(.secondary)
                .frame(width: 50, height: 50)
                .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 12))
        }
    }
}
