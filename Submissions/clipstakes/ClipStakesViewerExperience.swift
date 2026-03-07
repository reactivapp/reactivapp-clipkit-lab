import SwiftUI

struct ClipStakesViewerExperience: ClipExperience {
    static let urlPattern = "clip.clipstakes.app/v/:productId"
    static let clipName = "ClipStakes Viewer"
    static let clipDescription = "Watch real customer clips and buy in seconds."
    static let teamName = "ClipStakes"
    static let touchpoint: JourneyTouchpoint = .onSite
    static let invocationSource: InvocationSource = .nfcTag

    let context: ClipContext

    @State private var clips: [ClipStakesClip] = []
    @State private var isLoading = true
    @State private var selectedClipID: String?
    @State private var showCheckout = false
    @State private var checkoutInFlight = false
    @State private var checkoutOutcome: ClipStakesCheckoutOutcome?
    @State private var errorMessage: String?
    @State private var copiedReceiptURL = false
    @State private var catalogStatusMessage: String?
    @State private var pulseCTA = false

    private var productID: String {
        context.pathParameters["productId"] ?? "prod_hoodie"
    }

    private var storeDomainOverride: String? {
        context.queryParameters["store"]
    }

    private var product: ClipStakesProduct {
        ClipStakesCatalog.product(for: productID)
    }

    private var currentClip: ClipStakesClip? {
        if let selectedClipID,
           let match = clips.first(where: { $0.id == selectedClipID }) {
            return match
        }
        return clips.first
    }

    private var currentIndex: Int {
        guard let currentClip,
              let index = clips.firstIndex(where: { $0.id == currentClip.id })
        else { return 0 }
        return index + 1
    }

    private var compactCatalogStatus: String? {
        guard let catalogStatusMessage else { return nil }

        let lowered = catalogStatusMessage.lowercased()
        if lowered.contains("fallback catalog") {
            return "Fallback catalog active"
        }
        if lowered.contains("public shopify catalog") {
            return "Public Shopify catalog loaded"
        }

        return catalogStatusMessage
    }

