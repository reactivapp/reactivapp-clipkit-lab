import SwiftUI

struct AmountCard: View {
    let amount: Int?
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    private var displayAmount: String {
        if let amount { return "$\(amount)" }
        return "Other"
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(isSelected ? .white : .green)

                Text(displayAmount)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(isSelected ? .white : .primary)

                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(isSelected ? .white.opacity(0.9) : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.green : Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(isSelected ? Color.green : Color(.systemGray4), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}
