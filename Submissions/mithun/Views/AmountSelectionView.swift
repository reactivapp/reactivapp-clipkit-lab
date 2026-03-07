import SwiftUI

struct AmountSelectionView: View {
    let cause: CauseData
    @EnvironmentObject var donationState: DonationState

    @State private var isOtherSelected = false
    @State private var customAmountText = ""
    @FocusState private var isCustomFieldFocused: Bool

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    private let presetAmounts: [(amount: Int, icon: String, label: String)] = [
        (5, "person.fill", "Feed 1 child today"),
        (10, "house.fill", "Feed a family for a day"),
        (25, "shippingbox.fill", "Stock a shelf for a week"),
    ]

    private var isPresetSelected: Bool {
        !isOtherSelected && [5, 10, 25].contains(donationState.selectedAmount)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("How much would you like to give?")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.giveTextPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 24)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(presetAmounts, id: \.icon) { item in
                        AmountCard(
                            amount: item.amount,
                            icon: item.icon,
                            label: item.label,
                            isSelected: !isOtherSelected && donationState.selectedAmount == item.amount
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isOtherSelected = false
                                donationState.selectedAmount = item.amount
                                isCustomFieldFocused = false
                            }
                        }
                    }

                    AmountCard(
                        amount: nil,
                        icon: "plus.circle.fill",
                        label: "Choose your amount",
                        isSelected: isOtherSelected
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isOtherSelected = true
                            isCustomFieldFocused = true
                        }
                    }
                }
                .padding(.horizontal, 16)

                if isOtherSelected {
                    HStack(spacing: 4) {
                        Text("$")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.giveGreen)

                        TextField("0", text: $customAmountText)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.giveTextPrimary)
                            .keyboardType(.numberPad)
                            .focused($isCustomFieldFocused)
                            .onChange(of: customAmountText) { _, newValue in
                                let filtered = newValue.filter { $0.isNumber }
                                if filtered != newValue {
                                    customAmountText = filtered
                                }
                                if let value = Int(filtered), value > 0 {
                                    donationState.selectedAmount = min(value, 9999)
                                }
                            }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.giveLightGreen)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Color.giveGreen, lineWidth: 1.5)
                    )
                    .padding(.horizontal, 16)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

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
                    isCustomFieldFocused = false
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
                .disabled(isOtherSelected && (Int(customAmountText) ?? 0) < 1)
                .opacity(isOtherSelected && (Int(customAmountText) ?? 0) < 1 ? 0.5 : 1.0)
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 16)
        }
        .scrollIndicators(.hidden)
    }
}
