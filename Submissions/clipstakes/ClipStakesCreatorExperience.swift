import SwiftUI
import UIKit

struct ClipStakesCreatorExperience: ClipExperience {
    static let urlPattern = "clip.clipstakes.app/c/:receiptId"
    static let clipName = "ClipStakes Creator"
    static let clipDescription = "Create a clip, get $5 now, and earn bonus when it converts."
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
    @State private var createdClipID: String?
    @State private var bonusEvent: ClipStakesNotificationEvent?

    @State private var walletAdded = false
    @State private var showShareSheet = false
    @State private var copiedCoupon = false

    @State private var errorMessage: String?
    @State private var catalogStatusMessage: String?

    @State private var pulseHero = false
    @State private var pulseReward = false

    private let deviceToken = "clipstakes-device-token"

    private var receiptID: String {
        context.pathParameters["receiptId"] ?? "order_demo_hoodie"
    }

    private var storeDomainOverride: String? {
        context.queryParameters["store"]
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
                VStack(spacing: 16) {
                    hero

                    if let catalogStatusMessage {
                        Text(catalogStatusMessage)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.72))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }

                    content

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(ClipStakesPalette.neonOrange)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 18)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 14)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
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

    private var hero: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ClipStakesInfoChip(title: "CREATOR FLOW", icon: "camera.aperture", tint: ClipStakesPalette.neonPink)
                Spacer()
                Text("Receipt: \(receiptID)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.75))
                    .lineLimit(1)
            }

            Text("TURN RECEIPT\nINTO REACH")
                .font(.system(size: 34, weight: .black, design: .serif))
                .foregroundStyle(.white)
                .lineSpacing(-3)

            Text("One real clip. One instant reward. Bonus unlocks on first conversion.")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.78))

            VStack(spacing: 10) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.12))
                        RoundedRectangle(cornerRadius: 8)
                            .fill(ClipStakesPalette.accentGradient)
                            .frame(width: max(14, geometry.size.width * progressValue))
                            .shadow(color: ClipStakesPalette.neonBlue.opacity(pulseHero ? 0.5 : 0.2), radius: pulseHero ? 16 : 8)
                    }
                }
                .frame(height: 8)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(stepTimeline, id: \.1) { item in
                            ClipStakesStepPill(label: item.1, isActive: isStepActive(item.0))
                        }
                    }
                }
            }
        }
        .padding(18)
        .clipStakesGlassCard(cornerRadius: 24)
    }

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

    private var loadingState: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 10)
                    .frame(width: 86, height: 86)
                Circle()
                    .trim(from: 0, to: 0.72)
                    .stroke(ClipStakesPalette.primaryGradient, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .frame(width: 86, height: 86)
                    .rotationEffect(.degrees(pulseHero ? 240 : -30))
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.15)
            }

            Text("SYNCING RECEIPT")
                .font(.system(size: 13, weight: .black, design: .rounded))
                .tracking(1.0)
                .foregroundStyle(.white.opacity(0.8))

            Text("Checking eligible products and stake status")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.68))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .clipStakesGlassCard(cornerRadius: 22)
    }

    private var productSelection: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Pick one product from this receipt")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.75))
                Spacer()
                Text("\(products.count) eligible")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(ClipStakesPalette.mint)
            }

            if products.isEmpty {
                Text("No eligible products found in this receipt.")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.75))
                    .padding(.vertical, 24)
                    .frame(maxWidth: .infinity)
                    .clipStakesGlassCard(cornerRadius: 16)
            }

            ForEach(products) { product in
                Button {
                    selectedProduct = product
                    recordedVideo = nil
                    textOverlay = ""
                    textPosition = .bottom
                    step = .record
                } label: {
                    HStack(spacing: 12) {
                        productThumb(product)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(product.name)
                                .font(.system(size: 17, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                            HStack(spacing: 6) {
                                Text(product.formattedPrice)
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                                    .foregroundStyle(ClipStakesPalette.mint)
                                Text("stake-ready")
                                    .font(.system(size: 11, weight: .black, design: .rounded))
                                    .tracking(0.8)
                                    .foregroundStyle(.black)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(productAccent(product), in: Capsule())
                            }
                        }

                        Spacer()

                        Image(systemName: "arrow.up.right.circle.fill")
                            .font(.system(size: 21, weight: .bold))
                            .foregroundStyle(ClipStakesPalette.neonBlue)
                    }
                    .padding(14)
                    .background(
                        LinearGradient(
                            colors: [Color.white.opacity(0.12), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipStakesGlassCard(cornerRadius: 18)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var recordingStep: some View {
        VStack(spacing: 14) {
            if let selectedProduct {
                HStack(spacing: 10) {
                    productThumb(selectedProduct)
                        .frame(width: 52, height: 52)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Recording clip for")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .tracking(1.0)
                            .foregroundStyle(.white.opacity(0.72))
                        Text(selectedProduct.name.uppercased())
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                }
                .padding(12)
                .clipStakesGlassCard(cornerRadius: 16)
            }

            ClipStakesVideoRecorder(minDuration: 5, maxDuration: 15) { result in
                recordedVideo = result
                step = .aiValidating
                Task { await runValidation() }
            }
            .clipStakesGlassCard(cornerRadius: 24)

            HStack(spacing: 8) {
                ClipStakesInfoChip(title: "5-15 sec", icon: "timer", tint: ClipStakesPalette.mint)
                ClipStakesInfoChip(title: "Vertical", icon: "rectangle.portrait", tint: ClipStakesPalette.neonBlue)
                ClipStakesInfoChip(title: "One take", icon: "bolt.fill", tint: ClipStakesPalette.neonOrange)
                Spacer()
            }

            HStack(spacing: 10) {
                Button("Back") {
                    step = .selectProduct
                }
                .buttonStyle(ClipStakesSecondaryButtonStyle())

                if recordedVideo != nil {
                    Button("Use Last Recording") {
                        step = .aiValidating
                        Task { await runValidation() }
                    }
                    .buttonStyle(ClipStakesPrimaryButtonStyle())
                }
            }
        }
    }

    private var validatingStep: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(ClipStakesPalette.neonBlue.opacity(0.25), lineWidth: 10)
                    .frame(width: 88, height: 88)
                Circle()
                    .trim(from: 0, to: 0.58)
                    .stroke(ClipStakesPalette.accentGradient, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .frame(width: 88, height: 88)
                    .rotationEffect(.degrees(pulseHero ? 210 : -70))
                ProgressView()
                    .scaleEffect(1.45)
                    .tint(.white)
            }

            Text("ON-DEVICE AI REVIEW")
                .font(.system(size: 14, weight: .black, design: .rounded))
                .tracking(1.0)
                .foregroundStyle(.white)

            Text(validationMessage.isEmpty ? "Checking visibility, framing, and retail-safe content." : validationMessage)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.74))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .clipStakesGlassCard(cornerRadius: 22)
    }

    private var addTextStep: some View {
        VStack(spacing: 14) {
            Text("Add text energy (optional)")
                .font(.system(size: 21, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 10) {
                TextField("OBSESSED", text: $textOverlay)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))

                Picker("Text Position", selection: $textPosition) {
                    ForEach(ClipStakesTextPosition.allCases) { position in
                        Text(position.rawValue.capitalized)
                            .tag(position)
                    }
                }
                .pickerStyle(.segmented)

                textPreviewCard
            }

            HStack(spacing: 10) {
                Button("Back") {
                    step = .record
                }
                .buttonStyle(ClipStakesSecondaryButtonStyle())

                Button("Continue") {
                    step = .confirm
                }
                .buttonStyle(ClipStakesPrimaryButtonStyle())
            }
        }
        .padding(16)
        .clipStakesGlassCard(cornerRadius: 22)
    }

    private var textPreviewCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color.black.opacity(0.5), ClipStakesPalette.neonBlue.opacity(0.45)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 146)

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
            .padding(12)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }

    private var overlayPreviewText: some View {
        Text(trimmedTextOverlay.isEmpty ? "YOUR OVERLAY" : trimmedTextOverlay.uppercased())
            .font(.system(size: 17, weight: .black, design: .rounded))
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.45), radius: 4)
            .lineLimit(2)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var confirmStep: some View {
        VStack(spacing: 14) {
            Text("Final review")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            VStack(spacing: 10) {
                confirmRow(label: "Product", value: selectedProduct?.name ?? "-")
                confirmRow(label: "Duration", value: "\(recordedVideo?.durationSeconds ?? 0)s")
                confirmRow(label: "Overlay", value: trimmedTextOverlay.isEmpty ? "None" : trimmedTextOverlay)
                confirmRow(label: "Position", value: textPosition.rawValue.capitalized)
            }
            .padding(14)
            .clipStakesGlassCard(cornerRadius: 16)

            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("INSTANT UNLOCK")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .tracking(1)
                        .foregroundStyle(.white.opacity(0.78))
                    Text("$5 Coupon")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }
                Spacer()
                Image(systemName: "ticket.fill")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(ClipStakesPalette.neonOrange)
            }
            .padding(14)
            .background(
                LinearGradient(
                    colors: [ClipStakesPalette.neonPink.opacity(0.42), ClipStakesPalette.neonOrange.opacity(0.35)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 16)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.24), lineWidth: 1)
            )

            if isUploading {
                ProgressView("Uploading + minting reward...")
                    .tint(ClipStakesPalette.neonPink)
            }

            HStack(spacing: 10) {
                Button("Back") {
                    step = .addText
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
        .padding(16)
        .clipStakesGlassCard(cornerRadius: 22)
    }

    private var successStep: some View {
        VStack(spacing: 16) {
            if let reward {
                VStack(spacing: 8) {
                    Text("CLIP IS LIVE")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .tracking(1.1)
                        .foregroundStyle(.white.opacity(0.78))
                    Text("INSTANT CREATOR REWARD")
                        .font(.system(size: 24, weight: .black, design: .serif))
                        .foregroundStyle(.white)
                }

                VStack(spacing: 14) {
                    Text(reward.couponValue)
                        .font(.system(size: 56, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text("OFF YOUR NEXT PURCHASE")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .tracking(1.4)
                        .foregroundStyle(.white.opacity(0.9))

                    HStack(spacing: 10) {
                        Text(reward.couponCode)
                            .font(.system(size: 17, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)

                        Button(copiedCoupon ? "Copied" : "Copy") {
                            Task { @MainActor in
                                ClipStakesClipboard.copy(reward.couponCode)
                                copiedCoupon = true
                            }
                        }
                        .buttonStyle(.bordered)
                        .tint(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 12))
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(
                    LinearGradient(
                        colors: [ClipStakesPalette.neonPink, ClipStakesPalette.neonBlue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 24)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.24), lineWidth: 1)
                )
                .shadow(color: ClipStakesPalette.neonPink.opacity(pulseReward ? 0.48 : 0.24), radius: pulseReward ? 24 : 14, y: 8)

                VStack(spacing: 10) {
                    Button {
                        walletAdded = true
                        Task { @MainActor in
                            ClipStakesClipboard.copy(reward.couponCode)
                        }
                    } label: {
                        Label(
                            walletAdded ? "Wallet Fallback Ready" : "Add to Apple Wallet (Fallback)",
                            systemImage: walletAdded ? "checkmark.circle.fill" : "wallet.pass"
                        )
                    }
                    .buttonStyle(ClipStakesPrimaryButtonStyle(disabled: walletAdded))
                    .disabled(walletAdded)

                    Button {
                        showShareSheet = true
                    } label: {
                        Label("Share to Stories", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(ClipStakesSecondaryButtonStyle())

                    if let createdClipID {
                        Button("Check Bonus Status") {
                            Task { await refreshBonusStatus(clipID: createdClipID) }
                        }
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(ClipStakesPalette.mint)
                    }
                }

                if let bonusEvent {
                    VStack(alignment: .leading, spacing: 6) {
                        Label(bonusEvent.title, systemImage: "bell.badge.fill")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(ClipStakesPalette.neonOrange)

                        Text(bonusEvent.body)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.75))
                    }
                    .padding(12)
                    .clipStakesGlassCard(cornerRadius: 14)
                } else {
                    Text("If your clip converts within 8 hours, you unlock another $5 bonus.")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 10)
                }
            }
        }
        .padding(16)
        .clipStakesGlassCard(cornerRadius: 22)
    }

    private var blockedState: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.trianglebadge.exclamationmark")
                .font(.system(size: 46, weight: .black))
                .foregroundStyle(ClipStakesPalette.neonOrange)

            Text("Receipt already used")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Text(errorMessage ?? "This receipt already created a clip.")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.74))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding(.vertical, 30)
        .frame(maxWidth: .infinity)
        .clipStakesGlassCard(cornerRadius: 22)
    }

    private var failureState: some View {
        VStack(spacing: 12) {
            Image(systemName: "xmark.octagon.fill")
                .font(.system(size: 44, weight: .black))
                .foregroundStyle(ClipStakesPalette.neonPink)

            Text("Could not load receipt")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Text(errorMessage ?? "Try another receipt URL.")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.74))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            Button("Retry") {
                Task { await loadReceipt() }
            }
            .buttonStyle(ClipStakesPrimaryButtonStyle())
        }
        .padding(.vertical, 30)
        .padding(.horizontal, 16)
        .clipStakesGlassCard(cornerRadius: 22)
    }

    private func confirmRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
    }

    private func productThumb(_ product: ClipStakesProduct) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.12))

            if let imageURL = product.imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        Image(systemName: product.systemImage)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            } else {
                Image(systemName: product.systemImage)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: 44, height: 44)
        .clipShape(RoundedRectangle(cornerRadius: 10))
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

    private func isStepActive(_ candidate: CreatorStep) -> Bool {
        stepOrder(candidate) <= stepOrder(step)
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
            "I just staked a clip on CLIPSTAKES and unlocked \(reward.couponCode).",
            "Create a clip, get $5 instantly."
        ]
    }

    private func loadReceipt() async {
        await MainActor.run {
            step = .loading
            errorMessage = nil
        }

        let catalogResult = await ClipStakesShopifyPublicCatalogService.shared.loadCatalog(
            storeDomainOverride: storeDomainOverride
        )

        await MainActor.run {
            catalogStatusMessage = catalogResult.message
        }

        do {
            let receipt = try await ClipStakesMockBackend.shared.getReceipt(receiptId: receiptID)
            await MainActor.run {
                products = receipt.products
                step = .selectProduct
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                if let backendError = error as? ClipStakesBackendError, backendError == .receiptAlreadyUsed {
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
            let upload = await ClipStakesMockBackend.shared.createUploadURL(
                receiptId: receiptID,
                productId: selectedProduct.id
            )

            if let sourceURL = recordedVideo.fileURL, !trimmedTextOverlay.isEmpty {
                _ = await ClipStakesVideoCompositor.addText(
                    to: sourceURL,
                    text: trimmedTextOverlay,
                    position: textPosition
                )
            }

            let response = try await ClipStakesMockBackend.shared.createClip(
                receiptId: receiptID,
                deviceToken: deviceToken,
                productId: selectedProduct.id,
                videoURL: upload.videoURL,
                textOverlay: trimmedTextOverlay.isEmpty ? nil : trimmedTextOverlay,
                textPosition: textPosition,
                durationSeconds: recordedVideo.durationSeconds
            )

            await MainActor.run {
                reward = response
                createdClipID = response.clipID
                copiedCoupon = false
                walletAdded = false
                step = .success
            }

            await refreshBonusStatus(clipID: response.clipID)
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                step = .confirm
            }
        }
    }

    private func refreshBonusStatus(clipID: String) async {
        let event = await ClipStakesMockBackend.shared.latestNotification(for: clipID)
        await MainActor.run {
            bonusEvent = event
        }
    }
}
