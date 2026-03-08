//  ClipBetPayment.swift
//  ClipBet
//
//  Payment manager handling Apple Pay (user-facing) with
//  Stripe as the invisible backend. Users never see Stripe.
//
//  In production:
//    Apple Pay -> PKPaymentRequest -> Stripe PaymentIntent -> Escrow
//    Resolve -> Stripe Connect transfers to winners
//    Cancel -> Stripe refunds to original payment methods
//
//  For hackathon demo: fully mocked with realistic states.
//

import SwiftUI

// MARK: - Payment State

enum PaymentState: Equatable {
    case idle
    case processing
    case success(transactionId: String)
    case failed(message: String)
    case refunded
}

// MARK: - Payment Method

enum PaymentMethod: String {
    case applePay = "Apple Pay"
    case card = "Card"
}

// MARK: - Escrow State

enum EscrowState: String {
    case pending = "Pending"
    case held = "Held"
    case distributing = "Distributing"
    case distributed = "Distributed"
    case refunding = "Refunding"
    case refunded = "Refunded"
}

// MARK: - Payment Manager

@Observable
final class ClipBetPaymentManager {

    var paymentState: PaymentState = .idle
    var selectedMethod: PaymentMethod = .applePay
    var escrowState: EscrowState = .pending

    // In production this would be the Stripe PaymentIntent ID
    private(set) var paymentIntentId: String?

    // Platform fee percentage
    let platformFeeRate: Double = 0.05

    /// Processes a bet payment. In production this would:
    /// 1. Create a Stripe PaymentIntent on the backend
    /// 2. Present Apple Pay sheet (PKPaymentAuthorizationViewController)
    /// 3. Confirm the PaymentIntent with the Apple Pay token
    /// 4. Hold funds in escrow on the platform Stripe account
    func processBet(
        amount: Double,
        eventId: UUID,
        outcomeId: UUID,
        email: String,
        nickname: String,
        completion: @escaping (Bool) -> Void
    ) {
        paymentState = .processing

        if !ClipBetAPIConfig.useMockData {
            // Real API: get Stripe client_secret from backend
            ClipBetAPI.shared.placeBet(
                eventId: eventId.uuidString,
                optionId: outcomeId.uuidString,
                amount: amount,
                email: email,
                nickname: nickname
            ) { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(let response):
                    // In production: use response.client_secret with PKPaymentRequest
                    // For hackathon: mark as success directly
                    self.paymentIntentId = response.payment_intent_id
                    self.paymentState = .success(transactionId: response.payment_intent_id)
                    self.escrowState = .held
                    completion(true)
                case .failure(let error):
                    self.paymentState = .failed(message: error.localizedDescription)
                    completion(false)
                }
            }
            return
        }

        // Mock: simulate network delay for PaymentIntent creation + Apple Pay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self else { return }

            // Simulate 95% success rate
            let success = Double.random(in: 0...1) < 0.95

