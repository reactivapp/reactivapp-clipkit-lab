import SwiftUI

struct AmountSelectionView: View {
    let cause: CauseData
    @EnvironmentObject var donationState: DonationState

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    private let amounts: [(amount: Int?, icon: String, label: String)] = [
        (5, "person.fill", "Feed 1 child today"),
        (10, "house.fill", "Feed a family for a day"),
        (25, "shippingbox.fill", "Stock a shelf for a week"),
        (nil, "plus.circle.fill", "Choose your amount"),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("How much would you like to give?")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.giveTextPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 24)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(amounts, id: \.icon) { item in
                        AmountCard(
                            amount: item.amount,
                            icon: item.icon,
                            label: item.label,
                            isSelected: donationState.selectedAmount == (item.amount ?? 0)
                        ) {
                            if let amount = item.amount {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    donationState.selectedAmount = amount
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)

                VStack(spacing: 10) {
                    Text("Where should your gift go?")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.giveTextPrimary)

                    HStack(spacing: 12) {
                        ForEach(cause.causeOptions, id: \.self) { option in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    donationState.causeDirection = option
                                }
                            } label: {
                                Text(option)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(donationState.causeDirection == option ? .white : .giveGreen)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(donationState.causeDirection == option ? Color.giveGreen : Color.clear)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(Color.giveGreen, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                }

                Text("100% goes to \(cause.name). Powered by GiveClip.")
                    .font(.system(size: 12))
                    .foregroundStyle(.giveTextSecondary)
                    .multilineTextAlignment(.center)

                Button {
                    withAnimation(.spring(duration: 0.35)) {
                        donationState.currentScreen = .payment
                    }
                } label: {
                    Text("Continue to Give")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(.giveGreen, in: RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 16)
        }
        .scrollIndicators(.hidden)
    }
}
