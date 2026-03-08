import Foundation
import SwiftUI

struct CanadaclipsClipExperience: ClipExperience {
    static let urlPattern = "example.com/canadaclips/:param"
    static let clipName = "CanadaClips"
    static let clipDescription = "Redirect big-brand demand toward Canadian local and regional merchants."
    static let teamName = "CanadaClips"
    static let touchpoint: JourneyTouchpoint = .purchase
    static let invocationSource: InvocationSource = .iMessage
    static let sampleInvocationURL =
        "https://example.com/canadaclips/demo?url=https://www.bestbuy.ca/en-ca/product/lenovo-ideapad-slim-3i-14-laptop-abyss-blue-intel-n100-4gb-ram-128gb-ssd-windows-11/19436674"

    let context: ClipContext

    var body: some View {
        CanadaClipsShell(context: context)
    }
}

private struct CanadaClipsShell: View {
    private enum DiscoveryPhase {
        case intro
        case loading
        case results
        case emptyOrError
    }

    private enum ScreenState {
        case discovery
        case checkout
    }

    @Environment(\.openURL) private var openURL
    @Environment(\.locale) private var locale

    let context: ClipContext

    @State private var screenState: ScreenState = .discovery
    @State private var phase: DiscoveryPhase = .intro
    @State private var sourceURLText: String = ""
    @State private var sourceHost: String?
    @State private var products: [CanadaClipProduct] = []
    @State private var selectedProduct: CanadaClipProduct?
    @State private var isLoading = false
    @State private var noteText: String?
    @State private var didBootstrapInvocation = false
    @State private var selectedOption = "M"
    @State private var isAnimatingSuccess = false
    @State private var successPayload: SuccessPayload?

    private let discoveryService = CanadaClipsDiscoveryService()

    var body: some View {
        ZStack {
            CanadaClipsBackdrop()
                .ignoresSafeArea()

            VStack(spacing: 12) {
                Spacer(minLength: 80)

                switch screenState {
                case .discovery:
                    discoverySheet
                        .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity), removal: .opacity))
                case .checkout:
                    checkoutSheet
                        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
                }

