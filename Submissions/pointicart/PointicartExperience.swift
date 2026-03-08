import SwiftUI

struct PointicartExperience: ClipExperience {
    static let urlPattern = "pointicart.shop/store/:storeId"
    static let clipName = "Pointicart: Point & Shop"
    static let clipDescription = "Tap NFC on any shelf — browse, size, and buy in under 30 seconds."
    static let teamName = "Pointicart"
    static let touchpoint: JourneyTouchpoint = .onSite
    static let invocationSource: InvocationSource = .nfcTag

    let context: ClipContext

    @State private var phase: Phase = .scanning
    @State private var cart: [Product] = []
    @State private var scanProgress: CGFloat = 0
    @State private var identifiedCount: Int = 0

    private enum Phase: Equatable {
        case scanning, browse, checkout, success
    }

    private var storeId: String {
        context.pathParameters["storeId"] ?? "42"
    }

    // Pointicart in-store clothing products
    private static let shelfProducts: [Product] = [
        Product(
            id: UUID(), name: "Cropped Jacket", price: 129.99,
            category: .apparel, systemImage: "figure.walk",
            sizes: ["S", "M", "L", "XL"]
        ),
        Product(
            id: UUID(), name: "Graphic Tee", price: 34.99,
            category: .apparel, systemImage: "tshirt.fill",
            sizes: ["XS", "S", "M", "L", "XL"]
        ),
        Product(
            id: UUID(), name: "Oversized Hoodie", price: 64.99,
            category: .apparel, systemImage: "tshirt.fill",
            sizes: ["S", "M", "L", "XL"]
        ),
        Product(
            id: UUID(), name: "Knit Sweater", price: 79.99,
            category: .apparel, systemImage: "cloud.fill",
            sizes: ["S", "M", "L"]
        ),
    ]

    // 8h notification templates for abandoned-cart recovery
    private static let storeNotifications: [NotificationTemplate] = [
        NotificationTemplate(
            title: "Still shopping?",
            body: "You left items in your Pointicart bag. Checkout takes 10 seconds.",
            journeyStage: "In-Store",
            triggerDescription: "Sent 15 min after last interaction",
            delayFromInvocation: 60 * 15
        ),
        NotificationTemplate(
            title: "Your items are still available",
            body: "Cropped Jacket and more items are waiting. Complete your order before you leave.",
            journeyStage: "In-Store",
            triggerDescription: "Sent 1 hour after scan",
            delayFromInvocation: 60 * 60
        ),
        NotificationTemplate(
            title: "Exclusive: 10% off your cart",
            body: "We noticed you didn't check out. Here's a thank-you for visiting — valid 4 hours.",
            journeyStage: "Post-Visit",
            triggerDescription: "Sent 3 hours after scan if cart abandoned",
            delayFromInvocation: 60 * 60 * 3
        ),
    ]

    var body: some View {
        ZStack {
            ClipBackground()

            switch phase {
            case .scanning:
                scanningView
                    .transition(.opacity)
            case .browse:
                browseView
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .checkout:
                checkoutView
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .success:
                successView
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.4), value: phase)
    }

    // MARK: - Scanning Phase

    private var scanningView: some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                Circle()
                    .stroke(.primary.opacity(0.08), lineWidth: 1.5)
                    .frame(width: 180, height: 180)

                Circle()
                    .trim(from: 0, to: scanProgress)
                    .stroke(
                        AngularGradient(
                            colors: [.blue.opacity(0.8), .cyan, .blue.opacity(0.8)],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 10) {
                    Image(systemName: "viewfinder")
                        .font(.system(size: 44, weight: .ultraLight))
                        .foregroundStyle(.primary)
                        .symbolEffect(.pulse)

                    Text("\(identifiedCount) / \(Self.shelfProducts.count)")
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }

            VStack(spacing: 6) {
                Text("Scanning Shelf")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.primary)

                Text("NFC Tag → Store #\(storeId)")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }

            Spacer()
        }
        .task {
            withAnimation(.easeInOut(duration: 1.8)) {
                scanProgress = 1.0
            }

            let count = Self.shelfProducts.count
            for i in 1...count {
                try? await Task.sleep(for: .milliseconds(Int(1600.0 / Double(count))))
                withAnimation(.spring(duration: 0.2)) {
                    identifiedCount = i
                }
            }

            try? await Task.sleep(for: .milliseconds(400))
            withAnimation(.spring(duration: 0.4)) {
                phase = .browse
            }
        }
    }

    // MARK: - Browse Phase

    private var browseView: some View {
        ScrollView {
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "wave.3.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.blue)
                    Text("Pointicart Clothing")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)
                    Spacer()
                    Text("Store #\(storeId)")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .glassEffect(.regular.interactive(), in: .capsule)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                ClipHeader(
                    title: "Nearby Products",
                    subtitle: "\(Self.shelfProducts.count) items identified on this shelf",
                    systemImage: "bag.fill"
                )
                .padding(.top, 4)

                MerchGrid(products: Self.shelfProducts) { product in
                    cart.append(product)
                }

                if !cart.isEmpty {
                    CartSummary(items: cart) {
                        withAnimation(.spring(duration: 0.4)) {
                            phase = .checkout
                        }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(.bottom, 16)
        }
        .scrollIndicators(.hidden)
        .animation(.spring(duration: 0.3), value: cart.count)
    }

    // MARK: - Checkout Phase

    private var checkoutView: some View {
        VStack(spacing: 18) {
            Spacer()

            ClipHeader(
                title: "Express Checkout",
                subtitle: "No login needed. Tap, pay, pick up.",
                systemImage: "creditcard.fill"
            )
            .padding(.horizontal, 24)

            GlassEffectContainer {
                VStack(spacing: 8) {
                    checkoutRow(label: "Items", value: "\(cart.count)")
                    checkoutRow(label: "Subtotal", value: totalPrice)
                    checkoutRow(label: "Pickup", value: "Front Register")
                    checkoutRow(label: "Payment", value: "Apple Pay")
                }
            }
            .padding(.horizontal, 20)

            HStack(spacing: 10) {
                ClipActionButton(title: "Back", icon: "chevron.left", style: .secondary) {
                    withAnimation(.spring(duration: 0.35)) {
                        phase = .browse
                    }
                }

                ClipActionButton(title: "Pay Now", icon: "checkmark.circle.fill") {
                    withAnimation(.spring(duration: 0.35)) {
                        phase = .success
                    }
                }
            }
            .padding(.horizontal, 20)

            Spacer()
        }
        .padding(.bottom, 16)
    }

    // MARK: - Success Phase

    private var successView: some View {
        ScrollView {
            VStack(spacing: 16) {
                Spacer().frame(height: 20)

                ClipSuccessOverlay(
                    message: "Order confirmed!\nPick up \(cart.count) item\(cart.count == 1 ? "" : "s") at the front register."
                )

                NotificationTimeline(templates: Self.storeNotifications)
                    .padding(.top, 12)
            }
            .padding(.bottom, 16)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Helpers

    private var totalPrice: String {
        let total = cart.reduce(0) { $0 + $1.price }
        return String(format: "$%.2f", total)
    }

    @ViewBuilder
    private func checkoutRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 12))
    }
}
