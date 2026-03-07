//  ClipBetCreateEvent.swift
//  ClipBet
//
//  Create Event flow for organizers.
//  Sign in → TOS → Event Form (photo, name, description, outcomes, time, location) → PDF Card with QR
//

import SwiftUI

// MARK: - Create Event Flow

struct CreateEventFlow: View {

    var onEventCreated: ((PredictionEvent, String, String) -> Void)?
    var onCancel: (() -> Void)?

    enum Step {
        case signIn
        case terms
        case form
        case preview
        case qrCard
    }

    @State private var step: Step = .signIn
    @State private var organizerId: String = ""
    @State private var organizer: APIOrganizer?

    // Form fields
    @State private var eventName: String = ""
    @State private var eventDescription: String = ""
    @State private var eventImage: UIImage?
    @State private var showImagePicker = false
    @State private var eventTime: Date = Date().addingTimeInterval(3600)
    @State private var showDatePicker = false
    @State private var locationName: String = ""
    @State private var outcomes: [String] = ["", ""]
    @State private var minimumBet: Double = 5
    @State private var isCreating = false

    // Created event
    @State private var createdEvent: PredictionEvent?
    @State private var qrURL: String = ""

    var body: some View {
        ZStack {
            ClipBetColors.bg.ignoresSafeArea()

            switch step {
            case .signIn:
                signInView
            case .terms:
                termsView
            case .form:
                formView
            case .preview:
                previewView
            case .qrCard:
                qrCardView
            }
        }
        .animation(.easeInOut(duration: 0.3), value: step)
        .sheet(isPresented: $showImagePicker) {
            ClipBetImagePicker(selectedImage: $eventImage)
        }
    }

    // MARK: - Sign In View