                footerCard
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)

            if let successPayload {
                PaymentSuccessOverlay(payload: successPayload)
                    .transition(.opacity.combined(with: .scale(scale: 0.92)))
                    .zIndex(20)
            }
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.9), value: screenState)
        .animation(.easeInOut(duration: 0.22), value: phase)
        .onAppear {
            bootstrapFromInvocationIfNeeded()
        }
    }

    private var discoverySheet: some View {
        VStack(spacing: 14) {
            Capsule()
                .fill(Color.secondary.opacity(0.35))
                .frame(width: 40, height: 6)
                .padding(.top, 8)

            VStack(alignment: .leading, spacing: 6) {
                Text("CanadaClips")
                    .font(.system(size: 44, weight: .bold, design: .default))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)

                if phase == .intro {
                    Text("Paste a product URL to find local options")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else if let sourceHost {
                    Text("Source: \(sourceHost)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Searching for local alternatives")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Paste product URL...", text: $sourceURLText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .font(.body)

                Button("Find") {
                    Task { await runDiscovery(triggeredByUser: true) }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .disabled(isLoading || trimmedSourceInput.isEmpty)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.systemBackground).opacity(0.92))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )

            if phase == .intro {
                introContent
            } else {
                expandedContent
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(.systemBackground).opacity(0.90))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.6), lineWidth: 0.7)
                )
                .shadow(color: .black.opacity(0.18), radius: 24, y: 14)
        )
    }

    private var introContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Text("Works with")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                worksWithChip("Nike")
                worksWithChip("Amazon")
                worksWithChip("ASOS")
                worksWithChip("+ more")
            }

            VStack(spacing: 0) {
                introRow(
                    icon: "link",
                    color: Color.blue,
                    title: "Paste any product link",
                    subtitle: "Any big-brand URL works"
                )
                Divider().padding(.leading, 62)
                introRow(
                    icon: "leaf.fill",
                    color: Color.red,
                    title: "We find Canadian alternatives",
                    subtitle: "Gemini surfaces real local businesses"
                )
                Divider().padding(.leading, 62)
                introRow(
                    icon: "bag.fill",
                    color: Color.green,
                    title: "Shop local, keep it Canadian",
                    subtitle: "Visit their store directly"
                )
            }
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(.systemBackground).opacity(0.88))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.primary.opacity(0.07), lineWidth: 1)
            )
        }
    }

    private var expandedContent: some View {
        Group {
            switch phase {
            case .loading:
                VStack(spacing: 12) {
                    ProgressView()
                        .controlSize(.large)
                    Text("Finding local alternatives...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
                .padding(.vertical, 12)

            case .results:
                ScrollView {
                    VStack(spacing: 14) {
                        ForEach(products) { product in
                            CanadaClipProductCard(
                                product: product,
                                onCheckout: {
                                    guard !isAnimatingSuccess else { return }
                                    selectedProduct = product
                                    selectedOption = defaultOption(for: product)
                                    screenState = .checkout
                                },
                                onVisitStore: {
                                    if let url = URL(string: product.productURL) {
                                        openURL(url)
                                    }
                                }
                            )
                        }
                    }
                }
                .frame(maxHeight: 360)

            case .emptyOrError:
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 42))
                        .foregroundStyle(.secondary)

                    Text(noteText ?? "No matching alternatives were returned.")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)

                    Button("Try Again") {
                        Task { await runDiscovery(triggeredByUser: true) }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isLoading || trimmedSourceInput.isEmpty)
                }
                .frame(maxWidth: .infinity, minHeight: 220)
                .padding(.vertical, 10)

            case .intro:
                EmptyView()
            }
        }
    }

    private var checkoutSheet: some View {
        VStack(spacing: 14) {
            Capsule()
                .fill(Color.secondary.opacity(0.35))
                .frame(width: 40, height: 6)
                .padding(.top, 8)

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Checkout")
                        .font(.title2.bold())
                    Text(selectedProduct?.storeName ?? "")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Back") {
                    guard !isAnimatingSuccess else { return }
                    screenState = .discovery
                }
                .font(.body)
            }

            if let selectedProduct {
                checkoutContent(for: selectedProduct)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(.systemBackground).opacity(0.90))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.6), lineWidth: 0.7)
                )
                .shadow(color: .black.opacity(0.18), radius: 24, y: 14)
        )
    }

    private var footerCard: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.95), Color.blue.opacity(0.72)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "app.badge")
                        .foregroundStyle(.white)
                        .font(.system(size: 18, weight: .semibold))
                )

            VStack(alignment: .leading, spacing: 1) {
                Text("App Clip Preview")
                    .font(.title3.weight(.semibold))
                    .lineLimit(1)
                Text("Get the full app experience")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("GET")
                .font(.headline.bold())
                .foregroundStyle(.blue)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.blue.opacity(0.12))
                )
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(.systemBackground).opacity(0.90))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.65), lineWidth: 0.7)
                )
        )
    }

    @ViewBuilder
    private func checkoutContent(for product: CanadaClipProduct) -> some View {
        checkoutProductRow(product)
        checkoutOptionSelector(for: product)
        checkoutSummary(product)
        checkoutPaymentButtons(for: product)
    }

    @ViewBuilder
    private func checkoutOptionSelector(for product: CanadaClipProduct) -> some View {
        let options = optionSet(for: product)
        if options.count > 1 {
            VStack(alignment: .leading, spacing: 8) {
                Text(optionLabel(for: product).uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    ForEach(options, id: \.self) { option in
                        Button(option) {
                            guard !isAnimatingSuccess else { return }
                            selectedOption = option
                        }
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(selectedOption == option ? Color.red.opacity(0.09) : Color(.systemBackground).opacity(0.9))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(selectedOption == option ? Color.red : Color.primary.opacity(0.12), lineWidth: 1)
                        )
                        .foregroundStyle(selectedOption == option ? Color.red : Color.secondary)
                        .disabled(isAnimatingSuccess)
                    }
                }
            }
        }
    }

    private func checkoutPaymentButtons(for product: CanadaClipProduct) -> some View {
        VStack(spacing: 10) {
            Button {
                startMockPayment(method: "Apple Pay confirmed")
            } label: {
                Text("Pay")
                    .frame(maxWidth: .infinity)
                    .font(.title3.weight(.medium))
                    .padding(.vertical, 14)
            }
            .buttonStyle(.plain)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.black)
            )
            .foregroundStyle(.white)
            .disabled(isAnimatingSuccess)

            HStack {
                Rectangle().fill(Color.primary.opacity(0.15)).frame(height: 1)
                Text("or pay with card")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Rectangle().fill(Color.primary.opacity(0.15)).frame(height: 1)
            }

            Button {
                startMockPayment(method: "Card payment confirmed")
            } label: {
                Text("Pay \(formattedTotal(for: product)) \u{2192}")
                    .frame(maxWidth: .infinity)
                    .font(.headline.weight(.bold))
                    .padding(.vertical, 14)
            }
            .buttonStyle(.plain)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(red: 0.78, green: 0.06, blue: 0.18))
            )
            .foregroundStyle(.white)
            .disabled(isAnimatingSuccess)
        }
    }

    private func introRow(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(color.opacity(0.9))
                .frame(width: 38, height: 38)
                .overlay(
                    Image(systemName: icon)
                        .foregroundStyle(.white)
                        .font(.system(size: 16, weight: .bold))
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
    }

    private func worksWithChip(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(Color.primary.opacity(0.08))
            )
    }

    private func checkoutProductRow(_ product: CanadaClipProduct) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.primary.opacity(0.07))
                .frame(width: 48, height: 48)
                .overlay(
                    Text(product.emoji ?? categoryEmoji(for: product.categoryTag))
                        .font(.title2)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(product.productName)
                    .font(.headline)
                    .lineLimit(2)
                HStack(spacing: 6) {
                    if let location = product.location {
                        Text(location)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Text("\u{1F341} Local")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color(red: 0.16, green: 0.62, blue: 0.27))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule().fill(Color(red: 0.91, green: 0.97, blue: 0.93))
                        )
                }
            }

            Spacer()
            Text(product.price)
                .font(.title3.weight(.bold))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.systemBackground).opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.primary.opacity(0.10), lineWidth: 1)
                )
        )
    }

    private func checkoutSummary(_ product: CanadaClipProduct) -> some View {
        let subtotal = numericPrice(from: product.price)
        let tax = subtotal * 0.13
        let total = subtotal + tax

        return VStack(spacing: 7) {
            summaryRow("Subtotal", value: currencyString(subtotal))
            summaryRow("Shipping", value: "Free", valueColor: .green)
            summaryRow("HST (13%)", value: currencyString(tax))
            Divider().padding(.vertical, 3)
            summaryRow("Total", value: currencyString(total), bold: true)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.systemBackground).opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.primary.opacity(0.10), lineWidth: 1)
                )
        )
    }

    private func summaryRow(_ label: String, value: String, valueColor: Color = .primary, bold: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(bold ? .headline : .body)
                .foregroundStyle(bold ? .primary : .secondary)
            Spacer()
            Text(value)
                .font(bold ? .headline : .body)
                .foregroundStyle(valueColor)
        }
    }

    private func bootstrapFromInvocationIfNeeded() {
        guard !didBootstrapInvocation else { return }
        didBootstrapInvocation = true

        if let queryURL = context.queryParameters["url"]?.removingPercentEncoding ?? context.queryParameters["url"],
           !queryURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            sourceURLText = queryURL
            Task { await runDiscovery(triggeredByUser: false) }
            return
        }

        if let source = context.queryParameters["source"]?.removingPercentEncoding, !source.isEmpty {
            sourceURLText = source
        }
    }

    private func startMockPayment(method: String) {
        guard !isAnimatingSuccess, let selectedProduct else { return }
        isAnimatingSuccess = true
        successPayload = SuccessPayload(
            title: "Payment Complete",
            subtitle: method,
            amountText: "\(formattedTotal(for: selectedProduct)) paid"
        )

        Task {
            try? await Task.sleep(for: .milliseconds(1700))
            await MainActor.run {
                successPayload = nil
                isAnimatingSuccess = false
                screenState = .discovery
                self.selectedProduct = nil
            }
        }
    }

    private func runDiscovery(triggeredByUser: Bool) async {
        guard !isLoading else { return }

        guard let sourceURL = normalizedSourceURL(from: sourceURLText) else {
            if triggeredByUser {
                phase = .emptyOrError
                noteText = "Paste a valid product URL to continue."
            }
            return
        }

        isLoading = true
        phase = .loading
        noteText = nil
        sourceHost = hostDisplay(sourceURL)

        let pinned = HardcodedTriggerDefaults.matchingProduct(for: sourceURL)

        do {
            let response = try await discoveryService.fetchAlternatives(productURL: sourceURL, locale: locale)
            var merged = merge(pinned: pinned, discovered: response.products)

            if merged.isEmpty {
                merged = fallbackSyntheticProducts(for: sourceURL)
                noteText = merged.isEmpty
                    ? "No matching alternatives were returned."
                    : "Showing fallback alternatives while discovery improves."
            } else if let reason = response.reason, !reason.isEmpty {
                noteText = reasonMessage(for: reason)
            } else {
                noteText = nil
            }

            products = merged
            phase = merged.isEmpty ? .emptyOrError : .results
        } catch {
            let fallback = merge(pinned: pinned, discovered: fallbackSyntheticProducts(for: sourceURL))
            products = fallback
            if fallback.isEmpty {
                phase = .emptyOrError
                noteText = humanReadableError(error)
            } else {
                phase = .results
                noteText = "Showing fallback alternatives while live discovery is unavailable."
            }
        }

        isLoading = false
    }

    private func merge(pinned: CanadaClipProduct?, discovered: [CanadaClipProduct]) -> [CanadaClipProduct] {
        var seen = Set<String>()
        var output: [CanadaClipProduct] = []

        if let pinned {
            output.append(pinned)
            seen.insert(canonicalResultKey(for: pinned))
        }

        for item in discovered {
            let key = canonicalResultKey(for: item)
            if seen.contains(key) {
                continue
            }
            seen.insert(key)
            output.append(item)
        }
        return output
    }

    private func canonicalResultKey(for product: CanadaClipProduct) -> String {
        "\(canonicalURLString(product.productURL))|\(product.storeName.lowercased())"
    }

    private func normalizedSourceURL(from text: String) -> URL? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let url = URL(string: trimmed), let scheme = url.scheme, (scheme == "http" || scheme == "https"), url.host != nil {
            return url
        }
        if let url = URL(string: "https://\(trimmed)"), url.host != nil {
            return url
        }
        return nil
    }

    private var trimmedSourceInput: String {
        sourceURLText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func hostDisplay(_ url: URL) -> String {
        let host = (url.host ?? "").lowercased()
        if host.hasPrefix("www.") {
            return String(host.dropFirst(4))
        }
        return host
    }

    private func formattedTotal(for product: CanadaClipProduct) -> String {
        let subtotal = numericPrice(from: product.price)
        let total = subtotal + subtotal * 0.13
        return currencyString(total)
    }

    private func optionSet(for product: CanadaClipProduct) -> [String] {
        switch product.categoryTag {
        case .apparel:
            return ["S", "M", "L", "XL"]
        case .food:
            return ["Small", "Medium", "Large"]
        default:
            return ["Standard"]
        }
    }

    private func defaultOption(for product: CanadaClipProduct) -> String {
        optionSet(for: product).contains("M") ? "M" : optionSet(for: product).first ?? "Standard"
    }

    private func optionLabel(for product: CanadaClipProduct) -> String {
        switch product.categoryTag {
        case .food:
            return "Portion"
        case .apparel:
            return "Size"
        default:
            return "Configuration"
        }
    }

    private func numericPrice(from text: String) -> Double {
        let allowed = Set("0123456789.")
        let clean = String(text.filter { allowed.contains($0) })
        return Double(clean) ?? 0
    }

    private func currencyString(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = locale.currency?.identifier ?? "CAD"
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "$%.2f", value)
    }

    private func categoryEmoji(for category: CanadaClipProduct.CategoryTag) -> String {
        switch category {
        case .food: return "\u{1F959}"
        case .tech: return "\u{1F50C}"
        case .audio: return "\u{1F3A7}"
        case .outdoors: return "\u{1F392}"
        case .apparel: return "\u{1F9E5}"
        case .home: return "\u{1F3E0}"
        case .general: return "\u{1F6CD}"
        }
    }

    private func reasonMessage(for reason: String) -> String {
        switch reason {
        case "gemini_primary_timeout", "gemini_rescue_timeout":
            return "Live discovery timed out; showing available alternatives."
        case "gemini_rate_limited":
            return "Gemini quota is busy right now; try again shortly."
        case "backend_unreachable":
            return "Discovery backend is unavailable; showing fallback options."
        case "no_candidates_from_gemini", "no_valid_candidates_after_filter":
            return "No strong local matches were found for this URL yet."
        default:
            return reason.replacingOccurrences(of: "_", with: " ")
        }
    }

    private func humanReadableError(_ error: Error) -> String {
        if let discoveryError = error as? CanadaClipsDiscoveryService.DiscoveryError {
            switch discoveryError {
            case .backendUnavailable:
                return "Discovery backend is unavailable. Start backend or configure an endpoint."
            case .timedOut:
                return "Discovery request timed out waiting for Gemini."
            case .decodingFailed:
                return "Discovery response could not be parsed."
            case let .httpError(code):
                if code == 429 { return "Gemini quota is currently exceeded. Try again shortly." }
                if code == 403 { return "Discovery request was rejected by Gemini." }
                return "Discovery backend returned HTTP \(code)."
            }
        }
        return "No matching alternatives were returned."
    }

    private func fallbackSyntheticProducts(for sourceURL: URL) -> [CanadaClipProduct] {
        let host = hostDisplay(sourceURL)
        let category = CanadaClipProduct.CategoryTag.infer(from: sourceURL.absoluteString)

        let templates: [CanadaClipProduct]
        switch category {
        case .food:
            templates = [
                .init(storeName: "Local Plate Co", productName: "Loaded Bowl Special", price: "$17.50", productURL: "https://localplate.example/menu", imageURL: nil, description: "Fast, filling and made fresh locally.", location: "Toronto, ON", emoji: "\u{1F959}", isPinnedDefault: false, categoryTag: .food),
                .init(storeName: "Harbour Eats", productName: "Street Wrap Combo", price: "$15.00", productURL: "https://harboureats.example/menu", imageURL: nil, description: "A similar comfort-food option from a neighborhood kitchen.", location: "Mississauga, ON", emoji: "\u{1F32F}", isPinnedDefault: false, categoryTag: .food),
            ]
        case .tech, .audio:
            templates = [
                .init(storeName: "Maple Tech Supply", productName: "Performance Everyday Laptop", price: "$699.00", productURL: "https://mapletech.example/products/laptop", imageURL: nil, description: "Comparable performance and storage for daily workloads.", location: "Ottawa, ON", emoji: "\u{1F4BB}", isPinnedDefault: false, categoryTag: .tech),
                .init(storeName: "Northbyte Electronics", productName: "Compact Productivity Notebook", price: "$749.00", productURL: "https://northbyte.example/products/notebook", imageURL: nil, description: "Balanced specs in the same value tier.", location: "Calgary, AB", emoji: "\u{1F4BB}", isPinnedDefault: false, categoryTag: .tech),
            ]
        case .apparel:
            templates = [
                .init(storeName: "StreetRoot Co", productName: "Urban Hoodie — Forest", price: "$89.00", productURL: "https://streetroot-co.vercel.app/", imageURL: nil, description: "Soft fleece everyday layer from a Canadian brand.", location: "Montr\u{00E9}al, QC", emoji: "\u{1F9E5}", isPinnedDefault: false, categoryTag: .apparel),
                .init(storeName: "Northline Apparel", productName: "Classic Pullover", price: "$82.00", productURL: "https://northline.example/products/pullover", imageURL: nil, description: "Comparable fit and fabric for all-season wear.", location: "Edmonton, AB", emoji: "\u{1F455}", isPinnedDefault: false, categoryTag: .apparel),
            ]
        case .outdoors:
            templates = [
                .init(storeName: "Northbound Packs", productName: "City Pack 28L", price: "$129.00", productURL: "https://northbound-packs.vercel.app/", imageURL: nil, description: "A daypack alternative with similar capacity and utility.", location: "Ontario, CA", emoji: "\u{1F392}", isPinnedDefault: false, categoryTag: .outdoors),
                .init(storeName: "Trailform Goods", productName: "Urban Adventure Backpack", price: "$119.00", productURL: "https://trailform.example/products/backpack", imageURL: nil, description: "Water-resistant pack for work, gym, and short trips.", location: "Halifax, NS", emoji: "\u{1F392}", isPinnedDefault: false, categoryTag: .outdoors),
            ]
        case .home, .general:
            templates = [
                .init(storeName: "Maple Market House", productName: "Everyday Utility Pick", price: "$59.00", productURL: "https://maplemarket.example/product", imageURL: nil, description: "A practical local alternative in a similar price range.", location: "Winnipeg, MB", emoji: "\u{1F6CD}", isPinnedDefault: false, categoryTag: .general),
                .init(storeName: "Neighborhood Goods Co", productName: "Value Local Alternative", price: "$65.00", productURL: "https://neighborhoodgoods.example/item", imageURL: nil, description: "Comparable quality from an independent merchant.", location: "Hamilton, ON", emoji: "\u{1F6D2}", isPinnedDefault: false, categoryTag: .general),
            ]
        }

        if host.contains("bestbuy") || host.contains("amazon") || host.contains("newegg") {
            return templates.filter { $0.categoryTag == .tech || $0.categoryTag == .audio }.prefix(2).map { $0 }
        }
        return Array(templates.prefix(2))
    }

    private func canonicalURLString(_ raw: String) -> String {
        guard let url = URL(string: raw), var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return raw.lowercased()
        }
        let host = (components.host ?? "").lowercased()
        components.host = host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
        components.query = nil
        components.fragment = nil
        if components.path.hasSuffix("/") && components.path.count > 1 {
            components.path.removeLast()
        }
        return (components.string ?? raw).lowercased()
    }
}