            if success {
                let txId = "pi_\(UUID().uuidString.prefix(8))"
                self.paymentIntentId = txId
                self.paymentState = .success(transactionId: txId)
                self.escrowState = .held
                completion(true)
            } else {
                self.paymentState = .failed(message: "Payment could not be completed. Please try again.")
                completion(false)
            }
        }
    }

    // MARK: - Distribute Winnings

    /// Called when organizer resolves the event. In production:
    /// 1. Backend calculates each winner's share
    /// 2. Deducts 5% platform fee
    /// 3. Creates Stripe Connect transfers to winner payment methods
    /// 4. Organizer gets their fee share via Stripe Connect
    func distributeWinnings(
        event: PredictionEvent,
        winningOutcomeId: UUID,
        completion: @escaping ([(nickname: String, payout: Double)]) -> Void
    ) {
        escrowState = .distributing

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self else { return }
            guard let winningOutcome = event.outcomes.first(where: { $0.id == winningOutcomeId }) else {
                return
            }

            let totalPool = event.totalPool
            let fee = totalPool * self.platformFeeRate
            let winnerPool = totalPool - fee

            // Parimutuel: each winner gets proportional share
            // In production, each individual bet amount is tracked
            let payoutPerDollar = winnerPool / winningOutcome.totalAmount

            // Mock payout list
            let payouts: [(nickname: String, payout: Double)] = [
                ("Winner1", 25.0 * payoutPerDollar),
                ("Winner2", 10.0 * payoutPerDollar),
            ]

            self.escrowState = .distributed
            completion(payouts)
        }
    }

    // MARK: - Process Refund

    /// Called when organizer cancels or 24h resolution window expires.
    /// In production: triggers Stripe refunds to original payment methods.
    func processRefund(completion: @escaping (Bool) -> Void) {
        escrowState = .refunding

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.escrowState = .refunded
            self?.paymentState = .refunded
            completion(true)
        }
    }

    // MARK: - Reset

    func reset() {
        paymentState = .idle
        paymentIntentId = nil
        escrowState = .pending
    }
}

// MARK: - Apple Pay Button View

struct ClipBetApplePayButton: View {
    let amount: Double
    let isEnabled: Bool
    let isProcessing: Bool
    let onTap: () -> Void
    let onCardFallback: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            // Primary: Apple Pay
            Button(action: onTap) {
                HStack(spacing: 8) {
                    if isProcessing {
                        ProgressView()
                            .tint(ClipBetColors.dark)
                    } else {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 18))
                        Text("PAY WITH APPLE PAY")
                            .font(.custom("DM Mono", size: 13))
                            .kerning(2)
                    }
                }
                .foregroundColor(ClipBetColors.dark)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 2))
            }
            .disabled(!isEnabled || isProcessing)
            .opacity(isEnabled ? 1.0 : 0.5)

            // Fallback: Pay with card (still Stripe underneath, no branding)
            Button(action: onCardFallback) {
                Text("or pay with card")
                    .font(.custom("DM Mono", size: 11))
                    .foregroundColor(ClipBetColors.textFaint)
                    .underline()
            }
            .disabled(!isEnabled || isProcessing)
        }
    }
}

// MARK: - Payment Status View

struct ClipBetPaymentStatus: View {
    let state: PaymentState

    var body: some View {
        switch state {
        case .idle:
            EmptyView()

        case .processing:
            HStack(spacing: 8) {
                ProgressView()
                    .tint(ClipBetColors.textSecondary)
                Text("PROCESSING")
                    .font(.custom("DM Mono", size: 10))
                    .kerning(1.6)
                    .foregroundColor(ClipBetColors.textSecondary)
            }
            .padding(.vertical, 8)

        case .success(let txId):
            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(ClipBetColors.yes)
                    Text("PAYMENT CONFIRMED")
                        .font(.custom("DM Mono", size: 10))
                        .kerning(1.6)
                        .foregroundColor(ClipBetColors.yes)
                }
                Text(txId)
                    .font(.custom("DM Mono", size: 9))
                    .foregroundColor(ClipBetColors.textFaint)
            }
            .padding(.vertical, 8)

        case .failed(let message):
            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(ClipBetColors.no)
                    Text("PAYMENT FAILED")
                        .font(.custom("DM Mono", size: 10))
                        .kerning(1.6)
                        .foregroundColor(ClipBetColors.no)
                }
                Text(message)
                    .font(.custom("DM Mono", size: 10))
                    .foregroundColor(ClipBetColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 8)

        case .refunded:
            HStack(spacing: 6) {
                Image(systemName: "arrow.uturn.backward.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(ClipBetColors.textSecondary)
                Text("REFUNDED")
                    .font(.custom("DM Mono", size: 10))
                    .kerning(1.6)
                    .foregroundColor(ClipBetColors.textSecondary)
            }
            .padding(.vertical, 8)
        }
    }
}
