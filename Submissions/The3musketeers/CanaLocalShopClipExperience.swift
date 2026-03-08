import SwiftUI

// 1. Rename this file and struct to match your idea (e.g., PreShowMerchExperience.swift)
// 2. Update urlPattern, clipName, clipDescription, teamName
// 3. Build your UI in body using the building block components
// 4. Copy this folder as Submissions/YourTeamName/ and start building
// 5. If Xcode shows this file without Target Membership, that's expected here.
//    Submissions are compiled through GeneratedSubmissions.swift after build/script.
//
// DESIGN NOTES:
// - Use system colors (.primary, .secondary, .tertiary) — they adapt to Liquid Glass
// - Use .glassEffect(.regular.interactive(), in: ...) for card surfaces
// - ConstraintBanner is added automatically by the simulator — don't add it yourself
// - Wrap content in ScrollView to avoid overlapping with the top bar

struct CanaLocalShopClipExperience: ClipExperience {
    static let urlPattern = "canalocal.ca/stores/:id"
    static let clipName = "CanalocalShop"
    static let clipDescription = "Prioritizing Canadians since 2026"
    static let teamName = "The3musketeers"

    // Pick your touchpoint: .discovery, .purchase, .onSite, .reengagement, .utility
    // or define your own JourneyTouchpoint(id:title:icon:context:notificationHint:sortOrder:)
    static let touchpoint: JourneyTouchpoint = .purchase

    // Pick how fans invoke this: .qrCode, .nfcTag, .iMessage, .smartBanner, .appleMaps, .siri
    static let invocationSource: InvocationSource = .qrCode

    let context: ClipContext
    
    private enum CheckoutStep {
        case browse
        case stockVerify
        case checkout
        case success
    }

    // Add your @State properties here
    @State private var cart: [Product] = []
    @State private var purchased = false
    
    @State private var checkoutStep: CheckoutStep = .browse
    
    @State private var stockStatus = "Waiting for store verification..."
    @State private var secondsRemaining = 20
    @State private var stockFailed = false
    @State private var timer: Timer?
    @State private var orderCode = ""

    var body: some View {
        ZStack {
            ClipBackground()
            
            switch checkoutStep {
            case .browse:
                browseView
                    .transition(.move(edge: .leading).combined(with: .opacity))
            case .checkout:
                checkoutView
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .stockVerify:
                stockView
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .success:
                successView
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.35), value: checkoutStep)    }
    
    private var browseView: some View {
        ScrollView {
            VStack(spacing: 20) {
                ClipHeader(
                    title: "Mom and Pop's",
                    subtitle: "Great price, Great value",
                    systemImage: "cart.fill"
                )
                .padding(.top, 16)

                // Use MerchGrid for product browsing:
                 ShopClipProductGrid(products: ChallengeMockData.products) { product in
                     cart.append(product)
                 }

                // Use CartSummary for checkout:
                if !cart.isEmpty {
                    ShopCartSummary(items: cart,
                                    onCheckout: {
                                        purchased = true
                                        withAnimation(.spring(duration: 0.4)) {
                                            checkoutStep = .stockVerify
                                        }
                                    },
                                    onRemove: { product in
                        cart.removeAll { $0.id == product.id }
                    })
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
            }
            .padding(.bottom, 16)
        }
        .scrollIndicators(.hidden)
        
    }
    
    private var stockView: some View {
        VStack(spacing: 16) {

            if stockFailed {
                Text("Store reported an item is out of stock.")
                    .font(.headline)
                    .foregroundStyle(.red)

                ClipActionButton(title: "Back", icon: "chevron.left") {
                    withAnimation(.spring(duration: 0.35)) {
                        checkoutStep = .browse
                    }
                }
            } else {
                ProgressView()

                Text(stockStatus)
                    .font(.headline)

                Text("Estimated response: \(secondsRemaining)s")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .onAppear {
            startStockTimer()
        }
    }
    
    private var checkoutView: some View {
        VStack(spacing: 18) {
            Spacer()

            ClipHeader(
                title: "Mock Checkout",
                subtitle: "Transition demo: review, confirm, complete.",
                systemImage: "creditcard.fill"
            )
            .padding(.horizontal, 24)

            GlassEffectContainer {
                VStack(spacing: 8) {
                    checkoutRow(label: "Items", value: "\(cart.count)")
                    checkoutRow(label: "Subtotal", value: totalPrice)
                    checkoutRow(label: "Pickup", value: "Mom and Pop's")
                    checkoutRow(label: "Payment", value: "Apple Pay (Mock)")
                }
            }
            .padding(.horizontal, 20)
            

            HStack(spacing: 10) {
                ClipActionButton(title: "Back", icon: "chevron.left") {
                    withAnimation(.spring(duration: 0.35)) {
                        checkoutStep = .browse
                    }
                }

                ClipActionButton(title: "Pay Now", icon: "checkmark.circle.fill") {
                    orderCode = randomCode()
                    withAnimation(.spring(duration: 0.35)) {
                        checkoutStep = .success
                    }
                }
            }
            .padding(.horizontal, 20)

            Spacer()
        }
        .padding(.bottom, 16)
    }
    
    private var successView: some View {
        VStack(spacing: 20) {
            Spacer()
            ClipSuccessOverlay(
                message: "Order# \(orderCode)\nPlease pick up your items at the store with this number"
            )
            Spacer()
        }
    }
    
    private var totalPrice: String {
        let total = cart.reduce(0) { $0 + $1.price }
        return String(format: "$%.2f", total)
    }
    
    private func randomCode(length: Int = 5) -> String {
        let characters = "0123456789"
        return String((0..<length).compactMap { _ in characters.randomElement() })
    }
    
    func startStockTimer() {
        timer?.invalidate()
        timer = nil
        stockFailed = false
        stockStatus = "Waiting for store verification..."
        secondsRemaining = 10

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { t in
            secondsRemaining -= 1

            let storeResponds = Int.random(in: 1...10) == 1

            if storeResponds {
                t.invalidate()

                let failed = Int.random(in: 1...4) == 1

                if failed {
                    stockFailed = true
                } else {
                    checkoutStep = .checkout
                }

                return
            }
            
            if secondsRemaining <= 0 {
                        t.invalidate()
                        stockFailed = true
            }
        }
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

#Preview {
    CanaLocalShopClipExperience(context: .init(invocationURL: URL(string: "canalocal.ca/stores/goodstore")!))
}

