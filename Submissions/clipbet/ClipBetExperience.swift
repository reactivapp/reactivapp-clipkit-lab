//  ClipBetExperience.swift
//  ClipBet — Hyperlocal Prediction Markets via App Clips
//
//  Scan QR → See event → Place bet → Apple Pay → Done.
//  Editorial-minimal design: print magazine meets quiet SaaS.
//

import SwiftUI

struct ClipBetExperience: ClipExperience {
    static let urlPattern = "clipbet.io/event/:eventId"
    static let clipName = "ClipBet"
    static let clipDescription = "Scan. Predict. Win. Hyperlocal prediction markets — no app, no account."
    static let teamName = "ClipBet"

    static let touchpoint: JourneyTouchpoint = .onSite
    static let invocationSource: InvocationSource = .qrCode

    let context: ClipContext

    // MARK: - State

    enum Screen {
        case landing
        case placeBet
        case confirm
        case success
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
    @State private var isProcessing = false

    var body: some View {
        ZStack {
            // Editorial warm cream background
            ClipBetColors.bg.ignoresSafeArea()

            switch currentScreen {
            case .landing:
                landingScreen
                    .transition(.opacity)
            case .placeBet:
                placeBetScreen
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .confirm:
                confirmScreen
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .success:
                successScreen
                    .transition(.scale(scale: 0.95).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: currentScreen)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                appeared = true
            }
        }
    }

    // MARK: - Landing Screen (Specific Event QR)