private struct CanadaClipProductCard: View {
    let product: CanadaClipProduct
    let onCheckout: () -> Void
    let onVisitStore: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onCheckout) {
                VStack(spacing: 0) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.primary.opacity(0.06))
                            .frame(height: 178)

                        if let imageURL = product.imageURL, let url = URL(string: imageURL) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(height: 178)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        } else {
                            Text(product.emoji ?? fallbackEmoji)
                                .font(.system(size: 72))
                        }
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        Text(product.productName)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        HStack(spacing: 6) {
                            Text(product.storeName)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("\u{1F341} Local")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color(red: 0.16, green: 0.62, blue: 0.27))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule().fill(Color(red: 0.91, green: 0.97, blue: 0.93))
                                )
                        }

                        if let description = product.description, !description.isEmpty {
                            Text(description)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }

                        Text(product.price)
                            .font(.title2.bold())
                            .foregroundStyle(.primary)
                            .padding(.top, 1)
                    }
                    .padding(14)
                }
            }
            .buttonStyle(.plain)

            Button(action: onVisitStore) {
                HStack {
                    Image(systemName: "safari")
                    Text("Visit Store")
                }
                .font(.headline.weight(.bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
            }
            .buttonStyle(.plain)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(red: 0.78, green: 0.06, blue: 0.18))
            )
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
        }
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemBackground).opacity(0.94))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.primary.opacity(0.09), lineWidth: 1)
                )
        )
    }

    private var fallbackEmoji: String {
        switch product.categoryTag {
        case .food: return "\u{1F959}"
        case .tech: return "\u{1F50C}"
        case .audio: return "\u{1F3A7}"
        case .outdoors: return "\u{1F392}"
        case .apparel: return "\u{1F9E5}"
        case .home: return "\u{1F3E0}"
        case .general: return "\u{1F6CD}"
        }
    }
}