    var body: some View {
        ZStack {
            ClipStakesStageBackground()

            if isLoading {
                loadingView
            } else if clips.isEmpty {
                emptyState
            } else {
                reelsFeed
            }

            topHUD
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.35).repeatForever(autoreverses: true)) {
                pulseCTA = true
            }
        }
        .task(id: productID + "|" + (storeDomainOverride ?? "")) {
            await loadClips()
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomOverlay
        }
        .sheet(isPresented: $showCheckout) {
            if let clip = currentClip {
                ClipStakesViewerCheckoutSheet(
                    product: product,
                    clip: clip,
                    isProcessing: checkoutInFlight,
                    onCancel: { showCheckout = false },
                    onConfirm: { Task { await performCheckout() } }
                )
                .presentationDetents([.medium])
            }
        }
    }

    private var reelsFeed: some View {
        GeometryReader { proxy in
            ScrollView(.vertical) {
                LazyVStack(spacing: 0) {
                    ForEach(clips) { clip in
                        reelPage(for: clip)
                            .frame(width: proxy.size.width, height: proxy.size.height)
                            .id(clip.id)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $selectedClipID)
            .onAppear {
                if selectedClipID == nil {
                    selectedClipID = clips.first?.id
                }
            }
        }
        .ignoresSafeArea(edges: [.top, .bottom])
    }

    private var topHUD: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                ClipStakesInfoChip(title: "LIVE REVIEWS", icon: "bolt.fill", tint: ClipStakesPalette.neonOrange)
                ClipStakesInfoChip(title: "RANKED", icon: "chart.line.uptrend.xyaxis", tint: ClipStakesPalette.mint)

                Spacer()

                if !clips.isEmpty {
                    Text("\(currentIndex)/\(clips.count)")
                        .font(.system(size: 12, weight: .black, design: .monospaced))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .clipStakesGlassCard(cornerRadius: 999)
                }
            }

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(product.name.uppercased())
                        .font(.system(size: 16, weight: .black, design: .serif))
                        .foregroundStyle(.white)
                    Text("Swipe up for more customer clips")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.76))
                }
                Spacer()
            }

            if let compactCatalogStatus {
                HStack {
                    Label(compactCatalogStatus, systemImage: "shippingbox.fill")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.74))
                        .lineLimit(1)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .clipStakesGlassCard(cornerRadius: 999)
                    Spacer()
                }
            }

            if let errorMessage {
                HStack {
                    Text(errorMessage)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(ClipStakesPalette.neonOrange)
                    Spacer()
                }
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.top, 86)
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private var bottomOverlay: some View {
        if checkoutOutcome != nil || (!isLoading && !clips.isEmpty) {
            VStack(spacing: 10) {
                if let outcome = checkoutOutcome {
                    receiptPanel(outcome: outcome)
                }

                if !isLoading && !clips.isEmpty {
                    buyBar
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 8)
            .background(
                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.42)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }

    private var buyBar: some View {
        Button {
            showCheckout = true
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(ClipStakesPalette.primaryGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.24), lineWidth: 1)
                    )
                    .shadow(color: ClipStakesPalette.neonPink.opacity(pulseCTA ? 0.42 : 0.18), radius: pulseCTA ? 22 : 10)

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("BUY NOW")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .tracking(1.0)
                            .foregroundStyle(.white.opacity(0.84))

                        Text(product.formattedPrice)
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundStyle(.white)

                        if let currentClip {
                            Text("\(currentClip.conversions) conversions • \(currentClip.createdAt.clipStakesRelativeDescription())")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                    Spacer()
                    Image(systemName: "cart.badge.plus")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 18)
            }
            .frame(height: 84)
        }
        .buttonStyle(.plain)
        .disabled(currentClip == nil)
        .opacity(currentClip == nil ? 0.5 : 1)
        .padding(12)
        .clipStakesGlassCard(cornerRadius: 20)
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(ClipStakesPalette.neonPink)
                .scaleEffect(1.4)

            Text("PULLING LIVE CLIPS")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "video.slash.fill")
                .font(.system(size: 40, weight: .black))
                .foregroundStyle(.white.opacity(0.65))

            Text("NO CLIPS YET")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Text("Be first to create social proof for \(product.name). Stake a 5–15 second clip and unlock instant rewards.")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.78))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .padding(.bottom, 120)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func reelPage(for clip: ClipStakesClip) -> some View {
        ZStack {
            LinearGradient(
                colors: gradientColors(for: clip),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            if let imageURL = clip.product.imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .opacity(0.35)
                            .blur(radius: 5)
                    default:
                        EmptyView()
                    }
                }
                .clipped()
            }

            LinearGradient(
                colors: [Color.black.opacity(0.32), Color.black.opacity(0.0), Color.black.opacity(0.56)],
                startPoint: .top,
                endPoint: .bottom
            )

            Image(systemName: "play.circle.fill")
                .font(.system(size: 62, weight: .bold))
                .foregroundStyle(.white.opacity(0.84))

            HStack {
                Spacer()
                VStack(spacing: 10) {
                    railMetric(value: "\(clip.conversions)", icon: "flame.fill", tint: ClipStakesPalette.neonOrange)
                    railMetric(value: "\(clip.durationSeconds)s", icon: "timer", tint: ClipStakesPalette.mint)
                    railMetric(value: "#\(clipRank(clip))", icon: "list.number", tint: .white)
                }
                .padding(.trailing, 12)
                .padding(.bottom, 174)
            }

            positionedCaption(for: clip)
                .padding(.horizontal, 16)
                .padding(.top, 120)
                .padding(.bottom, 244)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func railMetric(value: String, icon: String, tint: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
            Text(value)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .clipStakesGlassCard(cornerRadius: 14)
    }

    @ViewBuilder
    private func positionedCaption(for clip: ClipStakesClip) -> some View {
        if let text = clip.textOverlay, !text.isEmpty {
            let caption = Text(text.uppercased())
                .font(.system(size: 27, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.5), radius: 6)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )

            switch clip.textPosition {
            case .top:
                VStack {
                    caption
                    Spacer(minLength: 0)
                }
            case .center:
                VStack {
                    Spacer(minLength: 0)
                    caption
                    Spacer(minLength: 0)
                }
            case .bottom:
                VStack {
                    Spacer(minLength: 0)
                    caption
                }
            }
        } else {
            VStack {
                Spacer(minLength: 0)
                Text("\(clip.product.name) • Real buyer take")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.78))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func clipRank(_ clip: ClipStakesClip) -> Int {
        (clips.firstIndex(where: { $0.id == clip.id }) ?? 0) + 1
    }

    private func receiptPanel(outcome: ClipStakesCheckoutOutcome) -> some View {
        let creatorURL = "clip.clipstakes.app/c/\(outcome.receiptID)"

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("ORDER CONFIRMED")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(ClipStakesPalette.mint)
                Spacer()
                Text(outcome.orderID)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.75))
            }

            HStack(spacing: 8) {
                Text(creatorURL)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 10))

                Button(copiedReceiptURL ? "Copied" : "Copy") {
                    Task { @MainActor in
                        ClipStakesClipboard.copy(creatorURL)
                        copiedReceiptURL = true
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(ClipStakesPalette.neonBlue)
            }

            if let conversion = outcome.conversion {
                Text(conversion.pushSent
                     ? "Bonus push simulated inside 8-hour window."
                     : (conversion.withinPushWindow
                        ? "Bonus created, no creator token available."
                        : "Bonus created outside push window."))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.74))
            }
        }
        .padding(12)
        .clipStakesGlassCard(cornerRadius: 18)
    }

    private func gradientColors(for clip: ClipStakesClip) -> [Color] {
        let seed = abs(clip.id.hashValue)
        let index = seed % 4

        switch index {
        case 0:
            return [Color(red: 0.95, green: 0.27, blue: 0.52), Color(red: 0.99, green: 0.56, blue: 0.27)]
        case 1:
            return [Color(red: 0.39, green: 0.44, blue: 0.97), Color(red: 0.23, green: 0.78, blue: 0.93)]
        case 2:
            return [Color(red: 0.16, green: 0.73, blue: 0.47), Color(red: 0.11, green: 0.43, blue: 0.66)]
        default:
            return [Color(red: 0.82, green: 0.31, blue: 0.88), Color(red: 0.29, green: 0.26, blue: 0.86)]
        }
    }

    private func loadClips() async {
        isLoading = true
        errorMessage = nil

        let previousSelectedID = selectedClipID

        let catalogResult = await ClipStakesShopifyPublicCatalogService.shared.loadCatalog(
            storeDomainOverride: storeDomainOverride
        )

        catalogStatusMessage = catalogResult.message

        let loaded = await ClipStakesMockBackend.shared.getClips(productId: productID)
        clips = loaded

        if let previousSelectedID,
           loaded.contains(where: { $0.id == previousSelectedID }) {
            selectedClipID = previousSelectedID
        } else {
            selectedClipID = loaded.first?.id
        }

        isLoading = false
    }

    private func performCheckout() async {
        guard let currentClip else { return }

        checkoutInFlight = true
        defer { checkoutInFlight = false }

        do {
            let outcome = try await ClipStakesMockBackend.shared.performViewerCheckout(
                productId: productID,
                clipId: currentClip.id
            )

            await MainActor.run {
                checkoutOutcome = outcome
                copiedReceiptURL = false
                showCheckout = false
            }

            await loadClips()
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showCheckout = false
            }
        }
    }
}

private struct ClipStakesViewerCheckoutSheet: View {
    let product: ClipStakesProduct
    let clip: ClipStakesClip
    let isProcessing: Bool
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                VStack(spacing: 8) {
                    Text("CHECKOUT PREVIEW")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                    Text("Simulated ClipKit checkout with conversion attribution.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 10) {
                    checkoutRow(label: "Product", value: product.name)
                    checkoutRow(label: "Price", value: product.formattedPrice)
                    checkoutRow(label: "Clip ID", value: String(clip.id.prefix(8)) + "…")
                    checkoutRow(label: "Conversions", value: "\(clip.conversions)")
                }
                .padding(14)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))

                Spacer(minLength: 6)

                if isProcessing {
                    ProgressView("Processing Apple Pay...")
                }

                HStack(spacing: 10) {
                    Button("Cancel", action: onCancel)
                        .buttonStyle(.bordered)

                    Button("Pay Now", action: onConfirm)
                        .buttonStyle(.borderedProminent)
                        .disabled(isProcessing)
                }
            }
            .padding(20)
        }
    }

    private func checkoutRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(.primary)
        }
    }
}