    private var signInView: some View {
        VStack(spacing: 0) {
            HStack {
                ClipBetBackButton {
                    onCancel?()
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            Spacer()

            VStack(spacing: 20) {
                Image(systemName: "person.crop.circle")
                    .font(.system(size: 48, weight: .ultraLight))
                    .foregroundColor(ClipBetColors.textPrimary)

                Text("Create a Market")
                    .font(.custom("Cormorant Garamond", size: 28))
                    .fontWeight(.light)
                    .foregroundColor(ClipBetColors.textPrimary)

                Text("Sign in to create prediction markets at your event")
                    .font(.custom("DM Mono", size: 12))
                    .foregroundColor(ClipBetColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Spacer()

            // Apple Sign In button (mock)
            Button {
                // Mock sign in
                ClipBetAPI.shared.signinOrganizer(appleUserId: "apple_\(UUID().uuidString.prefix(8))") { result in
                    switch result {
                    case .success(let response):
                        self.organizerId = response.organizer.id
                        self.organizer = response.organizer
                        if response.needs_tos {
                            withAnimation { step = .terms }
                        } else {
                            withAnimation { step = .form }
                        }
                    case .failure:
                        // Fallback for demo
                        self.organizerId = UUID().uuidString
                        withAnimation { step = .terms }
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "apple.logo")
                        .font(.system(size: 16))
                    Text("Sign in with Apple")
                        .font(.custom("DM Mono", size: 14))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.black)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }

    // MARK: - Terms View

    private var termsView: some View {
        ScrollView {
            VStack(spacing: 0) {
                HStack {
                    ClipBetBackButton {
                        onCancel?()
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                Text("Terms of Service")
                    .font(.custom("Cormorant Garamond", size: 28))
                    .fontWeight(.light)
                    .foregroundColor(ClipBetColors.textPrimary)
                    .padding(.top, 32)
                    .padding(.bottom, 24)

                ClipBetDivider()

                VStack(alignment: .leading, spacing: 16) {
                    tosItem(number: "1", text: "You will resolve each market honestly within 24 hours")
                    tosItem(number: "2", text: "Unresolved markets auto-refund all participants")
                    tosItem(number: "3", text: "ClipBet charges a 5% platform fee on all pools")
                    tosItem(number: "4", text: "Payouts are distributed via Stripe Connect")
                    tosItem(number: "5", text: "Organizers with 3+ disputes may be banned")
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)

                ClipBetDivider()

                ClipBetPrimaryButton(title: "I AGREE") {
                    withAnimation { step = .form }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
            }
        }
        .scrollIndicators(.hidden)
    }

    private func tosItem(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.custom("Cormorant Garamond", size: 22))
                .fontWeight(.light)
                .foregroundColor(ClipBetColors.yes)
                .frame(width: 20)
            Text(text)
                .font(.custom("DM Mono", size: 12))
                .foregroundColor(ClipBetColors.textSecondary)
                .lineSpacing(3)
        }
    }

    // MARK: - Form View

    private var formView: some View {
        ScrollView {
            VStack(spacing: 0) {
                HStack {
                    ClipBetBackButton {
                        onCancel?()
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                Text("Create Market")
                    .font(.custom("Cormorant Garamond", size: 28))
                    .fontWeight(.light)
                    .foregroundColor(ClipBetColors.textPrimary)
                    .padding(.top, 32)
                    .padding(.bottom, 24)

                ClipBetDivider()

                // Event photo (optional)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        MonoLabelLeft(text: "EVENT PHOTO")
                        Spacer()
                        Text("optional")
                            .font(.custom("DM Mono", size: 10))
                            .foregroundColor(ClipBetColors.textFaint)
                    }

                    Button { showImagePicker = true } label: {
                        if let image = eventImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 140)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 2))
                        } else {
                            VStack(spacing: 8) {
                                Image(systemName: "camera")
                                    .font(.system(size: 20, weight: .light))
                                    .foregroundColor(ClipBetColors.textFaint)
                                Text("TAP TO ADD PHOTO")
                                    .font(.custom("DM Mono", size: 10))
                                    .kerning(1.2)
                                    .foregroundColor(ClipBetColors.textFaint)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 140)
                            .background(ClipBetColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 2))
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)

                ClipBetDivider()

                // Event name (required)
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

                // Description (optional)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        MonoLabelLeft(text: "DESCRIPTION")
                        Spacer()
                        Text("optional")
                            .font(.custom("DM Mono", size: 10))
                            .foregroundColor(ClipBetColors.textFaint)
                    }
                    ClipBetTextEditor(
                        placeholder: "Add context about your event...",
                        text: $eventDescription
                    )
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)

                ClipBetDivider()

                // Outcomes
                VStack(alignment: .leading, spacing: 12) {
                    MonoLabelLeft(text: "OUTCOMES")
                        .padding(.horizontal, 24)

                    ForEach(outcomes.indices, id: \.self) { i in
                        HStack {
                            Circle()
                                .fill(i == 0 ? ClipBetColors.yes : ClipBetColors.no)
                                .frame(width: 8, height: 8)
                            TextField("Outcome \(i + 1)", text: Binding(
                                get: { outcomes[i] },
                                set: { outcomes[i] = $0 }
                            ))
                            .font(.custom("DM Mono", size: 14))
                            .foregroundColor(ClipBetColors.textPrimary)
                        }
                        .padding(.horizontal, 24)
                    }

                    if outcomes.count < 6 {
                        Button {
                            outcomes.append("")
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                    .font(.system(size: 10))
                                Text("ADD OUTCOME")
                                    .font(.custom("DM Mono", size: 10))
                                    .kerning(1.0)
                            }
                            .foregroundColor(ClipBetColors.yes)
                        }
                        .padding(.horizontal, 24)
                    }
                }
                .padding(.vertical, 20)

                ClipBetDivider()

                // Event time
                ClipBetDatePickerField(
                    label: "EVENT TIME",
                    date: $eventTime,
                    showPicker: $showDatePicker
                )
                .padding(.horizontal, 24)
                .padding(.vertical, 20)

                ClipBetDivider()

                // Location
                VStack(alignment: .leading, spacing: 8) {
                    MonoLabelLeft(text: "LOCATION")
                    ClipBetTextField(
                        placeholder: "Scotiabank Arena, Toronto",
                        text: $locationName,
                        autocapitalization: .words
                    )
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)

                ClipBetDivider()

                // Minimum bet
                VStack(alignment: .leading, spacing: 12) {
                    MonoLabelLeft(text: "MINIMUM BET")
                        .padding(.horizontal, 24)

                    HStack(spacing: 8) {
                        ForEach([5.0, 10.0, 25.0], id: \.self) { amount in
                            Button {
                                minimumBet = amount
                            } label: {
                                Text("$\(Int(amount))")
                                    .font(.custom("DM Mono", size: 13))
                                    .foregroundColor(minimumBet == amount ? ClipBetColors.surface : ClipBetColors.textSecondary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(minimumBet == amount ? ClipBetColors.dark : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 2))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 2)
                                            .stroke(ClipBetColors.divider, lineWidth: 1)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.vertical, 20)

                ClipBetDivider()

                // Preview button
                ClipBetPrimaryButton(
                    title: isCreating ? "CREATING..." : "PREVIEW MARKET",
                    isEnabled: isFormValid && !isCreating
                ) {
                    withAnimation { step = .preview }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
            }
        }
        .scrollIndicators(.hidden)
    }

    private var isFormValid: Bool {
        !eventName.trimmingCharacters(in: .whitespaces).isEmpty &&
        outcomes.filter({ !$0.trimmingCharacters(in: .whitespaces).isEmpty }).count >= 2
    }

    // MARK: - Preview View

    private var previewView: some View {
        ScrollView {
            VStack(spacing: 0) {

                HStack {
                    ClipBetBackButton {
                        withAnimation { step = .form }
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                Text("Preview")
                    .font(.custom("Cormorant Garamond", size: 28))
                    .fontWeight(.light)
                    .foregroundColor(ClipBetColors.textPrimary)
                    .padding(.top, 16)
                    .padding(.bottom, 24)

                ClipBetDivider()

                // Preview card
                VStack(spacing: 0) {
                    if let image = eventImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 160)
                            .clipped()
                        ClipBetDivider()
                    }

                    VStack(spacing: 12) {
                        StatusIndicator(status: .live)

                        Text(eventName)
                            .font(.custom("Cormorant Garamond", size: 24))
                            .fontWeight(.light)
                            .foregroundColor(ClipBetColors.textPrimary)
                            .multilineTextAlignment(.center)

                        if !eventDescription.isEmpty {
                            Text(eventDescription)
                                .font(.custom("DM Mono", size: 11))
                                .foregroundColor(ClipBetColors.textSecondary)
                                .multilineTextAlignment(.center)
                        }

                        HStack(spacing: 16) {
                            if !locationName.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: "mappin")
                                        .font(.system(size: 9))
                                    Text(locationName)
                                        .font(.custom("DM Mono", size: 10))
                                }
                                .foregroundColor(ClipBetColors.textFaint)
                            }

                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.system(size: 9))
                                let formatter = DateFormatter()
                                let _ = formatter.dateFormat = "MMM d, h:mm a"
                                Text(formatter.string(from: eventTime))
                                    .font(.custom("DM Mono", size: 10))
                            }
                            .foregroundColor(ClipBetColors.textFaint)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 24)

                    ClipBetDivider()

                    // Outcomes preview
                    VStack(spacing: 0) {
                        ForEach(validOutcomes.indices, id: \.self) { index in
                            HStack {
                                Circle()
                                    .fill(index == 0 ? ClipBetColors.yes : ClipBetColors.no)
                                    .frame(width: 8, height: 8)
                                Text(validOutcomes[index])
                                    .font(.custom("DM Mono", size: 14))
                                    .foregroundColor(ClipBetColors.textPrimary)
                                Spacer()
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)

                            if index < validOutcomes.count - 1 {
                                ClipBetDivider()
                            }
                        }
                    }
                }
                .background(ClipBetColors.surface.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 2))
                .padding(.horizontal, 24)
                .padding(.vertical, 24)

                ClipBetDivider()

                // Create button
                ClipBetPrimaryButton(
                    title: isCreating ? "CREATING MARKET..." : "CREATE MARKET",
                    isEnabled: !isCreating
                ) {
                    createMarket()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)

                ClipBetSecondaryButton(title: "EDIT") {
                    withAnimation { step = .form }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .scrollIndicators(.hidden)
    }

    private var validOutcomes: [String] {
        outcomes.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    private func createMarket() {
        isCreating = true

        ClipBetAPI.shared.createEvent(
            name: eventName,
            description: eventDescription.isEmpty ? nil : eventDescription,
            imageURL: nil, // Image would be uploaded to storage in production
            options: validOutcomes,
            minimumBet: minimumBet,
            organizerId: organizerId,
            locationName: locationName.isEmpty ? nil : locationName,
            locationLat: nil,
            locationLng: nil,
            eventTime: eventTime
        ) { result in
            isCreating = false
            switch result {
            case .success(let (event, url)):
                self.createdEvent = event
                self.qrURL = url
                withAnimation { step = .qrCard }
            case .failure:
                // Fallback for demo
                let mockId = UUID()
                self.createdEvent = PredictionEvent(
                    id: mockId,
                    name: eventName,
                    description: eventDescription.isEmpty ? nil : eventDescription,
                    imageURL: nil,
                    localImage: eventImage,
                    location: locationName.isEmpty ? "Unknown" : locationName,
                    locationLat: 0, locationLng: 0,
                    organizer: "You",
                    organizerId: UUID(),
                    status: .live,
                    outcomes: validOutcomes.map { BetOutcome(id: UUID(), name: $0, totalAmount: 0, betCount: 0) },
                    minimumBet: minimumBet,
                    bettingWindow: .manual,
                    createdAt: Date(),
                    eventTime: eventTime
                )
                self.qrURL = "clipbet.io/event/\(mockId.uuidString.prefix(8).lowercased())"
                withAnimation { step = .qrCard }
            }
        }
    }

    // MARK: - QR Card View (Printable PDF)

    private var qrCardView: some View {
        ScrollView {
            VStack(spacing: 0) {

                Text("Your Market is Live")
                    .font(.custom("Cormorant Garamond", size: 28))
                    .fontWeight(.light)
                    .foregroundColor(ClipBetColors.textPrimary)
                    .padding(.top, 32)
                    .padding(.bottom, 8)

                MonoLabel(text: "Print this card and place it at your venue")
                    .padding(.bottom, 24)

                ClipBetDivider()

                // Printable card
                VStack(spacing: 0) {
                    // Event header
                    VStack(spacing: 12) {
                        Text("CLIPBET")
                            .font(.custom("DM Mono", size: 11))
                            .kerning(3)
                            .foregroundColor(ClipBetColors.textFaint)

                        if let image = eventImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 120)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 2))
                        }

                        Text(eventName)
                            .font(.custom("Cormorant Garamond", size: 22))
                            .fontWeight(.light)
                            .foregroundColor(ClipBetColors.textPrimary)
                            .multilineTextAlignment(.center)

                        if !eventDescription.isEmpty {
                            Text(eventDescription)
                                .font(.custom("DM Mono", size: 10))
                                .foregroundColor(ClipBetColors.textSecondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(2)
                        }

                        if !locationName.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "mappin")
                                    .font(.system(size: 9))
                                Text(locationName)
                                    .font(.custom("DM Mono", size: 10))
                            }
                            .foregroundColor(ClipBetColors.textFaint)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 24)

                    ClipBetDivider()

                    // QR Code
                    VStack(spacing: 16) {
                        QRCodeView(url: qrURL, size: 180)
                            .padding(16)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 4))

                        Text("SCAN TO PREDICT")
                            .font(.custom("DM Mono", size: 12))
                            .kerning(2)
                            .foregroundColor(ClipBetColors.textSecondary)

                        Text(qrURL)
                            .font(.custom("DM Mono", size: 10))
                            .foregroundColor(ClipBetColors.textFaint)
                    }
                    .padding(.vertical, 24)

                    ClipBetDivider()

                    // Footer
                    Text("CLIPBET · LIVE NOW")
                        .font(.custom("DM Mono", size: 9))
                        .kerning(2)
                        .foregroundColor(ClipBetColors.textFaint)
                        .padding(.vertical, 16)
                }
                .background(ClipBetColors.surface.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 2))
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(ClipBetColors.divider, lineWidth: 1)
                )
                .padding(.horizontal, 24)
                .padding(.vertical, 24)

                // Actions
                VStack(spacing: 12) {
                    // Share
                    if let url = URL(string: "https://\(qrURL)") {
                        ShareLink(item: url) {
                            HStack(spacing: 8) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 14))
                                Text("SHARE")
                                    .font(.custom("DM Mono", size: 13))
                                    .kerning(1.4)
                            }
                            .foregroundColor(ClipBetColors.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 2)
                                    .stroke(ClipBetColors.dark, lineWidth: 1)
                            )
                        }
                    }

                    // Go to Dashboard
                    ClipBetPrimaryButton(title: "GO TO DASHBOARD") {
                        if let event = createdEvent {
                            onEventCreated?(event, qrURL, organizerId)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .scrollIndicators(.hidden)
    }
}