private struct CanadaClipsBackdrop: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.93, green: 0.95, blue: 0.97),
                    Color(red: 0.89, green: 0.92, blue: 0.95),
                    Color(red: 0.86, green: 0.90, blue: 0.93),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.blue.opacity(0.08))
                .frame(width: 320, height: 320)
                .blur(radius: 40)
                .offset(x: -130, y: 120)

            Circle()
                .fill(Color.white.opacity(0.5))
                .frame(width: 260, height: 260)
                .blur(radius: 28)
                .offset(x: 140, y: -190)
        }
    }
}

private struct PaymentSuccessOverlay: View {
    let payload: SuccessPayload
    @State private var showCard = false
    @State private var showCheck = false
    @State private var showRipple = false
    @State private var showConfetti = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.24)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(Color.green.opacity(0.35), lineWidth: 2)
                        .frame(width: showRipple ? 106 : 74, height: showRipple ? 106 : 74)
                        .opacity(showRipple ? 0 : 1)

                    Circle()
                        .fill(Color.green)
                        .frame(width: 72, height: 72)

                    Image(systemName: "checkmark")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.white)
                        .scaleEffect(showCheck ? 1 : 0.35)
                }

                Text(payload.title)
                    .font(.title2.bold())
                Text(payload.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(payload.amountText)
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 26)
            .padding(.horizontal, 22)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(.systemBackground).opacity(0.95))
            )
            .overlay(confettiOverlay)
            .scaleEffect(showCard ? 1 : 0.88)
            .opacity(showCard ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.36, dampingFraction: 0.78)) {
                showCard = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.55)) {
                    showCheck = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
                withAnimation(.easeOut(duration: 0.55)) {
                    showRipple = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
                withAnimation(.easeOut(duration: 0.7)) {
                    showConfetti = true
                }
            }
        }
    }

    private var confettiOverlay: some View {
        ZStack {
            ForEach(0..<12, id: \.self) { idx in
                Circle()
                    .fill(confettiColor(idx))
                    .frame(width: 7, height: 7)
                    .offset(
                        x: confettiX(idx),
                        y: showConfetti ? 85 : -8
                    )
                    .opacity(showConfetti ? 0 : 0.95)
            }
        }
        .allowsHitTesting(false)
    }

    private func confettiColor(_ index: Int) -> Color {
        let palette: [Color] = [.blue, .green, .orange, .pink, .purple]
        return palette[index % palette.count]
    }

    private func confettiX(_ index: Int) -> CGFloat {
        let positions: [CGFloat] = [-58, -44, -30, -16, -4, 8, 22, 35, 48, 60, -12, 14]
        return positions[index % positions.count]
    }
}

