//  ClipBetCreateEvent.swift
//  ClipBet
//
//  Create Event flow for organizers.
//  Sign in with Apple -> (first time: TOS + Stripe Connect) -> Form -> Preview -> QR
//

import SwiftUI

// MARK: - Create Event Flow

struct CreateEventFlow: View {
    enum Step {
        case signIn
        case tos
        case form
        case preview
        case qrCode
    }

    @State private var step: Step = .signIn
    @State private var isReturning = false
    @State private var appeared = false

    // Form state
    @State private var eventName = ""
    @State private var outcomes: [String] = ["", ""]
    @State private var minimumBet: Double = 5
    @State private var bettingWindow: BettingWindow = .manual
    @State private var locationName = "Detecting location..."
    @State private var tosAccepted = false
    @State private var isSignedIn = false
    @State private var generatedEventId = UUID()

    var body: some View {
        ZStack {
            ClipBetColors.bg.ignoresSafeArea()

            switch step {
            case .signIn:
                signInView
                    .transition(.opacity)
            case .tos:
                tosView
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .form:
                formView
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .preview:
                previewView
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .qrCode:
                qrCodeView
                    .transition(.scale(scale: 0.95).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: step)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                appeared = true
            }
            // Simulate location detection
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                locationName = "Scotiabank Arena, Toronto"
            }
        }
    }

    // MARK: - Sign In View

    private var signInView: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                Text("ClipBet")
                    .font(.custom("Cormorant Garamond", size: 36))
                    .fontWeight(.light)
                    .foregroundColor(ClipBetColors.textPrimary)
                    .opacity(appeared ? 1 : 0)

                Text("Create a Prediction Market")
                    .font(.custom("Cormorant Garamond", size: 24))
                    .fontWeight(.light)
                    .foregroundColor(ClipBetColors.textSecondary)

                MonoLabel(text: "ORGANIZERS MUST SIGN IN")
            }

            Spacer()

            VStack(spacing: 16) {
                // Sign in with Apple button
                Button {
                    simulateSignIn()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 18))
                        Text("SIGN IN WITH APPLE")
                            .font(.custom("DM Mono", size: 13))
                            .kerning(2)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
                }

                Text("Required to create and manage events")
                    .font(.custom("DM Mono", size: 10))
                    .foregroundColor(ClipBetColors.textFaint)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Terms of Service View

    private var tosView: some View {
        ScrollView {
            VStack(spacing: 0) {
                HStack {
                    ClipBetBackButton { withAnimation { step = .signIn } }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                Text("Terms of Service")
                    .font(.custom("Cormorant Garamond", size: 28))
                    .fontWeight(.light)
                    .foregroundColor(ClipBetColors.textPrimary)
                    .padding(.top, 20)
                    .padding(.bottom, 24)

                ClipBetDivider()

                VStack(alignment: .leading, spacing: 16) {
                    tosSection("Platform Fee", "ClipBet charges a 5% platform fee on all prediction market pools. This fee is deducted before winnings are distributed.")
                    tosSection("Resolution", "As an organizer, you must resolve events within 24 hours. Failure to resolve results in automatic refunds to all bettors.")
                    tosSection("Cancellation", "You may cancel an event at any time before resolution. All bettors will receive full refunds.")
                    tosSection("Payouts", "Payouts are processed via Stripe Connect. You must complete Stripe onboarding to receive your organizer share.")
                    tosSection("Disputes", "Bettors may dispute your resolution. ClipBet reserves the right to reverse outcomes and issue refunds.")
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)

                ClipBetDivider()

                VStack(spacing: 16) {
                    Button {
                        tosAccepted = true
                        withAnimation { step = .form }
                    } label: {
                        Text("I AGREE TO THE TERMS")
                            .font(.custom("DM Mono", size: 13))
                            .kerning(2.4)
                            .foregroundColor(ClipBetColors.bg)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(ClipBetColors.dark)
                            .clipShape(RoundedRectangle(cornerRadius: 2))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
            }
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Event Form View

    private var formView: some View {
        ScrollView {
            VStack(spacing: 0) {
                HStack {
                    ClipBetBackButton {
                        withAnimation { step = isReturning ? .signIn : .tos }
                    }
                    Spacer()
                    MonoLabel(text: "NEW EVENT")
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                Text("Create Event")
                    .font(.custom("Cormorant Garamond", size: 28))
                    .fontWeight(.light)
                    .foregroundColor(ClipBetColors.textPrimary)
                    .padding(.top, 20)
                    .padding(.bottom, 24)

                ClipBetDivider()

                // Event Name
                VStack(alignment: .leading, spacing: 8) {
                    MonoLabelLeft(text: "EVENT NAME")
                    ClipBetTextField(
                        placeholder: "Will the Raptors win tonight?",
                        text: $eventName,
                        autocapitalization: .sentences
                    )
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)

                ClipBetDivider()

                // Outcomes
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        MonoLabelLeft(text: "OUTCOMES")
                        Spacer()
                        MonoLabel(text: "\(outcomes.count) of 6")
                    }

                    ForEach(outcomes.indices, id: \.self) { index in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(index == 0 ? ClipBetColors.yes : ClipBetColors.no)
                                .frame(width: 6, height: 6)

                            TextField("Option \(index + 1)", text: $outcomes[index])
                                .font(.custom("DM Mono", size: 14))
                                .foregroundColor(ClipBetColors.textPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 12)
                                .background(ClipBetColors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 2))

                            if outcomes.count > 2 {
                                Button {
                                    outcomes.remove(at: index)
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(ClipBetColors.textFaint)
                                        .frame(width: 28, height: 28)
                                }
                            }
                        }
                    }

                    if outcomes.count < 6 {
                        Button {
                            outcomes.append("")
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "plus")
                                    .font(.system(size: 11))
                                Text("ADD OUTCOME")
                                    .font(.custom("DM Mono", size: 11))
                                    .kerning(1.4)
                            }
                            .foregroundColor(ClipBetColors.textSecondary)
                            .padding(.vertical, 10)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)

                ClipBetDivider()

                // Minimum Bet
                VStack(alignment: .leading, spacing: 12) {
                    MonoLabelLeft(text: "MINIMUM BET")

                    HStack(spacing: 8) {
                        ForEach([1.0, 5.0, 10.0], id: \.self) { amount in
                            AmountButton(
                                amount: amount,
                                isSelected: minimumBet == amount
                            ) {
                                minimumBet = amount
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)

                ClipBetDivider()

                // Betting Window
                VStack(alignment: .leading, spacing: 12) {
                    MonoLabelLeft(text: "BETTING WINDOW")

                    ForEach([BettingWindow.manual, .atStart, .stayOpen], id: \.rawValue) { window in
                        Button {
                            bettingWindow = window
                        } label: {
                            HStack {
                                Circle()
                                    .fill(bettingWindow == window ? ClipBetColors.dark : ClipBetColors.divider)
                                    .frame(width: 8, height: 8)
                                Text(window.rawValue)
                                    .font(.custom("DM Mono", size: 13))
                                    .foregroundColor(bettingWindow == window ? ClipBetColors.textPrimary : ClipBetColors.textSecondary)
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)

                ClipBetDivider()

                // Location
                VStack(alignment: .leading, spacing: 8) {
                    MonoLabelLeft(text: "LOCATION")

                    HStack {
                        Image(systemName: "location.fill")
                            .font(.system(size: 12))
                            .foregroundColor(ClipBetColors.yes)
                        Text(locationName)
                            .font(.custom("DM Mono", size: 13))
                            .foregroundColor(ClipBetColors.textPrimary)
                        Spacer()
                        Text("auto")
                            .font(.custom("DM Mono", size: 10))
                            .foregroundColor(ClipBetColors.textFaint)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(ClipBetColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)

                ClipBetDivider()

                // Preview button
                ClipBetPrimaryButton(
                    title: "PREVIEW EVENT",
                    isEnabled: isFormValid
                ) {
                    withAnimation { step = .preview }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
            }
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Preview View

    private var previewView: some View {
        ScrollView {
            VStack(spacing: 0) {
                HStack {
                    ClipBetBackButton { withAnimation { step = .form } }
                    Spacer()
                    MonoLabel(text: "PREVIEW")
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                Text("Event Preview")
                    .font(.custom("Cormorant Garamond", size: 28))
                    .fontWeight(.light)
                    .foregroundColor(ClipBetColors.textPrimary)
                    .padding(.top, 20)
                    .padding(.bottom, 24)

                ClipBetDivider()

                // Preview card
                VStack(spacing: 16) {
                    StatusIndicator(status: .live)

                    Text(eventName)
                        .font(.custom("Cormorant Garamond", size: 24))
                        .fontWeight(.light)
                        .foregroundColor(ClipBetColors.textPrimary)
                        .multilineTextAlignment(.center)

                    MonoLabel(text: locationName)
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 28)

                ClipBetDivider()

                // Outcomes preview
                VStack(spacing: 0) {
                    ForEach(validOutcomes.indices, id: \.self) { index in
                        HStack {
                            Circle()
                                .fill(index == 0 ? ClipBetColors.yes : ClipBetColors.no)
                                .frame(width: 6, height: 6)
                            Text(validOutcomes[index])
                                .font(.custom("DM Mono", size: 14))
                                .foregroundColor(ClipBetColors.textPrimary)
                            Spacer()
                            Text("0%")
                                .font(.custom("Cormorant Garamond", size: 22))
                                .fontWeight(.light)
                                .foregroundColor(ClipBetColors.textFaint)
                        }
                        .padding(.vertical, 12)

                        if index < validOutcomes.count - 1 {
                            ClipBetDivider()
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)

                ClipBetDivider()

                // Settings summary
                VStack(spacing: 0) {
                    ReceiptRow(label: "MIN BET", value: "$\(Int(minimumBet))")
                    ReceiptRow(label: "WINDOW", value: bettingWindow.rawValue)
                    ReceiptRow(label: "FEE", value: "5% platform fee")
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)

                ClipBetDivider()

                // Go Live
                Button {
                    generatedEventId = UUID()
                    withAnimation { step = .qrCode }
                } label: {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(ClipBetColors.accent)
                            .frame(width: 8, height: 8)
                        Text("GO LIVE")
                            .font(.custom("DM Mono", size: 13))
                            .kerning(2.4)
                    }
                    .foregroundColor(ClipBetColors.bg)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(ClipBetColors.dark)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
            }
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - QR Code View

    private var qrCodeView: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                Image(systemName: "checkmark")
                    .font(.system(size: 28, weight: .light))
                    .foregroundColor(ClipBetColors.yes)

                Text("Event is Live")
                    .font(.custom("Cormorant Garamond", size: 32))
                    .fontWeight(.light)
                    .foregroundColor(ClipBetColors.textPrimary)

                MonoLabel(text: eventName)
            }

            Spacer()

            // QR code placeholder (simulated)
            VStack(spacing: 16) {
                // QR visual
                ZStack {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white)
                        .frame(width: 200, height: 200)

                    VStack(spacing: 8) {
                        Image(systemName: "qrcode")
                            .font(.system(size: 80))
                            .foregroundColor(ClipBetColors.dark)

                        Text("ClipBet")
                            .font(.custom("DM Mono", size: 8))
                            .foregroundColor(ClipBetColors.textSecondary)
                    }
                }
                .padding(16)
                .background(ClipBetColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 2))

                // URL
                let shortId = generatedEventId.uuidString.prefix(8).lowercased()
                Text("clipbet.io/event/\(shortId)")
                    .font(.custom("DM Mono", size: 12))
                    .foregroundColor(ClipBetColors.textSecondary)
            }

            Spacer()

            // Actions
            VStack(spacing: 12) {
                ClipBetPrimaryButton(title: "SHARE QR CODE", icon: "square.and.arrow.up") { }

                ClipBetSecondaryButton(title: "VIEW DASHBOARD") { }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Helpers

    private func simulateSignIn() {
        // Mock: simulate Sign in with Apple
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            isSignedIn = true
            // First time user goes to TOS, returning user skips to form
            withAnimation {
                step = isReturning ? .form : .tos
            }
        }
    }

    private var isFormValid: Bool {
        !eventName.trimmingCharacters(in: .whitespaces).isEmpty &&
        validOutcomes.count >= 2
    }

    private var validOutcomes: [String] {
        outcomes.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    private func tosSection(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.custom("DM Mono", size: 12))
                .kerning(1)
                .foregroundColor(ClipBetColors.textPrimary)
            Text(body)
                .font(.custom("DM Mono", size: 11))
                .foregroundColor(ClipBetColors.textSecondary)
                .lineSpacing(3)
        }
    }
}
