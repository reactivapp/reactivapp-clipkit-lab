//  ClipBetExperience.swift
//  ClipBet
//
//  Main App Clip experience. Entry point for the ClipBet prediction market.
//  Flow: Landing -> Place Bet -> Confirm (Apple Pay) -> Success
//
//  Scan QR at a venue. See the event. Place your bet. Done.
//

import SwiftUI

struct ClipBetExperience: ClipExperience {
    static let urlPattern = "clipbet.io/event/:eventId"
    static let clipName = "ClipBet"
    static let clipDescription = "Scan. Predict. Win. Hyperlocal prediction markets, no app, no account."
    static let teamName = "ClipBet"

    static let touchpoint: JourneyTouchpoint = .onSite
    static let invocationSource: InvocationSource = .qrCode

    let context: ClipContext

    // MARK: - Screen Flow

    enum Screen {
        case landing
        case placeBet
        case confirm
        case success
        case createEvent
        case dashboard
    }

    @State private var currentScreen: Screen = .landing
    @State private var event: PredictionEvent = ClipBetMockData.primaryEvent
    @State private var selectedOutcome: BetOutcome?
    @State private var betAmount: Double = 10
    @State private var nickname: String = ""
    @State private var email: String = ""
    @State private var customAmount: String = ""
    @State private var showCustomAmount = false
    @State private var appeared = false
    @State private var paymentManager = ClipBetPaymentManager()