private struct SuccessPayload {
    let title: String
    let subtitle: String
    let amountText: String
}

private struct CanadaClipProduct: Identifiable, Hashable {
    enum CategoryTag: String, Codable {
        case food
        case tech
        case audio
        case outdoors
        case apparel
        case home
        case general

        static func infer(from text: String) -> CategoryTag {
            let lower = text.lowercased()
            if lower.contains("shawarma") || lower.contains("food") || lower.contains("ubereats") || lower.contains("restaurant") {
                return .food
            }
            if lower.contains("hoodie") || lower.contains("apparel") || lower.contains("shirt") || lower.contains("nike") {
                return .apparel
            }
            if lower.contains("backpack") || lower.contains("pack") || lower.contains("northface") || lower.contains("outdoor") {
                return .outdoors
            }
            if lower.contains("headphone") || lower.contains("speaker") || lower.contains("audio") {
                return .audio
            }
            if lower.contains("laptop") || lower.contains("computer") || lower.contains("charger") || lower.contains("usb") || lower.contains("anker") || lower.contains("tech") {
                return .tech
            }
            if lower.contains("home") || lower.contains("furniture") || lower.contains("kitchen") {
                return .home
            }
            return .general
        }
    }

    let id: String
    let storeName: String
    let productName: String
    let price: String
    let productURL: String
    let imageURL: String?
    let description: String?
    let location: String?
    let emoji: String?
    let isPinnedDefault: Bool
    let categoryTag: CategoryTag

