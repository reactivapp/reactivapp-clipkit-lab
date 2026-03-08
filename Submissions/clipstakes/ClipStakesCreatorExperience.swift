import SwiftUI
import UIKit

struct ClipStakesCreatorExperience: ClipExperience {
    static let urlPattern = "clip.clipstakes.app/c/:receiptId"
    static let clipName = "ClipStakes Creator"
    static let clipDescription = "Create a clip, get $5 now, and grow wallet balance on every conversion."
    static let teamName = "ClipStakes"
    static let touchpoint: JourneyTouchpoint = .purchase
    static let invocationSource: InvocationSource = .qrCode

    enum CreatorStep {
        case loading
        case selectProduct
        case record
        case aiValidating
        case addText
        case confirm
        case success
        case blocked
        case failure
    }

    let context: ClipContext

    @State private var step: CreatorStep = .loading
    @State private var products: [ClipStakesProduct] = []
    @State private var selectedProduct: ClipStakesProduct?
    @State private var recordedVideo: ClipStakesRecordedVideo?
    @State private var textOverlay = ""
    @State private var textPosition: ClipStakesTextPosition = .bottom
    @State private var validationMessage = ""
    @State private var isUploading = false
    @State private var reward: ClipStakesCreateClipResponse?
    @State private var rewardsSnapshot: ClipStakesRewardsSnapshot?

    @State private var walletAdded = false
    @State private var showShareSheet = false
    @State private var copiedWalletCode = false

    @State private var errorMessage: String?
    @State private var walletStatusMessage: String?
    @State private var blockedStatusMessage: String?

    @State private var pulseHero = false
    @State private var pulseReward = false
    @State private var demoAliasReceiptID = ClipStakesCreatorExperience.makeDemoAliasReceiptID()

    private let deviceID = "clipstakes-device-id"