    private var landingScreen: some View {
        ScrollView {
            VStack(spacing: 0) {

                // Logo + Status
                VStack(spacing: 16) {
                    // Brand
                    Text("ClipBet")
                        .font(.custom("Cormorant Garamond", size: 32))
                        .fontWeight(.light)
                        .foregroundColor(ClipBetColors.textPrimary)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 8)

                    // Status pill
                    StatusIndicator(status: event.status)
                }
                .padding(.top, 24)
                .padding(.bottom, 20)

                hairlineDivider

                // Event Question — the hero
                VStack(spacing: 12) {
                    Text(event.name)
                        .font(.custom("Cormorant Garamond", size: 28))
                        .fontWeight(.light)
                        .foregroundColor(ClipBetColors.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 12)

                    monoLabel(event.location)
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 28)

                hairlineDivider

                // Pool Stats (newspaper-style columns)
                HStack(spacing: 0) {
                    statColumn(value: event.formattedPool, label: "TOTAL POOL")

                    verticalDivider

                    statColumn(value: "\(event.totalBettors)", label: "BETTORS")

                    verticalDivider

                    statColumn(value: "5%", label: "PLATFORM FEE")
                }
                .padding(.vertical, 20)

                hairlineDivider

                // Outcomes with probability bars
                VStack(spacing: 0) {
                    ForEach(Array(event.outcomes.enumerated()), id: \.element.id) { index, outcome in
                        OutcomeRow(
                            outcome: outcome,
                            percentage: event.percentage(for: outcome),
                            isFirst: index == 0
                        )

                        if index < event.outcomes.count - 1 {
                            hairlineDivider
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)

                hairlineDivider

                // CTA Buttons
                VStack(spacing: 12) {
                    // Primary CTA
                    Button {
                        withAnimation { currentScreen = .placeBet }
                    } label: {
                        HStack {
                            Text("PLACE A BET")
                                .font(.custom("DM Mono", size: 13))
                                .kerning(2.4)
                                .foregroundColor(ClipBetColors.bg)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(ClipBetColors.dark)
                        .clipShape(RoundedRectangle(cornerRadius: 2))
                    }

                    // Secondary actions
                    HStack(spacing: 12) {
                        secondaryButton("BROWSE NEARBY") { }
                        secondaryButton("CREATE EVENT") { }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)

                // Organizer credit
                monoLabel("organized by \(event.organizer)")
                    .padding(.bottom, 24)
            }
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Place Bet Screen

    private var placeBetScreen: some View {
        ScrollView {
            VStack(spacing: 0) {

                // Back + Title
                HStack {
                    Button {
                        withAnimation { currentScreen = .landing }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 12))
                            Text("BACK")
                                .font(.custom("DM Mono", size: 11))
                                .kerning(1.6)
                        }
                        .foregroundColor(ClipBetColors.textSecondary)
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

                monoLabel(event.name)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 24)

                hairlineDivider

                // Email input
                VStack(alignment: .leading, spacing: 8) {
                    monoLabelLeft("EMAIL")

                    TextField("your@email.com", text: $email)
                        .font(.custom("DM Mono", size: 14))
                        .foregroundColor(ClipBetColors.textPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(ClipBetColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 2))
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)

                hairlineDivider

                // Nickname (optional)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        monoLabelLeft("NICKNAME")
                        Spacer()
                        Text("optional")
                            .font(.custom("DM Mono", size: 10))
                            .foregroundColor(ClipBetColors.textFaint)
                    }

                    TextField("Anonymous", text: $nickname)
                        .font(.custom("DM Mono", size: 14))
                        .foregroundColor(ClipBetColors.textPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(ClipBetColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 2))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)

                hairlineDivider

                // Select Outcome
                VStack(alignment: .leading, spacing: 12) {
                    monoLabelLeft("SELECT OUTCOME")
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
                                // Dot indicator
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

                hairlineDivider

                // Bet Amount
                VStack(alignment: .leading, spacing: 12) {
                    monoLabelLeft("BET AMOUNT")
                        .padding(.horizontal, 24)

                    HStack(spacing: 8) {
                        ForEach([5.0, 10.0, 25.0], id: \.self) { amount in
                            amountButton(amount)
                        }
                        // Custom
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

                hairlineDivider

                // Estimated Return
                if let outcome = selectedOutcome, betAmount > 0 {
                    let est = event.estimatedReturn(betAmount: betAmount, for: outcome)
                    VStack(spacing: 4) {
                        monoLabel("ESTIMATED RETURN")
                        Text(String(format: "$%.2f", est))
                            .font(.custom("Cormorant Garamond", size: 36))
                            .fontWeight(.light)
                            .foregroundColor(ClipBetColors.yes)
                    }
                    .padding(.vertical, 20)

                    hairlineDivider
                }

                // Confirm button
                Button {
                    withAnimation { currentScreen = .confirm }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 16))
                        Text("REVIEW & PAY")
                            .font(.custom("DM Mono", size: 13))
                            .kerning(2.4)
                    }
                    .foregroundColor(ClipBetColors.bg)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        (selectedOutcome != nil && betAmount >= event.minimumBet && !email.isEmpty)
                        ? ClipBetColors.dark
                        : ClipBetColors.textFaint
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 2))
                }
                .disabled(selectedOutcome == nil || betAmount < event.minimumBet || email.isEmpty)
                .padding(.horizontal, 24)
                .padding(.vertical, 24)

                monoLabel("min bet: $\(Int(event.minimumBet))")
                    .padding(.bottom, 24)
            }
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Confirm Screen

    private var confirmScreen: some View {
        VStack(spacing: 0) {
            Spacer()

            // Dark modal overlay style
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

                // Details rows
                VStack(spacing: 0) {
                    confirmRow(label: "EVENT", value: event.name, isMultiline: true)
                    confirmDivider
                    confirmRow(label: "PREDICTION", value: selectedOutcome?.name ?? "—")
                    confirmDivider
                    confirmRow(label: "AMOUNT", value: String(format: "$%.0f", betAmount))
                    confirmDivider
                    if let outcome = selectedOutcome {
                        let est = event.estimatedReturn(betAmount: betAmount, for: outcome)
                        confirmRow(label: "EST. RETURN", value: String(format: "$%.2f", est), valueColor: ClipBetColors.yes)
                        confirmDivider
                    }
                    confirmRow(label: "AS", value: nickname.isEmpty ? "Anonymous" : nickname)
                    confirmDivider
                    confirmRow(label: "CONTACT", value: email)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)

                Spacer()

                // Apple Pay button
                Button {
                    processPayment()
                } label: {
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
                .disabled(isProcessing)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .background(ClipBetColors.dark)
            .clipShape(RoundedRectangle(cornerRadius: 2))
        }
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Success Screen

    private var successScreen: some View {
        @State var successAppeared = false

        return ScrollView {
            VStack(spacing: 0) {
                VStack(spacing: 16) {
                    // Checkmark
                    Image(systemName: "checkmark")
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(ClipBetColors.yes)
                        .padding(.top, 40)

                    Text("You're In")
                        .font(.custom("Cormorant Garamond", size: 36))
                        .fontWeight(.light)
                        .foregroundColor(ClipBetColors.textPrimary)

                    monoLabel("Bet placed successfully")
                }
                .padding(.bottom, 28)

                hairlineDivider

                // Bet receipt
                VStack(spacing: 0) {
                    receiptRow(label: "EVENT", value: event.name)
                    receiptRow(label: "YOUR PICK", value: selectedOutcome?.name ?? "—")
                    receiptRow(label: "AMOUNT", value: String(format: "$%.0f", betAmount))
                    if let outcome = selectedOutcome {
                        let est = event.estimatedReturn(betAmount: betAmount, for: outcome)
                        receiptRow(label: "EST. RETURN", value: String(format: "$%.2f", est))
                    }
                    receiptRow(label: "NICKNAME", value: nickname.isEmpty ? "Anonymous" : nickname)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)

                hairlineDivider

                // Updated pool standings
                VStack(spacing: 16) {
                    monoLabel("CURRENT STANDINGS")
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
                                    Text("YOUR PICK")
                                        .font(.custom("DM Mono", size: 9))
                                        .kerning(1.2)
                                        .foregroundColor(ClipBetColors.accent)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 2)
                                                .stroke(ClipBetColors.accent, lineWidth: 1)
                                        )
                                }

                                Spacer()

                                Text(String(format: "%.0f%%", pct))
                                    .font(.custom("Cormorant Garamond", size: 24))
                                    .fontWeight(.light)
                                    .foregroundColor(isYes ? ClipBetColors.yes : ClipBetColors.no)
                            }

                            // Progress bar
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

                hairlineDivider

                // Push notifications opt-in
                VStack(spacing: 12) {
                    monoLabel("GET NOTIFIED WHEN RESULTS ARE IN")

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
            }
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Payment Processing (Mock)

    private func processPayment() {
        isProcessing = true
        // Simulate Apple Pay + Stripe processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Update the pool with user's bet
            if let outcomeIndex = event.outcomes.firstIndex(where: { $0.id == selectedOutcome?.id }) {
                event.outcomes[outcomeIndex].totalAmount += betAmount
                event.outcomes[outcomeIndex].betCount += 1
            }
            isProcessing = false
            withAnimation { currentScreen = .success }
        }
    }

    // MARK: - Shared Components

    private var hairlineDivider: some View {
        Rectangle()
            .fill(ClipBetColors.divider)
            .frame(height: 1)
    }

    private var verticalDivider: some View {
        Rectangle()
            .fill(ClipBetColors.divider)
            .frame(width: 1, height: 40)
    }

    private func monoLabel(_ text: String) -> some View {
        Text(text)
            .font(.custom("DM Mono", size: 11))
            .kerning(1.8)
            .foregroundColor(ClipBetColors.textSecondary)
            .textCase(.uppercase)
            .multilineTextAlignment(.center)
    }

    private func monoLabelLeft(_ text: String) -> some View {
        Text(text)
            .font(.custom("DM Mono", size: 10))
            .kerning(2)
            .foregroundColor(ClipBetColors.textSecondary)
            .textCase(.uppercase)
    }

    private func statColumn(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.custom("Cormorant Garamond", size: 26))
                .fontWeight(.light)
                .foregroundColor(ClipBetColors.textPrimary)

            Text(label)
                .font(.custom("DM Mono", size: 9))
                .kerning(1.6)
                .foregroundColor(ClipBetColors.textSecondary)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
    }

    private func secondaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.custom("DM Mono", size: 11))
                .kerning(1.4)
                .foregroundColor(ClipBetColors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(ClipBetColors.divider, lineWidth: 1)
                )
        }
    }

    private func amountButton(_ amount: Double) -> some View {
        let isSelected = !showCustomAmount && betAmount == amount
        return Button {
            showCustomAmount = false
            customAmount = ""
            betAmount = amount
        } label: {
            Text("$\(Int(amount))")
                .font(.custom("DM Mono", size: 14))
                .foregroundColor(isSelected ? ClipBetColors.bg : ClipBetColors.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(isSelected ? ClipBetColors.dark : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(isSelected ? Color.clear : ClipBetColors.divider, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 2))
        }
    }

    // Confirm screen helpers

    private var confirmDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(height: 1)
    }

    private func confirmRow(label: String, value: String, isMultiline: Bool = false, valueColor: Color = .white) -> some View {
        HStack(alignment: isMultiline ? .top : .center) {
            Text(label)
                .font(.custom("DM Mono", size: 10))
                .kerning(1.6)
                .foregroundColor(ClipBetColors.textFaint)
                .frame(width: 90, alignment: .leading)

            Text(value)
                .font(.custom("DM Mono", size: 13))
                .foregroundColor(valueColor)
                .lineLimit(isMultiline ? 3 : 1)

            Spacer()
        }
        .padding(.vertical, 10)
    }

    // Receipt row helper
    private func receiptRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.custom("DM Mono", size: 10))
                .kerning(1.6)
                .foregroundColor(ClipBetColors.textSecondary)
                .frame(width: 90, alignment: .leading)

            Text(value)
                .font(.custom("DM Mono", size: 13))
                .foregroundColor(ClipBetColors.textPrimary)
                .lineLimit(2)

            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Status Indicator Component

