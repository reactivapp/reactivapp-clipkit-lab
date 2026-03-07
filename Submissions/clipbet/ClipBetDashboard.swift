//  ClipBetDashboard.swift
//  ClipBet
//
//  Organizer Dashboard — manage live events.
//  View pool stats, close bets, resolve outcomes, cancel events, share QR.
//

import SwiftUI

struct OrganizerDashboard: View {

    @State var event: PredictionEvent
    var qrURL: String?
    var organizerId: String?

    @State private var generatedPDFURL: URL?

    @State private var showResolveSheet = false
    @State private var showCancelConfirm = false
    @State private var isProcessing = false
    @State private var refreshTimer: Timer?

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {

                // Header
                VStack(spacing: 12) {
                    Text("Dashboard")
                        .font(.custom("Cormorant Garamond", size: 28))
                        .fontWeight(.light)
                        .foregroundColor(ClipBetColors.textPrimary)

                    StatusIndicator(status: event.status)
                }
                .padding(.top, 24)
                .padding(.bottom, 20)

                ClipBetDivider()

                // Event name
                VStack(spacing: 8) {
                    Text(event.name)
                        .font(.custom("Cormorant Garamond", size: 22))
                        .fontWeight(.light)
                        .foregroundColor(ClipBetColors.textPrimary)
                        .multilineTextAlignment(.center)

                    if let timeString = event.formattedEventTime {
                        HStack(spacing: 6) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                            Text(timeString)
                                .font(.custom("DM Mono", size: 11))
                        }
                        .foregroundColor(ClipBetColors.textFaint)
                    }

                    MonoLabel(text: event.location)
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 20)

                ClipBetDivider()

                // Live stats
                HStack(spacing: 0) {
                    StatColumn(value: event.formattedPool, label: "TOTAL POOL")
                    ClipBetVerticalDivider()
                    StatColumn(value: "\(event.totalBettors)", label: "BETTORS")
                    ClipBetVerticalDivider()
                    StatColumn(value: String(format: "$%.0f", event.platformFee), label: "YOUR FEE")
                }
                .padding(.vertical, 20)

                ClipBetDivider()