    init(
        storeName: String,
        productName: String,
        price: String,
        productURL: String,
        imageURL: String?,
        description: String?,
        location: String?,
        emoji: String?,
        isPinnedDefault: Bool,
        categoryTag: CategoryTag
    ) {
        self.id = "\(storeName.lowercased())|\(productName.lowercased())|\(productURL.lowercased())"
        self.storeName = storeName
        self.productName = productName
        self.price = price
        self.productURL = productURL
        self.imageURL = imageURL
        self.description = description
        self.location = location
        self.emoji = emoji
        self.isPinnedDefault = isPinnedDefault
        self.categoryTag = categoryTag
    }
}

private enum HardcodedTriggerDefaults {
    struct TriggerRule {
        let host: String
        let pathPrefix: String
        let product: CanadaClipProduct
    }

    static let rules: [TriggerRule] = [
        .init(
            host: "thenorthface.com",
            pathPrefix: "/en-ca/bags-and-gear/backpacks",
            product: .init(
                storeName: "Northbound Packs",
                productName: "City Pack 28L",
                price: "$129.00",
                productURL: "https://northbound-packs.vercel.app/",
                imageURL: nil,
                description: "Canadian-designed everyday backpack with commuter-friendly storage.",
                location: "Ontario, CA",
                emoji: "\u{1F392}",
                isPinnedDefault: true,
                categoryTag: .outdoors
            )
        ),
        .init(
            host: "nike.com",
            pathPrefix: "/ca/w/hoodies-sweatshirts",
            product: .init(
                storeName: "StreetRoot Co",
                productName: "Urban Hoodie \u{2014} Forest",
                price: "$89.00",
                productURL: "https://streetroot-co.vercel.app/",
                imageURL: nil,
                description: "Brushed fleece hoodie option in the same budget range.",
                location: "Montr\u{00E9}al, QC",
                emoji: "\u{1F9E5}",
                isPinnedDefault: true,
                categoryTag: .apparel
            )
        ),
        .init(
            host: "anker.com",
            pathPrefix: "/collections/chargers",
            product: .init(
                storeName: "NorthTech Goods",
                productName: "ProCharge Hub 65W",
                price: "$64.00",
                productURL: "https://northtech-goods.vercel.app/",
                imageURL: nil,
                description: "Fast-charging USB-C solution for daily devices.",
                location: "Vancouver, BC",
                emoji: "\u{1F50C}",
                isPinnedDefault: true,
                categoryTag: .tech
            )
        ),
        .init(
            host: "ubereats.com",
            pathPrefix: "/ca/category/toronto-on/shawarma",
            product: .init(
                storeName: "Shawarma Palace",
                productName: "Loaded Shawarma Plate",
                price: "$18.50",
                productURL: "https://shawarma-palace.vercel.app/",
                imageURL: nil,
                description: "Fresh local shawarma plate with full toppings.",
                location: "Toronto, ON",
                emoji: "\u{1F959}",
                isPinnedDefault: true,
                categoryTag: .food
            )
        ),
    ]