    var body: some View {
        ZStack {
            ClipBetColors.bg.ignoresSafeArea()

            switch currentScreen {
            case .landing:
                landingView
                    .transition(.opacity)
            case .placeBet:
                placeBetView
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .confirm:
                confirmView
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .success:
                successView
                    .transition(.scale(scale: 0.95).combined(with: .opacity))
            case .createEvent:
                CreateEventFlow()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .dashboard:
                OrganizerDashboard()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: currentScreen)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                appeared = true
            }
        }
    }

    // MARK: - Landing View

    private var landingView: some View {
        ScrollView {
            VStack(spacing: 0) {

                // Brand + Status
                VStack(spacing: 16) {
                    Text("ClipBet")
                        .font(.custom("Cormorant Garamond", size: 32))
                        .fontWeight(.light)
                        .foregroundColor(ClipBetColors.textPrimary)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 8)

                    StatusIndicator(status: event.status)
                }
                .padding(.top, 24)
                .padding(.bottom, 20)

                ClipBetDivider()

                // Event question
                VStack(spacing: 12) {
                    Text(event.name)
                        .font(.custom("Cormorant Garamond", size: 28))
                        .fontWeight(.light)
                        .foregroundColor(ClipBetColors.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 12)

                    MonoLabel(text: event.location)
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 28)

                ClipBetDivider()

                // Pool stats
                HStack(spacing: 0) {
                    StatColumn(value: event.formattedPool, label: "TOTAL POOL")
                    ClipBetVerticalDivider()
                    StatColumn(value: "\(event.totalBettors)", label: "BETTORS")
                    ClipBetVerticalDivider()
                    StatColumn(value: "5%", label: "PLATFORM FEE")
                }
                .padding(.vertical, 20)

                ClipBetDivider()

                // Outcomes
                VStack(spacing: 0) {
                    ForEach(Array(event.outcomes.enumerated()), id: \.element.id) { index, outcome in
                        OutcomeRow(
                            outcome: outcome,
                            percentage: event.percentage(for: outcome),
                            isFirst: index == 0
                        )
                        if index < event.outcomes.count - 1 {
                            ClipBetDivider()
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)

                ClipBetDivider()

                // CTA
                VStack(spacing: 12) {
                    ClipBetPrimaryButton(title: "PLACE A BET") {
                        withAnimation { currentScreen = .placeBet }
                    }

                    ClipBetSecondaryButton(title: "CREATE YOUR OWN EVENT") {
                        withAnimation { currentScreen = .createEvent }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)

                // Organizer
                MonoLabel(text: "organized by \(event.organizer)")
                    .padding(.bottom, 8)

                MonoLabel(text: event.timeSinceCreated + " ago")
                    .padding(.bottom, 24)
            }
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Place Bet View

    private var placeBetView: some View {
        ScrollView {
            VStack(spacing: 0) {

                // Header
                HStack {
                    ClipBetBackButton {
                        withAnimation { currentScreen = .landing }
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                Text("Place Your Bet")
                    .font(.custom("Cormorant Garamond", size: 28))
                    .fontWeight(.light)
                    .foregroundColor(ClipBetColors.textPrimary)
                    .padding(.top, 20)
                    .padding(.bottom, 8)

                MonoLabel(text: event.name)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 24)

                ClipBetDivider()

                // Email
                VStack(alignment: .leading, spacing: 8) {
                    MonoLabelLeft(text: "EMAIL")
                    ClipBetTextField(
                        placeholder: "your@email.com",
                        text: $email,
                        keyboardType: .emailAddress
                    )
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)

                ClipBetDivider()

                // Nickname
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        MonoLabelLeft(text: "NICKNAME")
                        Spacer()
                        Text("optional")
                            .font(.custom("DM Mono", size: 10))
                            .foregroundColor(ClipBetColors.textFaint)
                    }
                    ClipBetTextField(
                        placeholder: "Anonymous",
                        text: $nickname
                    )
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)

                ClipBetDivider()

                // Outcome selection
                VStack(alignment: .leading, spacing: 12) {
                    MonoLabelLeft(text: "SELECT OUTCOME")
                        .padding(.horizontal, 24)

                    ForEach(event.outcomes) { outcome in
                        let isSelected = selectedOutcome?.id == outcome.id
                        let isYes = event.outcomes.first?.id == outcome.id

                        Button {
                            withAnimation(.easeOut(duration: 0.2)) {
                                selectedOutcome = outcome
                            }
                        } label: {
                            HStack {
                                Circle()
                                    .fill(isSelected
                                          ? (isYes ? ClipBetColors.yes : ClipBetColors.no)
                                          : ClipBetColors.divider)
                                    .frame(width: 8, height: 8)

                                Text(outcome.name)
                                    .font(.custom("DM Mono", size: 14))
                                    .foregroundColor(isSelected ? ClipBetColors.textPrimary : ClipBetColors.textSecondary)

                                Spacer()

                                Text(String(format: "%.0f%%", event.percentage(for: outcome)))
                                    .font(.custom("Cormorant Garamond", size: 22))
                                    .fontWeight(.light)
                                    .foregroundColor(isSelected
                                                     ? (isYes ? ClipBetColors.yes : ClipBetColors.no)
                                                     : ClipBetColors.textFaint)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(isSelected
                                        ? (isYes ? ClipBetColors.yesFill : ClipBetColors.noFill)
                                        : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 2))
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 20)

                ClipBetDivider()

                // Bet amount
                VStack(alignment: .leading, spacing: 12) {
                    MonoLabelLeft(text: "BET AMOUNT")
                        .padding(.horizontal, 24)

                    HStack(spacing: 8) {
                        ForEach([5.0, 10.0, 25.0], id: \.self) { amount in
                            AmountButton(
                                amount: amount,
                                isSelected: !showCustomAmount && betAmount == amount
                            ) {
                                showCustomAmount = false
                                customAmount = ""
                                betAmount = amount
                            }
                        }

                        Button {
                            showCustomAmount = true
                            betAmount = 0
                        } label: {
                            Text("CUSTOM")
                                .font(.custom("DM Mono", size: 12))
                                .kerning(1)
                                .foregroundColor(showCustomAmount ? ClipBetColors.bg : ClipBetColors.textSecondary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(showCustomAmount ? ClipBetColors.dark : Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 2)
                                        .stroke(ClipBetColors.divider, lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 2))
                        }
                    }
                    .padding(.horizontal, 24)

                    if showCustomAmount {
                        HStack {
                            Text("$")
                                .font(.custom("Cormorant Garamond", size: 24))
                                .fontWeight(.light)
                                .foregroundColor(ClipBetColors.textPrimary)
                            TextField("0", text: $customAmount)
                                .font(.custom("Cormorant Garamond", size: 24))
                                .fontWeight(.light)
                                .foregroundColor(ClipBetColors.textPrimary)
                                .keyboardType(.numberPad)
                                .onChange(of: customAmount) { _, newValue in
                                    betAmount = Double(newValue) ?? 0
                                }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(ClipBetColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 2))
                        .padding(.horizontal, 24)
                    }
                }
                .padding(.vertical, 20)

                ClipBetDivider()

                // Estimated return
                if let outcome = selectedOutcome, betAmount > 0 {
                    let est = event.estimatedReturn(betAmount: betAmount, for: outcome)
                    VStack(spacing: 4) {
                        MonoLabel(text: "ESTIMATED RETURN")
                        Text(String(format: "$%.2f", est))
                            .font(.custom("Cormorant Garamond", size: 36))
                            .fontWeight(.light)
                            .foregroundColor(ClipBetColors.yes)
                    }
                    .padding(.vertical, 20)

                    ClipBetDivider()
                }

                // Review button
                let canProceed = selectedOutcome != nil && betAmount >= event.minimumBet && !email.isEmpty
                ClipBetPrimaryButton(
                    title: "REVIEW & PAY",
                    icon: "apple.logo",
                    isEnabled: canProceed
                ) {
                    withAnimation { currentScreen = .confirm }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)

                MonoLabel(text: "min bet: $\(Int(event.minimumBet))")
                    .padding(.bottom, 24)
            }
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Confirm View (Dark Modal)

    private var confirmView: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button {
                        withAnimation { currentScreen = .placeBet }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 12))
                            Text("BACK")
                                .font(.custom("DM Mono", size: 11))
                                .kerning(1.6)
                        }
                        .foregroundColor(ClipBetColors.textFaint)
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)

                Text("Confirm Bet")
                    .font(.custom("Cormorant Garamond", size: 28))
                    .fontWeight(.light)
                    .foregroundColor(ClipBetColors.bg)
                    .padding(.top, 16)
                    .padding(.bottom, 24)

                // Bet details
                VStack(spacing: 0) {
                    ConfirmRow(label: "EVENT", value: event.name, isMultiline: true)
                    ClipBetDarkDivider()
                    ConfirmRow(label: "PREDICTION", value: selectedOutcome?.name ?? "")
                    ClipBetDarkDivider()
                    ConfirmRow(label: "AMOUNT", value: String(format: "$%.0f", betAmount))
                    ClipBetDarkDivider()
                    if let outcome = selectedOutcome {
                        let est = event.estimatedReturn(betAmount: betAmount, for: outcome)
                        ConfirmRow(label: "EST. RETURN", value: String(format: "$%.2f", est), valueColor: ClipBetColors.yes)
                        ClipBetDarkDivider()
                    }
                    ConfirmRow(label: "AS", value: nickname.isEmpty ? "Anonymous" : nickname)
                    ClipBetDarkDivider()
                    ConfirmRow(label: "CONTACT", value: email)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)

                // Payment status
                ClipBetPaymentStatus(state: paymentManager.paymentState)
                    .padding(.horizontal, 24)

                Spacer()

                // Apple Pay button + card fallback
                ClipBetApplePayButton(
                    amount: betAmount,
                    isEnabled: paymentManager.paymentState != .processing,
                    isProcessing: paymentManager.paymentState == .processing,
                    onTap: { processApplePayment() },
                    onCardFallback: { processCardPayment() }
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .background(ClipBetColors.dark)
            .clipShape(RoundedRectangle(cornerRadius: 2))
        }
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Success View

    private var successView: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(ClipBetColors.yes)
                        .padding(.top, 40)

                    Text("You're In")
                        .font(.custom("Cormorant Garamond", size: 36))
                        .fontWeight(.light)
                        .foregroundColor(ClipBetColors.textPrimary)

                    MonoLabel(text: "Bet placed successfully")
                }
                .padding(.bottom, 28)

                ClipBetDivider()

                // Receipt
                VStack(spacing: 0) {
                    ReceiptRow(label: "EVENT", value: event.name)
                    ReceiptRow(label: "YOUR PICK", value: selectedOutcome?.name ?? "")
                    ReceiptRow(label: "AMOUNT", value: String(format: "$%.0f", betAmount))
                    if let outcome = selectedOutcome {
                        let est = event.estimatedReturn(betAmount: betAmount, for: outcome)
                        ReceiptRow(label: "EST. RETURN", value: String(format: "$%.2f", est))
                    }
                    ReceiptRow(label: "NICKNAME", value: nickname.isEmpty ? "Anonymous" : nickname)
                    if case .success(let txId) = paymentManager.paymentState {
                        ReceiptRow(label: "TRANSACTION", value: txId)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)

                ClipBetDivider()

                // Pool standings
                VStack(spacing: 16) {
                    MonoLabel(text: "CURRENT STANDINGS")
                        .padding(.top, 20)

                    ForEach(event.outcomes) { outcome in
                        let pct = event.percentage(for: outcome)
                        let isYes = event.outcomes.first?.id == outcome.id
                        let isYours = outcome.id == selectedOutcome?.id

                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(outcome.name)
                                    .font(.custom("DM Mono", size: 13))
                                    .foregroundColor(ClipBetColors.textPrimary)

                                if isYours {
                                    ClipBetTag(text: "YOUR PICK")
                                }

                                Spacer()

                                Text(String(format: "%.0f%%", pct))
                                    .font(.custom("Cormorant Garamond", size: 24))
                                    .fontWeight(.light)
                                    .foregroundColor(isYes ? ClipBetColors.yes : ClipBetColors.no)
                            }

                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(ClipBetColors.divider)
                                        .frame(height: 3)
                                    Rectangle()
                                        .fill(isYes ? ClipBetColors.yes : ClipBetColors.no)
                                        .frame(width: geo.size.width * (pct / 100), height: 3)
                                }
                            }
                            .frame(height: 3)
                        }
                        .padding(.horizontal, 24)
                    }
                }
                .padding(.bottom, 24)

                ClipBetDivider()

                // Notification opt-in
                VStack(spacing: 12) {
                    MonoLabel(text: "GET NOTIFIED WHEN RESULTS ARE IN")

                    Button { } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "bell")
                                .font(.system(size: 14))
                            Text("ENABLE NOTIFICATIONS")
                                .font(.custom("DM Mono", size: 12))
                                .kerning(1.6)
                        }
                        .foregroundColor(ClipBetColors.textPrimary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(ClipBetColors.divider, lineWidth: 1)
                        )
                    }
                }
                .padding(.vertical, 24)

                // Escrow info
                VStack(spacing: 4) {
                    MonoLabel(text: "FUNDS HELD IN ESCROW")
                    Text("Organizer has 24h to resolve. If unresolved, you get a full refund.")
                        .font(.custom("DM Mono", size: 10))
                        .foregroundColor(ClipBetColors.textFaint)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.bottom, 32)
            }
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Payment Actions

    private func processApplePayment() {
        paymentManager.selectedMethod = .applePay
        paymentManager.processBet(
            amount: betAmount,
            eventId: event.id,
            outcomeId: selectedOutcome?.id ?? UUID(),
            email: email,
            nickname: nickname.isEmpty ? "Anonymous" : nickname
        ) { success in
            if success {
                // Update pool with user bet
                if let idx = event.outcomes.firstIndex(where: { $0.id == selectedOutcome?.id }) {
                    event.outcomes[idx].totalAmount += betAmount
                    event.outcomes[idx].betCount += 1
                }
                withAnimation { currentScreen = .success }
            }
            // On failure, payment status view shows error, user can retry
        }
    }

    private func processCardPayment() {
        paymentManager.selectedMethod = .card
        paymentManager.processBet(
            amount: betAmount,
            eventId: event.id,
            outcomeId: selectedOutcome?.id ?? UUID(),
            email: email,
            nickname: nickname.isEmpty ? "Anonymous" : nickname
        ) { success in
            if success {
                if let idx = event.outcomes.firstIndex(where: { $0.id == selectedOutcome?.id }) {
                    event.outcomes[idx].totalAmount += betAmount
                    event.outcomes[idx].betCount += 1
                }
                withAnimation { currentScreen = .success }
            }
        }
    }
}
