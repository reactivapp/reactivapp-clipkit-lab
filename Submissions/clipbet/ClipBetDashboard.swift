//  ClipBetDashboard.swift
//  ClipBet
//
//  Organizer dashboard showing live pool stats.
//  Includes Resolve, Cancel, Close Bets, and Share QR actions.
//

import SwiftUI

// MARK: - Dashboard View

struct OrganizerDashboard: View {
    @State private var event: PredictionEvent = ClipBetMockData.primaryEvent
    @State private var showResolveSheet = false
    @State private var showCancelConfirm = false
    @State private var showCloseConfirm = false
    @State private var selectedWinner: BetOutcome?
    @State private var showResolveConfirm = false
    @State private var appeared = false
    @State private var paymentManager = ClipBetPaymentManager()

    var body: some View {
        ZStack {
            ClipBetColors.bg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 12) {
                        Text("Dashboard")
                            .font(.custom("Cormorant Garamond", size: 28))
                            .fontWeight(.light)
                            .foregroundColor(ClipBetColors.textPrimary)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 8)

                        StatusIndicator(status: event.status)
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 20)

                    ClipBetDivider()

                    // Event name
                    Text(event.name)
                        .font(.custom("Cormorant Garamond", size: 22))
                        .fontWeight(.light)
                        .foregroundColor(ClipBetColors.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 20)

                    ClipBetDivider()

                    // Pool stats
                    HStack(spacing: 0) {
                        StatColumn(value: event.formattedPool, label: "TOTAL POOL")
                        ClipBetVerticalDivider()
                        StatColumn(value: "\(event.totalBettors)", label: "BETTORS")
                    }
                    .padding(.vertical, 16)

                    HStack(spacing: 0) {
                        StatColumn(value: String(format: "$%.0f", event.platformFee), label: "PLATFORM FEE 5%")
                        ClipBetVerticalDivider()
                        StatColumn(value: String(format: "$%.0f", event.winnerPool), label: "WINNER POOL")
                    }
                    .padding(.vertical, 16)

                    MonoLabel(text: "Started \(event.timeSinceCreated) ago")
                        .padding(.bottom, 16)

                    ClipBetDivider()