    static func matchingProduct(for sourceURL: URL) -> CanadaClipProduct? {
        let host = canonicalHost(sourceURL)
        let path = canonicalPath(sourceURL)

        for rule in rules where host == rule.host {
            if path == rule.pathPrefix || path.hasPrefix(rule.pathPrefix) {
                return rule.product
            }
        }
        return nil
    }

    private static func canonicalHost(_ url: URL) -> String {
        var host = (url.host ?? "").lowercased()
        if host.hasPrefix("www.") {
            host = String(host.dropFirst(4))
        }
        return host
    }

    private static func canonicalPath(_ url: URL) -> String {
        var path = url.path.lowercased()
        if path.hasSuffix("/") && path.count > 1 {
            path.removeLast()
        }
        return path
    }
}

private struct CanadaClipsDiscoveryService {
    enum DiscoveryError: Error {
        case backendUnavailable
        case timedOut
        case httpError(Int)
        case decodingFailed
    }

    struct ResponseBundle {
        let products: [CanadaClipProduct]
        let reason: String?
    }

    func fetchAlternatives(productURL: URL, locale: Locale) async throws -> ResponseBundle {
        let payload = DiscoveryRequest(
            productURL: productURL.absoluteString,
            localeIdentifier: locale.identifier,
            regionCode: locale.region?.identifier,
            currencyCode: locale.currency?.identifier,
            countryHint: locale.region?.identifier
        )

        var lastError: DiscoveryError = .backendUnavailable
        for endpoint in endpointCandidates() {
            do {
                return try await request(endpoint: endpoint, payload: payload)
            } catch let err as DiscoveryError {
                lastError = err
                if case .backendUnavailable = err {
                    continue
                }
                throw err
            }
        }
        throw lastError
    }

