//  ClipBetDashboard.swift
//  ClipBet
//
//  Organizer Dashboard — manage live events.
//  View pool stats, close bets, resolve outcomes, cancel events, share QR.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct OrganizerDashboard: View {

    @State var event: PredictionEvent
    var qrURL: String?
    var organizerId: String?
    var onBack: (() -> Void)?

    @State private var generatedPDFURL: URL?

    @State private var showResolveSheet = false
    @State private var showCancelConfirm = false
    @State private var isProcessing = false
    @State private var refreshTimer: Timer?

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header Back Button
                HStack {
                    ClipBetBackButton {
                        onBack?()
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                // Header
                VStack(spacing: 12) {
                    Text("Dashboard")
                        .font(.custom("Cormorant Garamond", size: 28))
                        .fontWeight(.regular)
                        .foregroundColor(ClipBetColors.textPrimary)

                    StatusIndicator(status: event.status)
                }
                .padding(.top, 24)
                .padding(.bottom, 20)

                ClipBetDivider()

                // Event name and image
                VStack(spacing: 8) {
                    if let localImage = event.localImage {
                        Image(uiImage: localImage)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 120)
                            .clipped()
                        
                        ClipBetDivider()
                            .padding(.bottom, 8)
                    } else if let imageURL = event.imageURL, !imageURL.isEmpty {
                        AsyncImage(url: URL(string: imageURL)) { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 120)
                                .clipped()
                        } placeholder: {
                            Rectangle()
                                .fill(ClipBetColors.surface)
                                .frame(height: 120)
                        }
                        
                        ClipBetDivider()
                            .padding(.bottom, 8)
                    }

                    Text(event.name)
                        .font(.custom("Cormorant Garamond", size: 22))
                        .fontWeight(.regular)
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
                                    .fontWeight(.regular)
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

                    if event.status == .live || event.status == .planned {
                        // Cancel & refund
                        if showCancelConfirm {
                            VStack(spacing: 8) {
                                Text("All bettors will receive full refunds. This cannot be undone.")
                                    .font(.custom("DM Mono", size: 10))
                                    .foregroundColor(ClipBetColors.no)
                                    .multilineTextAlignment(.center)
                                    .padding(.bottom, 8)
                                    
                                ClipBetPrimaryButton(title: "YES, CANCEL EVENT") {
                                    showCancelConfirm = false
                                    cancelEvent()
                                }
                                
                                ClipBetSecondaryButton(title: "KEEP OPEN") {
                                    showCancelConfirm = false
                                }
                            }
                            .padding()
                            .background(ClipBetColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 2))
                        } else {
                            ClipBetSecondaryButton(title: "CANCEL & REFUND ALL") {
                                withAnimation { showCancelConfirm = true }
                            }
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
                            .foregroundColor(ClipBetColors.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 2)
                                    .stroke(ClipBetColors.textPrimary, lineWidth: 1.5)
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
    }

    // MARK: - Resolve Sheet

    private var resolveSheet: some View {
        NavigationView {
            VStack(spacing: 0) {
                Text("Select Winner")
                    .font(.custom("Cormorant Garamond", size: 24))
                    .fontWeight(.regular)
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
                    Button { showResolveSheet = false } label: {
                        Text("Cancel")
                            .font(.custom("DM Mono", size: 12))
                            .kerning(1.6)
                            .foregroundColor(ClipBetColors.textPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 2)
                                    .stroke(ClipBetColors.textPrimary, lineWidth: 1.5)
                            )
                    }
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
            kCGPDFContextAuthor: "Organizer",
            kCGPDFContextTitle: event.name
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth: CGFloat = 8.5 * 72.0 // US Letter
        let pageHeight: CGFloat = 11.0 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let margin: CGFloat = 50
        let contentWidth = pageWidth - margin * 2
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("ClipBet-Poster-\(event.id.uuidString.prefix(6)).pdf")
        
        do {
            try renderer.writePDF(to: tempURL) { context in
                context.beginPage()
                var yOffset: CGFloat = margin
                
                // --- 1. Event Image (if available) ---
                if let image = event.localImage ?? loadRemoteImage() {
                    let imageHeight: CGFloat = 200
                    let imageRect = CGRect(x: margin, y: yOffset, width: contentWidth, height: imageHeight)
                    
                    // Draw rounded clip
                    let clipPath = UIBezierPath(roundedRect: imageRect, cornerRadius: 4)
                    context.cgContext.saveGState()
                    clipPath.addClip()
                    
                    // Scale to fill
                    let imageAspect = image.size.width / image.size.height
                    let rectAspect = contentWidth / imageHeight
                    var drawRect = imageRect
                    if imageAspect > rectAspect {
                        let scaledWidth = imageHeight * imageAspect
                        drawRect = CGRect(
                            x: margin - (scaledWidth - contentWidth) / 2,
                            y: yOffset,
                            width: scaledWidth,
                            height: imageHeight
                        )
                    } else {
                        let scaledHeight = contentWidth / imageAspect
                        drawRect = CGRect(
                            x: margin,
                            y: yOffset - (scaledHeight - imageHeight) / 2,
                            width: contentWidth,
                            height: scaledHeight
                        )
                    }
                    image.draw(in: drawRect)
                    context.cgContext.restoreGState()
                    yOffset += imageHeight + 24
                } else {
                    yOffset += 20
                }
                
                // --- 2. ClipBet Branding ---
                let brandAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 10, weight: .medium),
                    .foregroundColor: UIColor.gray,
                    .kern: 4.0
                ]
                let brandString = "CLIPBET"
                let brandSize = brandString.size(withAttributes: brandAttrs)
                brandString.draw(
                    at: CGPoint(x: (pageWidth - brandSize.width) / 2, y: yOffset),
                    withAttributes: brandAttrs
                )
                yOffset += brandSize.height + 16
                
                // --- 3. Divider line ---
                drawDivider(in: context.cgContext, y: yOffset, margin: margin, width: contentWidth)
                yOffset += 16
                
                // --- 4. Event Name ---
                let titleAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 28, weight: .bold),
                    .foregroundColor: UIColor.black
                ]
                let titleParagraph = NSMutableParagraphStyle()
                titleParagraph.alignment = .center
                titleParagraph.lineSpacing = 4
                let titleDrawAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 28, weight: .bold),
                    .foregroundColor: UIColor.black,
                    .paragraphStyle: titleParagraph
                ]
                let titleRect = CGRect(x: margin, y: yOffset, width: contentWidth, height: 120)
                let titleBounds = event.name.boundingRect(
                    with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: titleDrawAttrs,
                    context: nil
                )
                event.name.draw(in: titleRect, withAttributes: titleDrawAttrs)
                yOffset += min(titleBounds.height, 120) + 12
                
                // --- 5. Description (if available) ---
                if let desc = event.description, !desc.isEmpty {
                    let descParagraph = NSMutableParagraphStyle()
                    descParagraph.alignment = .center
                    descParagraph.lineSpacing = 3
                    let descAttrs: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 12, weight: .regular),
                        .foregroundColor: UIColor.darkGray,
                        .paragraphStyle: descParagraph
                    ]
                    let descRect = CGRect(x: margin + 20, y: yOffset, width: contentWidth - 40, height: 80)
                    let descBounds = desc.boundingRect(
                        with: CGSize(width: contentWidth - 40, height: .greatestFiniteMagnitude),
                        options: [.usesLineFragmentOrigin, .usesFontLeading],
                        attributes: descAttrs,
                        context: nil
                    )
                    desc.draw(in: descRect, withAttributes: descAttrs)
                    yOffset += min(descBounds.height, 80) + 12
                }
                
                // --- 6. Location & Time ---
                let infoAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 11, weight: .regular),
                    .foregroundColor: UIColor.gray,
                    .kern: 1.0
                ]
                var infoString = ""
                if !event.location.isEmpty { infoString += event.location }
                if let timeStr = event.formattedEventTime {
                    if !infoString.isEmpty { infoString += "  ·  " }
                    infoString += timeStr
                }
                if !infoString.isEmpty {
                    let infoSize = infoString.size(withAttributes: infoAttrs)
                    infoString.draw(
                        at: CGPoint(x: (pageWidth - infoSize.width) / 2, y: yOffset),
                        withAttributes: infoAttrs
                    )
                    yOffset += infoSize.height + 16
                }
                
                // --- 7. Divider ---
                drawDivider(in: context.cgContext, y: yOffset, margin: margin, width: contentWidth)
                yOffset += 16
                
                // --- 8. Outcomes ---
                let outcomeNameAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 14, weight: .medium),
                    .foregroundColor: UIColor.black
                ]
                let outcomePctAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 14, weight: .regular),
                    .foregroundColor: UIColor.darkGray
                ]
                
                for (index, outcome) in event.outcomes.enumerated() {
                    let pct = event.percentage(for: outcome)
                    let dotColor: UIColor = index == 0
                        ? UIColor(red: 100/255, green: 170/255, blue: 140/255, alpha: 1)
                        : UIColor(red: 200/255, green: 100/255, blue: 100/255, alpha: 1)
                    
                    // Dot
                    let dotRect = CGRect(x: margin + 10, y: yOffset + 5, width: 8, height: 8)
                    context.cgContext.setFillColor(dotColor.cgColor)
                    context.cgContext.fillEllipse(in: dotRect)
                    
                    // Name
                    outcome.name.draw(
                        at: CGPoint(x: margin + 28, y: yOffset),
                        withAttributes: outcomeNameAttrs
                    )
                    
                    // Percentage
                    let pctStr = String(format: "%.0f%%", pct)
                    let pctSize = pctStr.size(withAttributes: outcomePctAttrs)
                    pctStr.draw(
                        at: CGPoint(x: margin + contentWidth - pctSize.width - 10, y: yOffset),
                        withAttributes: outcomePctAttrs
                    )
                    
                    yOffset += 24
                }
                
                yOffset += 8
                
                // --- 9. Divider ---
                drawDivider(in: context.cgContext, y: yOffset, margin: margin, width: contentWidth)
                yOffset += 24
                
                // --- 10. QR Code ---
                if let qrURLString = qrURL, let qrImage = generateQRCodeImage(from: qrURLString) {
                    let qrSize: CGFloat = 180
                    let qrX = (pageWidth - qrSize) / 2
                    
                    // White background behind QR
                    let qrBg = CGRect(x: qrX - 12, y: yOffset - 12, width: qrSize + 24, height: qrSize + 24)
                    context.cgContext.setFillColor(UIColor.white.cgColor)
                    context.cgContext.fill(qrBg)
                    context.cgContext.setStrokeColor(UIColor(white: 0.85, alpha: 1).cgColor)
                    context.cgContext.setLineWidth(1)
                    context.cgContext.stroke(qrBg)
                    
                    let qrRect = CGRect(x: qrX, y: yOffset, width: qrSize, height: qrSize)
                    qrImage.draw(in: qrRect)
                    yOffset += qrSize + 20
                    
                    // "SCAN TO PREDICT" label
                    let scanAttrs: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 12, weight: .medium),
                        .foregroundColor: UIColor.darkGray,
                        .kern: 3.0
                    ]
                    let scanLabel = "SCAN TO PREDICT"
                    let scanSize = scanLabel.size(withAttributes: scanAttrs)
                    scanLabel.draw(
                        at: CGPoint(x: (pageWidth - scanSize.width) / 2, y: yOffset),
                        withAttributes: scanAttrs
                    )
                    yOffset += scanSize.height + 8
                    
                    // URL
                    let urlAttrs: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 10, weight: .regular),
                        .foregroundColor: UIColor.gray
                    ]
                    let urlSize = qrURLString.size(withAttributes: urlAttrs)
                    qrURLString.draw(
                        at: CGPoint(x: (pageWidth - urlSize.width) / 2, y: yOffset),
                        withAttributes: urlAttrs
                    )
                    yOffset += urlSize.height + 24
                }
                
                // --- 11. Footer divider ---
                drawDivider(in: context.cgContext, y: yOffset, margin: margin, width: contentWidth)
                yOffset += 12
                
                // --- 12. Footer ---
                let footerAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 9, weight: .regular),
                    .foregroundColor: UIColor.lightGray,
                    .kern: 2.0
                ]
                let footerLabel = "CLIPBET · POWERED BY APP CLIPS"
                let footerSize = footerLabel.size(withAttributes: footerAttrs)
                footerLabel.draw(
                    at: CGPoint(x: (pageWidth - footerSize.width) / 2, y: yOffset),
                    withAttributes: footerAttrs
                )
            }
            return tempURL
        } catch {
            print("Could not create PDF: \(error)")
            return nil
        }
    }
    
    // MARK: - PDF Helpers
    
    private func drawDivider(in cgContext: CGContext, y: CGFloat, margin: CGFloat, width: CGFloat) {
        cgContext.setStrokeColor(UIColor(white: 0.85, alpha: 1).cgColor)
        cgContext.setLineWidth(0.5)
        cgContext.move(to: CGPoint(x: margin, y: y))
        cgContext.addLine(to: CGPoint(x: margin + width, y: y))
        cgContext.strokePath()
    }
    
    private func generateQRCodeImage(from string: String) -> UIImage? {
        let ciContext = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        
        guard let ciImage = filter.outputImage else { return nil }
        let scale: CGFloat = 180 / ciImage.extent.width
        let scaledImage = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        guard let cgImage = ciContext.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
    
    private func loadRemoteImage() -> UIImage? {
        guard let urlStr = event.imageURL, !urlStr.isEmpty,
              let url = URL(string: urlStr),
              let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
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
