import SwiftUI

struct PaymentView: View {
    let cause: CauseData
    @EnvironmentObject var donationState: DonationState

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 16)

                VStack(spacing: 12) {
                    Text("$\(donationState.finalAmount)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(.green)

                    Text(cause.name)
                        .font(.system(size: 16, weight: .medium))

                    Text(donationState.impactLabel)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
                )
                .padding(.horizontal, 16)

                Button {
                    donationState.isProcessingPayment = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        donationState.isProcessingPayment = false
                        withAnimation(.spring(duration: 0.35)) {
                            donationState.currentScreen = .confirmation
                        }
                    }
                } label: {
                    HStack(spacing: 10) {
                        if donationState.isProcessingPayment {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "apple.logo")
                                .font(.system(size: 20))
                            Text("Give with Apple Pay")
                                .font(.system(size: 18, weight: .semibold))
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(.black, in: RoundedRectangle(cornerRadius: 16))
                }
                .disabled(donationState.isProcessingPayment)
                .padding(.horizontal, 16)

                if donationState.selectedAmount == 10 {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Round up to $12?")
                                .font(.system(size: 15, weight: .semibold))
                            Text("Feed one more child today")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Toggle("", isOn: $donationState.roundUpSelected)
                            .tint(.green)
                            .labelsHidden()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(.secondarySystemBackground))
                    )
                    .padding(.horizontal, 16)
                }

                HStack(spacing: 6) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Text("No account created. Payment secured by Apple Pay.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 16)
        }
        .scrollIndicators(.hidden)
    }
}