    private func endpointCandidates() -> [URL] {
        var candidates: [URL] = []

        if let configured = ProcessInfo.processInfo.environment["SHOPIFY_DISCOVERY_ENDPOINT"],
           let url = URL(string: configured) {
            candidates.append(url)
        }

        if let envBase = ProcessInfo.processInfo.environment["CANADACLIPS_BACKEND_BASE_URL"] {
            if let url = URL(string: "\(envBase)/discover-shopify-alternatives") {
                candidates.append(url)
            }
        }

        candidates.append(URL(string: "http://127.0.0.1:8899/discover-shopify-alternatives")!)
        candidates.append(URL(string: "http://localhost:8899/discover-shopify-alternatives")!)
        return uniqueURLs(candidates)
    }

    private func uniqueURLs(_ input: [URL]) -> [URL] {
        var seen = Set<String>()
        var out: [URL] = []
        for url in input {
            let key = url.absoluteString
            if seen.insert(key).inserted {
                out.append(url)
            }
        }
        return out
    }

    private func request(endpoint: URL, payload: DiscoveryRequest) async throws -> ResponseBundle {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 6.5
        request.httpBody = try JSONEncoder().encode(payload)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            if (error as NSError).code == NSURLErrorTimedOut {
                throw DiscoveryError.timedOut
            }
            throw DiscoveryError.backendUnavailable
        }

        guard let http = response as? HTTPURLResponse else {
            throw DiscoveryError.backendUnavailable
        }

        guard (200..<300).contains(http.statusCode) else {
            throw DiscoveryError.httpError(http.statusCode)
        }

        let decoder = JSONDecoder()
        if let envelope = try? decoder.decode(DiscoveryEnvelope.self, from: data) {
            let products = envelope.alternatives.compactMap { $0.asProduct() }
            return ResponseBundle(products: policyFilter(products), reason: envelope.meta?.reason)
        }

        if let list = try? decoder.decode([DiscoveryItem].self, from: data) {
            let products = list.compactMap { $0.asProduct() }
            return ResponseBundle(products: policyFilter(products), reason: nil)
        }

        throw DiscoveryError.decodingFailed
    }

    private func policyFilter(_ products: [CanadaClipProduct]) -> [CanadaClipProduct] {
        products.filter { product in
            guard let url = URL(string: product.productURL), let host = url.host?.lowercased() else {
                return false
            }
            let blocked = [
                "amazon.", "walmart.", "target.", "bestbuy.", "ebay.", "temu.", "aliexpress.",
                "costco.", "homedepot.", "lowes."
            ]
            if blocked.contains(where: { host.contains($0) }) {
                return false
            }
            return true
        }
    }
}

private struct DiscoveryRequest: Codable {
    let productURL: String
    let localeIdentifier: String?
    let regionCode: String?
    let currencyCode: String?
    let countryHint: String?
}

private struct DiscoveryEnvelope: Decodable {
    let alternatives: [DiscoveryItem]
    let meta: DiscoveryMeta?
}

private struct DiscoveryMeta: Decodable {
    let reason: String?
}

private struct DiscoveryItem: Decodable {
    let storeName: String?
    let productName: String?
    let price: String?
    let productURL: String?
    let imageURL: String?
    let description: String?
    let categoryTag: String?
    let location: String?
    let emoji: String?

    func asProduct() -> CanadaClipProduct? {
        guard
            let storeName, !storeName.isEmpty,
            let productName, !productName.isEmpty,
            let productURL, !productURL.isEmpty
        else {
            return nil
        }
        let derivedCategory = CanadaClipProduct.CategoryTag(rawValue: categoryTag ?? "") ?? .infer(from: "\(productName) \(storeName) \(productURL)")
        return CanadaClipProduct(
            storeName: storeName,
            productName: productName,
            price: (price?.isEmpty == false ? price! : fallbackPrice(for: derivedCategory)),
            productURL: productURL,
            imageURL: imageURL,
            description: description ?? fallbackDescription(for: productName, category: derivedCategory),
            location: location,
            emoji: emoji,
            isPinnedDefault: false,
            categoryTag: derivedCategory
        )
    }

    private func fallbackPrice(for category: CanadaClipProduct.CategoryTag) -> String {
        switch category {
        case .food: return "$18.00"
        case .apparel: return "$88.00"
        case .outdoors: return "$125.00"
        case .audio: return "$95.00"
        case .tech: return "$699.00"
        case .home: return "$79.00"
        case .general: return "$59.00"
        }
    }

    private func fallbackDescription(for productName: String, category: CanadaClipProduct.CategoryTag) -> String {
        switch category {
        case .food:
            return "Similar local food option in the same value range."
        case .apparel:
            return "Comparable style and comfort for everyday wear."
        case .outdoors:
            return "Comparable utility and capacity for daily carry."
        case .audio:
            return "Comparable listening performance at a similar price."
        case .tech:
            return "Comparable specs and value for daily productivity."
        case .home:
            return "Comparable home-use option from a smaller retailer."
        case .general:
            return "Comparable alternative in a similar budget range."
        }
    }
}