struct StatusIndicator: View {
    let status: EventStatus
    @State private var pulsing = false

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(status.dotColor)
                .frame(width: 6, height: 6)
                .opacity(pulsing ? 0.4 : 1.0)

            Text(status.rawValue)
                .font(.custom("DM Mono", size: 11))
                .kerning(2)
                .foregroundColor(ClipBetColors.textSecondary)
                .textCase(.uppercase)
        }
        .onAppear {
            if status.isPulsing {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    pulsing = true
                }
            }
        }
    }
}

// MARK: - Outcome Row Component

struct OutcomeRow: View {
    let outcome: BetOutcome
    let percentage: Double
    let isFirst: Bool

    private var color: Color {
        isFirst ? ClipBetColors.yes : ClipBetColors.no
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(outcome.name)
                    .font(.custom("DM Mono", size: 14))
                    .foregroundColor(ClipBetColors.textPrimary)

                Spacer()

                Text(String(format: "%.0f%%", percentage))
                    .font(.custom("Cormorant Garamond", size: 28))
                    .fontWeight(.light)
                    .foregroundColor(color)
            }

            // 3px progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(ClipBetColors.divider)
                        .frame(height: 3)

                    Rectangle()
                        .fill(color)
                        .frame(width: geo.size.width * (percentage / 100), height: 3)
                }
            }
            .frame(height: 3)

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
}