                // Outcomes with animated bars
                VStack(spacing: 0) {
                    MonoLabelLeft(text: "OUTCOMES")
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .padding(.bottom, 12)

                    ForEach(Array(event.outcomes.enumerated()), id: \.element.id) { index, outcome in
                        VStack(spacing: 8) {
                            HStack {
                                Circle()
                                    .fill(index == 0 ? ClipBetColors.yes : ClipBetColors.no)
                                    .frame(width: 8, height: 8)
                                Text(outcome.name)
                                    .font(.custom("DM Mono", size: 13))
                                    .foregroundColor(ClipBetColors.textPrimary)
                                Spacer()
                                Text(String(format: "%.0f%%", event.percentage(for: outcome)))
                                    .font(.custom("Cormorant Garamond", size: 20))
                                    .fontWeight(.light)
                                    .foregroundColor(index == 0 ? ClipBetColors.yes : ClipBetColors.no)
                            }

                            // Progress bar
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(ClipBetColors.divider)
                                        .frame(height: 3)
                                    Rectangle()
                                        .fill(index == 0 ? ClipBetColors.yes : ClipBetColors.no)
                                        .frame(
                                            width: geo.size.width * (event.percentage(for: outcome) / 100),
                                            height: 3
                                        )
                                        .animation(.easeInOut(duration: 0.6), value: event.percentage(for: outcome))
                                }
                            }
                            .frame(height: 3)

                            HStack {
                                Text("\(outcome.betCount) bets")
                                    .font(.custom("DM Mono", size: 10))
                                    .foregroundColor(ClipBetColors.textFaint)
                                Spacer()
                                Text(String(format: "$%.0f", outcome.totalAmount))
                                    .font(.custom("DM Mono", size: 10))
                                    .foregroundColor(ClipBetColors.textFaint)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)

                        if index < event.outcomes.count - 1 {
                            ClipBetDivider()
                        }
                    }
                }
                .padding(.bottom, 16)

                ClipBetDivider()

                // Actions — state dependent
                VStack(spacing: 12) {
                    if event.status == .live {
                        // Close bets
                        ClipBetSecondaryButton(title: isProcessing ? "PROCESSING..." : "CLOSE BETS") {
                            closeBets()
                        }

                        // Cancel & refund
                        Button {
                            showCancelConfirm = true
                        } label: {
                            Text("CANCEL & REFUND ALL")
                                .font(.custom("DM Mono", size: 12))
                                .kerning(1.2)
                                .foregroundColor(ClipBetColors.no)
                        }
                    }

                    if event.status == .betsClosed || event.status == .live {
                        // Resolve
                        ClipBetPrimaryButton(
                            title: isProcessing ? "RESOLVING..." : "RESOLVE EVENT",
                            isEnabled: !isProcessing
                        ) {
                            showResolveSheet = true
                        }
                    }

                    if event.status == .resolved {
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 24, weight: .light))
                                .foregroundColor(ClipBetColors.yes)
                            Text("EVENT RESOLVED")
                                .font(.custom("DM Mono", size: 12))
                                .kerning(1.4)
                                .foregroundColor(ClipBetColors.yes)
                            Text("Winners have been paid out")
                                .font(.custom("DM Mono", size: 10))
                                .foregroundColor(ClipBetColors.textFaint)
                        }
                    }

                    if event.status == .cancelled {
                        VStack(spacing: 8) {
                            Image(systemName: "xmark.circle")
                                .font(.system(size: 24, weight: .light))
                                .foregroundColor(ClipBetColors.no)
                            Text("EVENT CANCELLED")
                                .font(.custom("DM Mono", size: 12))
                                .kerning(1.4)
                                .foregroundColor(ClipBetColors.no)
                            Text("All participants have been refunded")
                                .font(.custom("DM Mono", size: 10))
                                .foregroundColor(ClipBetColors.textFaint)
                        }
                    }

                    // Share PDF / QR
                    if let pdfURL = generatedPDFURL {
                        ShareLink(item: pdfURL) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.down.doc.fill")
                                    .font(.system(size: 14))
                                Text("SAVE PDF POSTER")
                                    .font(.custom("DM Mono", size: 12))
                                    .kerning(1.2)
                            }
                            .foregroundColor(ClipBetColors.bg)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(ClipBetColors.textPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 2))
                        }
                    } else {
                        Button {
                            self.generatedPDFURL = generatePDF()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "doc.text")
                                    .font(.system(size: 14))
                                Text("GENERATE PRINTABLE PDF")
                                    .font(.custom("DM Mono", size: 12))
                                    .kerning(1.2)
                            }
                            .foregroundColor(ClipBetColors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 2)
                                    .stroke(ClipBetColors.divider, lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
            }
        }
        .scrollIndicators(.hidden)
        .onAppear { startPolling() }
        .onDisappear { stopPolling() }
        .sheet(isPresented: $showResolveSheet) {
            resolveSheet
        }
        .alert("Cancel Event?", isPresented: $showCancelConfirm) {
            Button("Cancel Event", role: .destructive) { cancelEvent() }
            Button("Keep Open", role: .cancel) { }
        } message: {
            Text("All bettors will receive full refunds. This cannot be undone.")
        }
    }

    // MARK: - Resolve Sheet

    private var resolveSheet: some View {
        NavigationView {
            VStack(spacing: 0) {
                Text("Select Winner")
                    .font(.custom("Cormorant Garamond", size: 24))
                    .fontWeight(.light)
                    .foregroundColor(ClipBetColors.textPrimary)
                    .padding(.top, 24)
                    .padding(.bottom, 8)

                MonoLabel(text: "Choose the winning outcome")
                    .padding(.bottom, 24)

                ClipBetDivider()

                ForEach(Array(event.outcomes.enumerated()), id: \.element.id) { index, outcome in
                    Button {
                        resolveEvent(winningOptionId: outcome.id.uuidString)
                        showResolveSheet = false
                    } label: {
                        HStack {
                            Circle()
                                .fill(index == 0 ? ClipBetColors.yes : ClipBetColors.no)
                                .frame(width: 10, height: 10)
                            Text(outcome.name)
                                .font(.custom("DM Mono", size: 14))
                                .foregroundColor(ClipBetColors.textPrimary)
                            Spacer()
                            Text(String(format: "$%.0f", outcome.totalAmount))
                                .font(.custom("DM Mono", size: 12))
                                .foregroundColor(ClipBetColors.textFaint)
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                    }

                    if index < event.outcomes.count - 1 {
                        ClipBetDivider()
                    }
                }

                Spacer()
            }
            .background(ClipBetColors.bg)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showResolveSheet = false }
                }
            }
        }
    }

    // MARK: - Actions

    private func closeBets() {
        isProcessing = true
        ClipBetAPI.shared.closeBets(eventId: event.id.uuidString) { result in
            isProcessing = false
            if case .success = result {
                event.status = .betsClosed
            }
        }
    }
    
    // MARK: - PDF Generation
    
    private func generatePDF() -> URL? {
        let pdfMetaData = [
            kCGPDFContextCreator: "ClipBet",
            kCGPDFContextAuthor: "Organizer"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0 // US Letter
        let pageHeight = 11.0 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("ClipBet-QR-\(event.id.uuidString.prefix(6)).pdf")
        
        do {
            try renderer.writePDF(to: tempURL) { context in
                context.beginPage()
                
                let titleAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 36, weight: .bold)
                ]
                let titleString = "Scan to bet on:\n\(event.name)"
                titleString.draw(in: CGRect(x: 50, y: 100, width: pageWidth - 100, height: 100), withAttributes: titleAttributes)
                
                if let qrURL = qrURL {
                    let urlAttributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 18, weight: .regular)
                    ]
                    "\(qrURL)".draw(in: CGRect(x: 50, y: 250, width: pageWidth - 100, height: 50), withAttributes: urlAttributes)
                }
            }
            return tempURL
        } catch {
            print("Could not create PDF: \(error)")
            return nil
        }
    }
    private func resolveEvent(winningOptionId: String) {
        isProcessing = true
        ClipBetAPI.shared.resolveEvent(
            eventId: event.id.uuidString,
            winningOptionId: winningOptionId,
            organizerId: organizerId ?? ""
        ) { result in
            isProcessing = false
            if case .success = result {
                event.status = .resolved
                event.resolvedOutcomeId = UUID(uuidString: winningOptionId)
            }
        }
    }

    private func cancelEvent() {
        isProcessing = true
        ClipBetAPI.shared.cancelEvent(
            eventId: event.id.uuidString,
            organizerId: organizerId ?? ""
        ) { result in
            isProcessing = false
            if case .success = result {
                event.status = .cancelled
            }
        }
    }

    // MARK: - Polling

    private func startPolling() {
        guard !ClipBetAPIConfig.useMockData else { return }
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in
            ClipBetAPI.shared.fetchEvent(id: event.id.uuidString) { result in
                if case .success(let updated) = result {
                    self.event = updated
                }
            }
        }
    }

    private func stopPolling() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
}