    private var receiptID: String {
        let raw = context.pathParameters["receiptId"] ?? "order_demo_hoodie"
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "order_demo_hoodie" }
        if trimmed.caseInsensitiveCompare("demo") == .orderedSame {
            return demoAliasReceiptID
        }
        return trimmed
    }

    private var storeDomainOverride: String? {
        context.queryParameters["store"]
    }

    private var apiBaseOverride: String? {
        context.queryParameters["api"] ?? context.queryParameters["api_base"]
    }

    private var apiBaseURL: URL {
        ClipStakesRemoteBackend.resolveAPIBaseURL(override: apiBaseOverride)
    }

    private var firstProductIDForViewer: String {
        if let first = products.first?.id {
            return first
        }

        if receiptID.contains("hoodie") {
            return "prod_hoodie"
        }
        if receiptID.contains("vinyl") {
            return "prod_vinyl"
        }
        return "prod_hoodie"
    }

    private var trimmedTextOverlay: String {
        textOverlay.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var stepTimeline: [(CreatorStep, String)] {
        [
            (.selectProduct, "Product"),
            (.record, "Record"),
            (.aiValidating, "AI"),
            (.addText, "Text"),
            (.confirm, "Stake"),
            (.success, "Reward"),
        ]
    }

    private var progressValue: Double {
        let total = Double(stepTimeline.count)
        let progress = Double(max(0, min(stepTimeline.count, stepOrder(step) - 1)))
        return total == 0 ? 0 : progress / total
    }

    var body: some View {
        ZStack {
            ClipStakesStageBackground()

            ScrollView {
                VStack(spacing: 12) {
                    compactHeader

                    content

                    if let errorMessage {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 11))
                            Text(errorMessage)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                        }
                        .foregroundStyle(ClipStakesPalette.neonOrange)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(ClipStakesPalette.neonOrange.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 20)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                pulseHero = true
                pulseReward = true
            }
        }
        .task(id: receiptID + "|" + (storeDomainOverride ?? "")) {
            await loadReceipt()
        }
        .sheet(isPresented: $showShareSheet) {
            ClipStakesShareSheet(items: shareItems)
        }
    }

    // MARK: - Compact Header (replaces old giant hero)

    private var compactHeader: some View {
        VStack(spacing: 7) {
            HStack(spacing: 6) {
                Image(systemName: "camera.aperture")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(ClipStakesPalette.neonPink)
                Text("CREATOR")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(ClipStakesPalette.neonPink)

                Spacer()
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.08))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(ClipStakesPalette.accentGradient)
                        .frame(width: max(8, geometry.size.width * progressValue))
                        .shadow(color: ClipStakesPalette.neonBlue.opacity(pulseHero ? 0.4 : 0.15), radius: pulseHero ? 10 : 4)
                }
            }
            .frame(height: 4)
            .animation(.easeInOut(duration: 0.4), value: progressValue)

            if let rewardsSnapshot {
                HStack {
                    Text("Wallet \(rewardsSnapshot.availableBalanceDisplay)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(ClipStakesPalette.mint)
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .clipStakesGlassCard(cornerRadius: 16)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch step {
        case .loading:
            loadingState
        case .selectProduct:
            productSelection
        case .record:
            recordingStep
        case .aiValidating:
            validatingStep
        case .addText:
            addTextStep
        case .confirm:
            confirmStep
        case .success:
            successStep
        case .blocked:
            blockedState
        case .failure:
            failureState
        }
    }

    // MARK: - Loading

    private var loadingState: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 6)
                    .frame(width: 56, height: 56)
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(ClipStakesPalette.accentGradient, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 56, height: 56)
                    .rotationEffect(.degrees(pulseHero ? 240 : -30))
            }

            Text("SYNCING RECEIPT")
                .font(.system(size: 11, weight: .black, design: .rounded))
                .tracking(1.0)
                .foregroundStyle(.white.opacity(0.7))

            Text("Checking eligible products")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.45))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .clipStakesGlassCard(cornerRadius: 18)
    }

    // MARK: - Product Selection

    private var productSelection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Select a product")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(products.count) eligible")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(ClipStakesPalette.mint)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(ClipStakesPalette.mint.opacity(0.12), in: Capsule())
            }
            .padding(.horizontal, 4)

            if products.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "shippingbox")
                        .font(.system(size: 28))
                        .foregroundStyle(.white.opacity(0.3))
                    Text("No eligible products found.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity)
                .clipStakesGlassCard(cornerRadius: 14)
            }

            ForEach(products.indices, id: \.self) { index in
                productSelectionRow(products[index])
            }
        }
    }

    private func productSelectionRow(_ product: ClipStakesProduct) -> some View {
        Button {
            beginRecording(for: product)
        } label: {
            HStack(spacing: 12) {
                productThumb(product)

                VStack(alignment: .leading, spacing: 3) {
                    Text(product.name)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    HStack(spacing: 6) {
                        Text(product.formattedPrice)
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(ClipStakesPalette.mint)
                        Text("STAKE-READY")
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .tracking(0.6)
                            .foregroundStyle(.black)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(productAccent(product), in: Capsule())
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .padding(12)
            .clipStakesGlassCard(cornerRadius: 14)
        }
        .buttonStyle(.plain)
    }

    private func beginRecording(for product: ClipStakesProduct) {
        selectedProduct = product
        recordedVideo = nil
        textOverlay = ""
        textPosition = .bottom
        step = .record
    }

    // MARK: - Recording

    private var recordingStep: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                if let selectedProduct {
                    productThumb(selectedProduct)
                        .frame(width: 34, height: 34)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Recording")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                        Text(selectedProduct.name)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Button("Change Product") {
                    step = .selectProduct
                }
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.white.opacity(0.14), in: Capsule())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .clipStakesGlassCard(cornerRadius: 12)

            ClipStakesVideoRecorder(minDuration: 5, maxDuration: 15) { result in
                recordedVideo = result
                step = .aiValidating
                Task { await runValidation() }
            }
            .frame(minHeight: max(420, UIScreen.main.bounds.height * 0.62))
            .clipStakesGlassCard(cornerRadius: 18)

            HStack(spacing: 8) {
                Text("Record one clean take, then tap Stop.")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
                Spacer()
            }
            .padding(.horizontal, 2)

            if recordedVideo != nil {
                Button("Use Last Recording") {
                    step = .aiValidating
                    Task { await runValidation() }
                }
                .buttonStyle(ClipStakesPrimaryButtonStyle())
            }
        }
        .padding(.bottom, 6)
    }

    // MARK: - Validating

    private var validatingStep: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(ClipStakesPalette.neonBlue.opacity(0.15), lineWidth: 6)
                    .frame(width: 56, height: 56)
                Circle()
                    .trim(from: 0, to: 0.6)
                    .stroke(ClipStakesPalette.accentGradient, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 56, height: 56)
                    .rotationEffect(.degrees(pulseHero ? 210 : -70))
                Image(systemName: "brain")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
            }

            Text("AI REVIEW")
                .font(.system(size: 11, weight: .black, design: .rounded))
                .tracking(1.0)
                .foregroundStyle(.white.opacity(0.8))

            Text(validationMessage.isEmpty ? "Checking visibility, framing, and content" : validationMessage)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .clipStakesGlassCard(cornerRadius: 18)
    }

    // MARK: - Add Text

    private var addTextStep: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Add overlay text")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
                Text("Optional")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.4))
            }

            VStack(spacing: 10) {
                TextField("OBSESSED", text: $textOverlay)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(11)
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                    )

                Picker("Text Position", selection: $textPosition) {
                    ForEach(ClipStakesTextPosition.allCases) { position in
                        Text(position.rawValue.capitalized)
                            .tag(position)
                    }
                }
                .pickerStyle(.segmented)

                textPreviewCard
            }

            HStack(spacing: 8) {
                Button("Back") {
                    withAnimation(.easeOut(duration: 0.2)) { step = .record }
                }
                .buttonStyle(ClipStakesSecondaryButtonStyle())

                Button("Continue") {
                    withAnimation(.easeOut(duration: 0.25)) { step = .confirm }
                }
                .buttonStyle(ClipStakesPrimaryButtonStyle())
            }
        }
        .padding(14)
        .clipStakesGlassCard(cornerRadius: 18)
    }

    private var textPreviewCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [Color.black.opacity(0.5), ClipStakesPalette.neonBlue.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 110)

            VStack {
                switch textPosition {
                case .top:
                    overlayPreviewText
                    Spacer(minLength: 0)
                case .center:
                    Spacer(minLength: 0)
                    overlayPreviewText
                    Spacer(minLength: 0)
                case .bottom:
                    Spacer(minLength: 0)
                    overlayPreviewText
                }
            }
            .padding(10)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
        )
    }

    private var overlayPreviewText: some View {
        Text(trimmedTextOverlay.isEmpty ? "YOUR OVERLAY" : trimmedTextOverlay.uppercased())
            .font(.system(size: 15, weight: .black, design: .rounded))
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.45), radius: 4)
            .lineLimit(2)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Confirm

    private var confirmStep: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Final Review")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
            }

            VStack(spacing: 1) {
                confirmRow(label: "Product", value: selectedProduct?.name ?? "-")
                confirmRow(label: "Duration", value: "\(recordedVideo?.durationSeconds ?? 0)s")
                confirmRow(label: "Overlay", value: trimmedTextOverlay.isEmpty ? "None" : trimmedTextOverlay)
                confirmRow(label: "Position", value: textPosition.rawValue.capitalized)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Reward preview
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("INSTANT REWARD")
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .tracking(0.8)
                        .foregroundStyle(.white.opacity(0.6))
                    Text("$5 Coupon")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }
                Spacer()
                Image(systemName: "ticket.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(ClipStakesPalette.neonOrange)
            }
            .padding(12)
            .background(
                LinearGradient(
                    colors: [ClipStakesPalette.neonPink.opacity(0.25), ClipStakesPalette.neonOrange.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
            )

            if isUploading {
                HStack(spacing: 8) {
                    ProgressView()
                        .tint(ClipStakesPalette.neonPink)
                        .scaleEffect(0.8)
                    Text("Uploading + minting reward...")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.vertical, 4)
            }

            HStack(spacing: 8) {
                Button("Back") {
                    withAnimation(.easeOut(duration: 0.2)) { step = .addText }
                }
                .buttonStyle(ClipStakesSecondaryButtonStyle())
                .disabled(isUploading)

                Button("Stake Clip") {
                    Task { await uploadAndStake() }
                }
                .buttonStyle(ClipStakesPrimaryButtonStyle(disabled: isUploading))
                .disabled(isUploading)
            }
        }
        .padding(14)
        .clipStakesGlassCard(cornerRadius: 18)
    }

    // MARK: - Success

    private var successStep: some View {
        VStack(spacing: 14) {
            if let reward {
                let displayedBalance = rewardsSnapshot?.availableBalanceDisplay ?? reward.availableBalanceDisplay
                let walletCode = rewardsSnapshot?.walletCode ?? reward.walletCode
                let passURL = rewardsSnapshot?.passURL ?? reward.passURL
                let transactions = rewardsSnapshot?.transactions ?? []

                // Header
                VStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(ClipStakesPalette.mint)

                    Text("CLIP IS LIVE")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .tracking(1.2)
                        .foregroundStyle(.white.opacity(0.6))
                }

                // Reward card
                VStack(spacing: 10) {
                    Text("+\(reward.instantCreditDisplay)")
                        .font(.system(size: 44, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text("ADDED TO YOUR WALLET BALANCE")
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .tracking(1.2)
                        .foregroundStyle(.white.opacity(0.8))

                    HStack(spacing: 8) {
                        Text(displayedBalance)
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)

                        Button(copiedWalletCode ? "Copied" : "Copy Wallet Code") {
                            Task { @MainActor in
                                ClipStakesClipboard.copy(walletCode)
                                copiedWalletCode = true
                            }
                        }
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.15), in: Capsule())
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(
                    LinearGradient(
                        colors: [ClipStakesPalette.neonPink, ClipStakesPalette.neonBlue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 18)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                )
                .shadow(color: ClipStakesPalette.neonPink.opacity(pulseReward ? 0.35 : 0.15), radius: pulseReward ? 20 : 10, y: 6)

                // Actions
                VStack(spacing: 8) {
                    Button {
                        Task { @MainActor in
                            let fallbackPassURL = ClipStakesRemoteBackend.fallbackWalletPassURL(
                                apiBaseURL: apiBaseURL,
                                walletCode: walletCode
                            )
                            let passURLReachable = await ClipStakesURLLauncher.isReachable(passURL)
                            if passURLReachable, await ClipStakesURLLauncher.open(passURL) {
                                walletAdded = true
                                walletStatusMessage = "Wallet pass opened."
                                return
                            }

                            if passURL != fallbackPassURL {
                                let fallbackReachable = await ClipStakesURLLauncher.isReachable(fallbackPassURL)
                                if fallbackReachable, await ClipStakesURLLauncher.open(fallbackPassURL) {
                                    walletAdded = true
                                    walletStatusMessage = "Wallet pass opened."
                                    return
                                }
                            }

                            ClipStakesClipboard.copy(walletCode)
                            walletStatusMessage = "Wallet pass link is unavailable. Wallet code copied."
                        }
                    } label: {
                        Label(
                            walletAdded ? "Wallet Pass Ready" : "Add to Apple Wallet",
                            systemImage: walletAdded ? "checkmark.circle.fill" : "wallet.pass"
                        )
                    }
                    .buttonStyle(ClipStakesPrimaryButtonStyle())

                    Button {
                        Task { await openViewerForSuccess(clipID: reward.clipID) }
                    } label: {
                        Label("Watch My Clip", systemImage: "play.rectangle.fill")
                    }
                    .buttonStyle(ClipStakesSecondaryButtonStyle())

                    Button {
                        showShareSheet = true
                    } label: {
                        Label("Share to Stories", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(ClipStakesSecondaryButtonStyle())

                    Button("Refresh Balance") {
                        Task { await refreshRewards() }
                    }
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(ClipStakesPalette.mint)
                    .padding(.top, 2)
                }

                if let walletStatusMessage {
                    Text(walletStatusMessage)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                }

                if !transactions.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recent Earnings")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.82))

                        ForEach(transactions.prefix(3)) { item in
                            HStack(spacing: 8) {
                                Image(systemName: item.kind == .conversion ? "cart.fill.badge.plus" : "video.badge.plus")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(ClipStakesPalette.mint)
                                Text(item.kind == .conversion ? "Conversion reward" : "Clip published")
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.74))
                                Spacer()
                                Text("+\(item.amountDisplay)")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .clipStakesGlassCard(cornerRadius: 12)
                }
            }
        }
        .padding(14)
        .clipStakesGlassCard(cornerRadius: 18)
    }

    // MARK: - Blocked / Failure

    private var blockedState: some View {
        VStack(spacing: 10) {
            Image(systemName: "lock.trianglebadge.exclamationmark")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(ClipStakesPalette.neonOrange)

            Text("Receipt Already Used")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text(errorMessage ?? "This receipt already created a clip.")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)

            if let rewardsSnapshot {
                Text("Wallet balance: \(rewardsSnapshot.availableBalanceDisplay)")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(ClipStakesPalette.mint)
            }

            VStack(spacing: 8) {
                Button("View Existing Clips") {
                    Task { await openViewerForBlockedReceipt() }
                }
                .buttonStyle(ClipStakesPrimaryButtonStyle())

                Button("Use Fresh Demo Receipt") {
                    Task { await openFreshDemoReceipt() }
                }
                .buttonStyle(ClipStakesSecondaryButtonStyle())
            }
            .padding(.horizontal, 18)

            if let blockedStatusMessage {
                Text(blockedStatusMessage)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .clipStakesGlassCard(cornerRadius: 18)
    }

    private var failureState: some View {
        VStack(spacing: 10) {
            Image(systemName: "xmark.octagon.fill")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(ClipStakesPalette.neonPink)

            Text("Could Not Load Receipt")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text(errorMessage ?? "Try another receipt URL.")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)

            Button("Retry") {
                Task { await loadReceipt() }
            }
            .buttonStyle(ClipStakesPrimaryButtonStyle())
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 14)
        .clipStakesGlassCard(cornerRadius: 18)
    }

    // MARK: - Helpers

    private func confirmRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.04))
    }

    private func productThumb(_ product: ClipStakesProduct) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.08))

            if let imageURL = product.imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        Image(systemName: product.systemImage)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
            } else {
                Image(systemName: product.systemImage)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .frame(width: 40, height: 40)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func productAccent(_ product: ClipStakesProduct) -> LinearGradient {
        let seed = abs(product.id.hashValue) % 3
        switch seed {
        case 0:
            return LinearGradient(colors: [ClipStakesPalette.neonBlue, ClipStakesPalette.mint], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 1:
            return LinearGradient(colors: [ClipStakesPalette.neonOrange, ClipStakesPalette.neonPink], startPoint: .topLeading, endPoint: .bottomTrailing)
        default:
            return LinearGradient(colors: [ClipStakesPalette.mint, ClipStakesPalette.neonBlue], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private func stepOrder(_ value: CreatorStep) -> Int {
        switch value {
        case .loading: return 0
        case .selectProduct: return 1
        case .record: return 2
        case .aiValidating: return 3
        case .addText: return 4
        case .confirm: return 5
        case .success: return 6
        case .blocked: return 7
        case .failure: return 8
        }
    }

    private var shareItems: [Any] {
        guard let reward else {
            return ["I created a ClipStakes video and unlocked rewards."]
        }

        return [
            "I just staked a clip on CLIPSTAKES and grew my wallet balance.",
            "Wallet code: \(reward.walletCode)"
        ]
    }

    // MARK: - Backend

    private func loadReceipt() async {
        await MainActor.run {
            step = .loading
            errorMessage = nil
            blockedStatusMessage = nil
        }

        await refreshRewards()

        _ = await ClipStakesShopifyPublicCatalogService.shared.loadCatalog(
            storeDomainOverride: storeDomainOverride
        )

        do {
            let receipt = try await getReceipt()
            await MainActor.run {
                products = receipt.products
                step = .selectProduct
            }
        } catch {
            let fallbackProducts = await productsForUsedReceipt()
            await MainActor.run {
                errorMessage = error.localizedDescription
                if let backendError = error as? ClipStakesBackendError, backendError == .receiptAlreadyUsed {
                    if !fallbackProducts.isEmpty {
                        products = fallbackProducts
                    }
                    step = .blocked
                } else {
                    step = .failure
                }
            }
        }
    }

    private func runValidation() async {
        guard let recordedVideo else {
            await MainActor.run {
                errorMessage = "Record a clip before validation."
                step = .record
            }
            return
        }

        await MainActor.run {
            validationMessage = ""
        }

        let result = await ClipStakesAIValidator.validate(
            videoURL: recordedVideo.fileURL,
            expectedProductId: selectedProduct?.id ?? "",
            durationSeconds: recordedVideo.durationSeconds
        )

        try? await Task.sleep(nanoseconds: 450_000_000)

        await MainActor.run {
            validationMessage = result.message
            if result.isValid {
                step = .addText
                errorMessage = nil
            } else {
                errorMessage = result.message
                step = .record
            }
        }
    }

    private func uploadAndStake() async {
        guard let selectedProduct, let recordedVideo else { return }

        await MainActor.run {
            isUploading = true
            errorMessage = nil
        }

        defer {
            Task { @MainActor in
                isUploading = false
            }
        }

        do {
            let upload = try await createUploadURL(productId: selectedProduct.id)

            var preparedVideoURL = recordedVideo.fileURL
            if let sourceURL = preparedVideoURL, !trimmedTextOverlay.isEmpty {
                let compositedURL = await ClipStakesVideoCompositor.addText(
                    to: sourceURL,
                    text: trimmedTextOverlay,
                    position: textPosition
                )
                preparedVideoURL = compositedURL ?? sourceURL
            }

            let publishedVideoURL = await ClipStakesVideoStorage.shared.publishVideo(
                sourceURL: preparedVideoURL,
                upload: upload
            )

            let response = try await createClip(
                receiptId: receiptID,
                deviceID: deviceID,
                productId: selectedProduct.id,
                videoURL: publishedVideoURL,
                textOverlay: trimmedTextOverlay.isEmpty ? nil : trimmedTextOverlay,
                textPosition: textPosition,
                durationSeconds: recordedVideo.durationSeconds
            )

            await MainActor.run {
                reward = response
                copiedWalletCode = false
                walletAdded = false
                walletStatusMessage = nil
                step = .success
            }

            await refreshRewards()
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                step = .confirm
            }
        }
    }

    private func refreshRewards() async {
        guard let snapshot = await getRewards() else { return }
        await MainActor.run {
            rewardsSnapshot = snapshot
        }
    }

    private func getReceipt() async throws -> ClipStakesReceipt {
        if receiptID.hasPrefix("order_demo_hoodie_demo_") {
            return await ClipStakesMockBackend.shared.ensureDemoReceipt(receiptId: receiptID)
        }

        if receiptID.hasPrefix("order_demo_") {
            return try await ClipStakesMockBackend.shared.getReceipt(receiptId: receiptID)
        }

        do {
            return try await ClipStakesRemoteBackend.getReceipt(
                receiptId: receiptID,
                apiBaseURL: apiBaseURL,
                deviceID: deviceID
            )
        } catch let error as ClipStakesBackendError where error == .receiptNotFound {
            if receiptID.hasPrefix("order_demo_") {
                return try await ClipStakesMockBackend.shared.getReceipt(receiptId: receiptID)
            }
            throw error
        } catch let error as ClipStakesRemoteBackendError where error.isConnectivityIssue {
            return try await ClipStakesMockBackend.shared.getReceipt(receiptId: receiptID)
        }
    }

    private func createUploadURL(productId: String) async throws -> ClipStakesUploadURLResponse {
        if receiptID.hasPrefix("order_demo_") {
            return await ClipStakesMockBackend.shared.createUploadURL(
                receiptId: receiptID,
                productId: productId
            )
        }

        do {
            return try await ClipStakesRemoteBackend.createUploadURL(
                receiptId: receiptID,
                productId: productId,
                apiBaseURL: apiBaseURL,
                deviceID: deviceID
            )
        } catch let error as ClipStakesRemoteBackendError where error.isConnectivityIssue {
            return await ClipStakesMockBackend.shared.createUploadURL(
                receiptId: receiptID,
                productId: productId
            )
        }
    }

    private func createClip(
        receiptId: String,
        deviceID: String,
        productId: String,
        videoURL: URL,
        textOverlay: String?,
        textPosition: ClipStakesTextPosition,
        durationSeconds: Int
    ) async throws -> ClipStakesCreateClipResponse {
        if receiptId.hasPrefix("order_demo_") {
            return try await ClipStakesMockBackend.shared.createClip(
                receiptId: receiptId,
                deviceID: deviceID,
                productId: productId,
                videoURL: videoURL,
                textOverlay: textOverlay,
                textPosition: textPosition,
                durationSeconds: durationSeconds
            )
        }

        do {
            return try await ClipStakesRemoteBackend.createClip(
                receiptId: receiptId,
                deviceID: deviceID,
                productId: productId,
                videoURL: videoURL,
                textOverlay: textOverlay,
                textPosition: textPosition,
                durationSeconds: durationSeconds,
                apiBaseURL: apiBaseURL
            )
        } catch let error as ClipStakesRemoteBackendError where error.isConnectivityIssue {
            return try await ClipStakesMockBackend.shared.createClip(
                receiptId: receiptId,
                deviceID: deviceID,
                productId: productId,
                videoURL: videoURL,
                textOverlay: textOverlay,
                textPosition: textPosition,
                durationSeconds: durationSeconds
            )
        }
    }

    private func getRewards() async -> ClipStakesRewardsSnapshot? {
        do {
            return try await ClipStakesRemoteBackend.getRewards(
                deviceID: deviceID,
                apiBaseURL: apiBaseURL
            )
        } catch let error as ClipStakesRemoteBackendError where error.isConnectivityIssue {
            return await ClipStakesMockBackend.shared.getRewards(deviceID: deviceID)
        } catch {
            return nil
        }
    }

    private func productsForUsedReceipt() async -> [ClipStakesProduct] {
        if receiptID.hasPrefix("order_demo_") {
            if let receipt = try? await ClipStakesMockBackend.shared.getReceiptIncludingUsed(receiptId: receiptID) {
                return receipt.products
            }
            return []
        }

        if let receipt = try? await ClipStakesRemoteBackend.getReceipt(
            receiptId: receiptID,
            apiBaseURL: apiBaseURL,
            deviceID: deviceID
        ) {
            return receipt.products
        }

        return []
    }

    @MainActor
    private func viewerLink(for productID: String, clipID: String?) -> URL {
        var components = URLComponents(string: "https://clip.clipstakes.app/v/\(productID)")!
        if let clipID, !clipID.isEmpty {
            components.queryItems = [URLQueryItem(name: "clip", value: clipID)]
        }
        return components.url!
    }

    @MainActor
    private func creatorDemoLink() -> URL {
        URL(string: "https://clip.clipstakes.app/c/demo")!
    }

    private func openViewerForBlockedReceipt() async {
        let target = await MainActor.run { viewerLink(for: firstProductIDForViewer, clipID: nil) }
        if await ClipStakesURLLauncher.open(target) {
            await MainActor.run {
                blockedStatusMessage = "Opened viewer."
            }
            return
        }

        await MainActor.run {
            ClipStakesClipboard.copy(target.absoluteString)
            blockedStatusMessage = "Could not open viewer directly. Link copied."
        }
    }

    private func openViewerForSuccess(clipID: String) async {
        let productID = selectedProduct?.id ?? firstProductIDForViewer
        let target = await MainActor.run { viewerLink(for: productID, clipID: clipID) }

        if await ClipStakesURLLauncher.open(target) {
            await MainActor.run {
                walletStatusMessage = "Opened your clip in viewer."
            }
            return
        }

        await MainActor.run {
            ClipStakesClipboard.copy(target.absoluteString)
            walletStatusMessage = "Could not open viewer directly. Link copied."
        }
    }

    private func openFreshDemoReceipt() async {
        let target = await MainActor.run { creatorDemoLink() }
        if await ClipStakesURLLauncher.open(target) {
            await MainActor.run {
                blockedStatusMessage = "Opened fresh demo receipt."
            }
            return
        }

        await MainActor.run {
            ClipStakesClipboard.copy(target.absoluteString)
            blockedStatusMessage = "Could not open demo link directly. Link copied."
        }
    }

    nonisolated private static func makeDemoAliasReceiptID() -> String {
        let token = String(UUID().uuidString.prefix(8)).lowercased()
        return "order_demo_hoodie_demo_\(token)"
    }
}