                    // Outcomes with animated bars
                    VStack(spacing: 0) {
                        ForEach(Array(event.outcomes.enumerated()), id: \.element.id) { index, outcome in
                            dashboardOutcomeRow(outcome: outcome, index: index)

                            if index < event.outcomes.count - 1 {
                                ClipBetDivider()
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)

                    ClipBetDivider()

                    // Actions
                    VStack(spacing: 12) {
                        if event.status == .live {
                            // Close Bets
                            ClipBetSecondaryButton(title: "CLOSE BETS") {
                                showCloseConfirm = true
                            }

                            // Resolve
                            ClipBetPrimaryButton(title: "RESOLVE EVENT", icon: "checkmark.circle") {
                                showResolveSheet = true
                            }

                            // Cancel
                            Button {
                                showCancelConfirm = true
                            } label: {
                                Text("CANCEL & REFUND ALL")
                                    .font(.custom("DM Mono", size: 11))
                                    .kerning(1.4)
                                    .foregroundColor(ClipBetColors.no)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 2)
                                            .stroke(ClipBetColors.noFill, lineWidth: 1)
                                    )
                            }
                        } else if event.status == .betsClosed {
                            ClipBetPrimaryButton(title: "RESOLVE EVENT", icon: "checkmark.circle") {
                                showResolveSheet = true
                            }

                            Button {
                                showCancelConfirm = true
                            } label: {
                                Text("CANCEL & REFUND ALL")
                                    .font(.custom("DM Mono", size: 11))
                                    .kerning(1.4)
                                    .foregroundColor(ClipBetColors.no)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 2)
                                            .stroke(ClipBetColors.noFill, lineWidth: 1)
                                    )
                            }
                        } else if event.status == .resolved {
                            resolvedBanner
                        } else if event.status == .cancelled {
                            cancelledBanner
                        }

                        // Share QR
                        ClipBetSecondaryButton(title: "VIEW & SHARE QR") { }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 24)
                }
            }
            .scrollIndicators(.hidden)

            // Resolve sheet
            if showResolveSheet {
                resolveSheet
            }

            // Cancel confirmation
            if showCancelConfirm {
                cancelConfirmOverlay
            }

            // Close bets confirmation
            if showCloseConfirm {
                closeConfirmOverlay
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                appeared = true
            }
        }
    }

    // MARK: - Dashboard Outcome Row

    private func dashboardOutcomeRow(outcome: BetOutcome, index: Int) -> some View {
        let pct = event.percentage(for: outcome)
        let isFirst = index == 0
        let color = isFirst ? ClipBetColors.yes : ClipBetColors.no
        let isWinner = event.resolvedOutcomeId == outcome.id

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(outcome.name)
                    .font(.custom("DM Mono", size: 14))
                    .foregroundColor(ClipBetColors.textPrimary)

                if isWinner {
                    ClipBetTag(text: "WINNER", color: ClipBetColors.yes)
                }

                Spacer()

                Text(String(format: "%.0f%%", pct))
                    .font(.custom("Cormorant Garamond", size: 28))
                    .fontWeight(.light)
                    .foregroundColor(color)
            }

            // Animated progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(ClipBetColors.divider)
                        .frame(height: 4)

                    Rectangle()
                        .fill(color)
                        .frame(width: appeared ? geo.size.width * (pct / 100) : 0, height: 4)
                        .animation(.easeOut(duration: 0.8).delay(Double(index) * 0.15), value: appeared)
                }
            }
            .frame(height: 4)

            HStack {
                Text(outcome.formattedAmount)
                    .font(.custom("DM Mono", size: 11))
                    .foregroundColor(ClipBetColors.textSecondary)
                Spacer()
                Text("\(outcome.betCount) bets")
                    .font(.custom("DM Mono", size: 11))
                    .foregroundColor(ClipBetColors.textFaint)
            }
        }
        .padding(.vertical, 16)
    }

    // MARK: - Resolve Sheet

    private var resolveSheet: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
                .onTapGesture {
                    withAnimation { showResolveSheet = false }
                }

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Button {
                            withAnimation { showResolveSheet = false }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14))
                                .foregroundColor(ClipBetColors.textFaint)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                    Text("Resolve Event")
                        .font(.custom("Cormorant Garamond", size: 24))
                        .fontWeight(.light)
                        .foregroundColor(ClipBetColors.bg)
                        .padding(.top, 8)
                        .padding(.bottom, 4)

                    MonoLabel(text: "SELECT THE WINNING OUTCOME")
                        .padding(.bottom, 20)

                    ClipBetDarkDivider()

                    // Outcome selection
                    ForEach(event.outcomes) { outcome in
                        let isSelected = selectedWinner?.id == outcome.id
                        let isFirst = event.outcomes.first?.id == outcome.id
                        let pct = event.percentage(for: outcome)

                        Button {
                            selectedWinner = outcome
                        } label: {
                            HStack {
                                Circle()
                                    .fill(isSelected ? (isFirst ? ClipBetColors.yes : ClipBetColors.no) : ClipBetColors.textFaint)
                                    .frame(width: 10, height: 10)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(outcome.name)
                                        .font(.custom("DM Mono", size: 14))
                                        .foregroundColor(isSelected ? .white : ClipBetColors.textFaint)
                                    Text("\(outcome.betCount) bettors share \(String(format: "$%.0f", event.winnerPool))")
                                        .font(.custom("DM Mono", size: 10))
                                        .foregroundColor(ClipBetColors.textFaint)
                                }

                                Spacer()

                                Text(String(format: "%.0f%%", pct))
                                    .font(.custom("Cormorant Garamond", size: 22))
                                    .fontWeight(.light)
                                    .foregroundColor(isSelected ? (isFirst ? ClipBetColors.yes : ClipBetColors.no) : ClipBetColors.textFaint)
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                        }

                        ClipBetDarkDivider()
                    }

                    if let winner = selectedWinner {
                        // Payout breakdown
                        VStack(spacing: 4) {
                            Text("\(winner.betCount) winners share")
                                .font(.custom("DM Mono", size: 11))
                                .foregroundColor(ClipBetColors.textFaint)
                            Text(String(format: "$%.0f", event.winnerPool))
                                .font(.custom("Cormorant Garamond", size: 28))
                                .fontWeight(.light)
                                .foregroundColor(ClipBetColors.yes)
                        }
                        .padding(.vertical, 16)
                    }

                    // Confirm button
                    Button {
                        resolveEvent()
                    } label: {
                        Text("CONFIRM RESOLUTION")
                            .font(.custom("DM Mono", size: 13))
                            .kerning(2)
                            .foregroundColor(selectedWinner != nil ? ClipBetColors.dark : ClipBetColors.textFaint)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(selectedWinner != nil ? Color.white : Color.white.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 2))
                    }
                    .disabled(selectedWinner == nil)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)

                    Text("This cannot be undone")
                        .font(.custom("DM Mono", size: 10))
                        .foregroundColor(ClipBetColors.no)
                        .padding(.bottom, 24)
                }
                .background(ClipBetColors.dark)
                .clipShape(RoundedRectangle(cornerRadius: 2))
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }

    // MARK: - Cancel Confirm Overlay

    private var cancelConfirmOverlay: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
                .onTapGesture {
                    withAnimation { showCancelConfirm = false }
                }

            VStack(spacing: 20) {
                Text("Cancel Event?")
                    .font(.custom("Cormorant Garamond", size: 24))
                    .fontWeight(.light)
                    .foregroundColor(ClipBetColors.bg)

                Text("\(event.totalBettors) bettors will be fully refunded")
                    .font(.custom("DM Mono", size: 12))
                    .foregroundColor(ClipBetColors.textFaint)
                    .multilineTextAlignment(.center)

                VStack(spacing: 8) {
                    Button {
                        cancelEvent()
                    } label: {
                        Text("CANCEL & REFUND ALL")
                            .font(.custom("DM Mono", size: 13))
                            .kerning(1.6)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(ClipBetColors.no)
                            .clipShape(RoundedRectangle(cornerRadius: 2))
                    }

                    Button {
                        withAnimation { showCancelConfirm = false }
                    } label: {
                        Text("KEEP EVENT")
                            .font(.custom("DM Mono", size: 12))
                            .kerning(1.4)
                            .foregroundColor(ClipBetColors.textFaint)
                            .padding(.vertical, 12)
                    }
                }
            }
            .padding(28)
            .background(ClipBetColors.dark)
            .clipShape(RoundedRectangle(cornerRadius: 2))
            .padding(.horizontal, 32)
        }
    }

    // MARK: - Close Bets Confirm Overlay

    private var closeConfirmOverlay: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
                .onTapGesture {
                    withAnimation { showCloseConfirm = false }
                }

            VStack(spacing: 20) {
                Text("Close Bets?")
                    .font(.custom("Cormorant Garamond", size: 24))
                    .fontWeight(.light)
                    .foregroundColor(ClipBetColors.bg)

                Text("No new bets will be accepted. You can still resolve or cancel.")
                    .font(.custom("DM Mono", size: 12))
                    .foregroundColor(ClipBetColors.textFaint)
                    .multilineTextAlignment(.center)

                VStack(spacing: 8) {
                    Button {
                        closeBets()
                    } label: {
                        Text("CLOSE BETS")
                            .font(.custom("DM Mono", size: 13))
                            .kerning(1.6)
                            .foregroundColor(ClipBetColors.dark)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 2))
                    }

                    Button {
                        withAnimation { showCloseConfirm = false }
                    } label: {
                        Text("KEEP OPEN")
                            .font(.custom("DM Mono", size: 12))
                            .kerning(1.4)
                            .foregroundColor(ClipBetColors.textFaint)
                            .padding(.vertical, 12)
                    }
                }
            }
            .padding(28)
            .background(ClipBetColors.dark)
            .clipShape(RoundedRectangle(cornerRadius: 2))
            .padding(.horizontal, 32)
        }
    }

    // MARK: - Status Banners

    private var resolvedBanner: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(ClipBetColors.yes)
            Text("Event Resolved")
                .font(.custom("DM Mono", size: 12))
                .kerning(1.4)
                .foregroundColor(ClipBetColors.yes)
            Text("Winnings have been distributed")
                .font(.custom("DM Mono", size: 10))
                .foregroundColor(ClipBetColors.textFaint)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(ClipBetColors.yesFill)
        .clipShape(RoundedRectangle(cornerRadius: 2))
    }

    private var cancelledBanner: some View {
        VStack(spacing: 8) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(ClipBetColors.no)
            Text("Event Cancelled")
                .font(.custom("DM Mono", size: 12))
                .kerning(1.4)
                .foregroundColor(ClipBetColors.no)
            Text("All bettors have been refunded")
                .font(.custom("DM Mono", size: 10))
                .foregroundColor(ClipBetColors.textFaint)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(ClipBetColors.noFill)
        .clipShape(RoundedRectangle(cornerRadius: 2))
    }

    // MARK: - Actions

    private func resolveEvent() {
        guard let winner = selectedWinner else { return }
        event.resolvedOutcomeId = winner.id
        event.status = .resolved
        event.resolvedAt = Date()
        withAnimation { showResolveSheet = false }

        // In production: trigger Stripe Connect transfers
        paymentManager.distributeWinnings(
            event: event,
            winningOutcomeId: winner.id
        ) { _ in }
    }

    private func cancelEvent() {
        event.status = .cancelled
        withAnimation { showCancelConfirm = false }

        // In production: trigger Stripe refunds
        paymentManager.processRefund { _ in }
    }

    private func closeBets() {
        event.status = .betsClosed
        event.closedAt = Date()
        withAnimation { showCloseConfirm = false }
    }
}
