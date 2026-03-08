import SwiftUI

// MARK: - Menu Data

private struct MenuItem: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let price: Double
    let category: MenuCategory
    let imageName: String?
    let systemImage: String
}

private enum MenuCategory: String, CaseIterable {
    case recommended  = "For You"
    case signatureBuns = "Buns"
    case appetizers   = "Appetizers"
    case noodles      = "Noodles & Rice"
    case chicken      = "Fried Chicken"
    case drinks       = "Drinks"

    var icon: String {
        switch self {
        case .recommended:   return "sparkles"
        case .signatureBuns: return "circle.grid.3x3.fill"
        case .appetizers:    return "leaf"
        case .noodles:       return "fork.knife"
        case .chicken:       return "bolt.fill"
        case .drinks:        return "cup.and.saucer.fill"
        }
    }
}

private struct CartEntry: Identifiable {
    let id = UUID()
    let item: MenuItem
    var quantity: Int
}

private let allMenuItems: [MenuItem] = [
    MenuItem(name: "Braised Pork Pan-Fried Buns",   description: "Crispy-bottom buns, slow-braised pork. 4 pcs.",     price: 12.99, category: .signatureBuns, imageName: "braisedporkpanfriedbuns",   systemImage: "circle.grid.3x3.fill"),
    MenuItem(name: "Fresh Pork Pan-Fried Buns",     description: "Juicy fresh pork, golden bottom. 4 pcs.",           price: 11.99, category: .signatureBuns, imageName: "freshporkpanfriedbuns",     systemImage: "circle.grid.3x3.fill"),
    MenuItem(name: "Mom's Soup Dumplings",           description: "Thin-skin dumplings, savory pork broth. 6 pcs.",   price: 13.99, category: .signatureBuns, imageName: "soupdumplings",             systemImage: "drop.circle.fill"),
    MenuItem(name: "Siu Mai Bamboo & Sticky Rice",  description: "Steamed dumplings, pork, rice, bamboo. 4 pcs.",    price: 10.99, category: .signatureBuns, imageName: "siumai",                    systemImage: "seal.fill"),
    MenuItem(name: "Spicy Vinegar Tofu Skin",        description: "Tofu skin in Sichuan vinegar chili dressing.",     price:  8.99, category: .appetizers,    imageName: "spicyvinegartofuskin",      systemImage: "flame.fill"),
    MenuItem(name: "Garlic Sliced Pork Belly",       description: "Sliced pork belly, chili garlic sauce, sesame.",   price:  9.99, category: .appetizers,    imageName: "garlic sliced pork belly",  systemImage: "leaf.fill"),
    MenuItem(name: "Pickled Vinegar Peanuts",        description: "Crispy peanuts, aged black vinegar, coriander.",   price:  5.99, category: .appetizers,    imageName: "pickledvinegarpeanuts",     systemImage: "leaf"),
    MenuItem(name: "Classic Beef Noodle Soup",       description: "Braised beef, hand-pulled noodles, bone broth.",   price: 14.99, category: .noodles,       imageName: "classicbeefnoodlesoup",     systemImage: "flame.fill"),
    MenuItem(name: "Braised Beef Noodle Soup",       description: "Red-braised beef, wide noodles, Sichuan broth.",   price: 15.99, category: .noodles,       imageName: "braisedbeefnoodlesoup",     systemImage: "flame"),
    MenuItem(name: "Grilled Pork Belly Egg on Rice", description: "Charcoal pork belly, soft egg, jasmine rice.",    price: 12.99, category: .noodles,       imageName: "grilledporkbellyeggonrice", systemImage: "bowl.fill"),
    MenuItem(name: "Magic Fried Chicken Wings",      description: "Crispy wings in sweet-spicy sesame glaze.",        price: 13.99, category: .chicken,       imageName: "magicfriedchickenwings",    systemImage: "bolt.fill"),
    MenuItem(name: "Crispy Fried Chicken Bites",     description: "Five-spice marinated chicken, fried golden.",      price: 11.99, category: .chicken,       imageName: "crispyfriedchickenbites",   systemImage: "bolt"),
    MenuItem(name: "Sour Plum Drink",                description: "House-made sour plum, rock sugar, osmanthus.",    price:  4.99, category: .drinks,        imageName: "sourplumdrink",             systemImage: "drop.fill"),
    MenuItem(name: "Sweet Soy Milk",                 description: "Freshly pressed soy milk, lightly sweetened.",    price:  3.99, category: .drinks,        imageName: "sweetsoymilk",              systemImage: "cup.and.saucer.fill"),
]

// MARK: - Experience
//
// URL: momsgoldendumplings.com/reserve/:flow
//   waitlist  → join waitlist (QR at entrance — default)
//   feedback  → post-meal star rating → SERVD15 reward → takeout menu
//   offer     → tonight's pan-fried buns promo
//
// 8h Notification window:
//   1. ~20 min  "Your table is ready!"                       → table alert
//   2. ~2 h     "How was your meal? Get 15% off takeout."    → /reserve/feedback
//   3. ~6 h     "Still hungry? Free buns expire tonight."    → /reserve/offer

struct TeamKiizonRestaurantExperience: ClipExperience {

    static let urlPattern      = "momsgoldendumplings.com/reserve/:flow"
    static let clipName        = "Servd"
    static let clipDescription = "Reserve a table or join the waitlist instantly."
    static let teamName        = "Team Kiizon"
    static let touchpoint: JourneyTouchpoint  = .onSite
    static let invocationSource: InvocationSource = .qrCode

    static let notifications: [NotificationTemplate] = [
        NotificationTemplate(
            title: "Your table is ready! 🍜",
            body: "Head to the host — we're holding your table.",
            journeyStage: "On-site",
            triggerDescription: "~20 min after joining waitlist",
            delayFromInvocation: 20 * 60
        ),
        NotificationTemplate(
            title: "How was your meal?",
            body: "Rate us and get 15% off your next takeout order.",
            journeyStage: "Post-visit",
            triggerDescription: "~2 h after seating → opens feedback + menu",
            delayFromInvocation: 2 * 3600
        ),
        NotificationTemplate(
            title: "Still hungry? 🥟",
            body: "Your free Pan-Fried Buns reward expires tonight.",
            journeyStage: "Re-engagement",
            triggerDescription: "~6 h later → opens offer screen",
            delayFromInvocation: 6 * 3600
        ),
    ]

    static let demoURLs: [(label: String, url: String)] = [
        ("Join Waitlist",    "momsgoldendumplings.com/reserve/waitlist"),
        ("Feedback + Menu",  "momsgoldendumplings.com/reserve/feedback"),
        ("Tonight's Offer",  "momsgoldendumplings.com/reserve/offer"),
    ]

    // MARK: State

    let context: ClipContext

    // waitlist
    @State private var partySize = 2
    @State private var joined = false
    // feedback
    @State private var rating = 0
    @State private var feedbackDone = false
    @State private var showMenu = false
    // menu
    @State private var selectedCategory: MenuCategory = .recommended
    @State private var cart: [CartEntry] = []
    @State private var showCart = false
    @State private var orderPlaced = false
    // offer
    @State private var showOfferMenu = false

    // MARK: Helpers

    private var flow: String { context.pathParameters["flow"] ?? "waitlist" }

    // SERVD15 — 15% off entire order (feedback flow)
    private var isServd15Active: Bool { flow == "feedback" }
    // DUMPLING2025 — free Pan-Fried Buns item (offer flow)
    private var isDumpling2025Active: Bool { flow == "offer" }

    private var freeBunPrice: Double {
        cart.first(where: { $0.item.name.contains("Pan-Fried Buns") })?.item.price ?? 0
    }

    private var filtered: [MenuItem] {
        selectedCategory == .recommended
            ? Array(allMenuItems.prefix(6))
            : allMenuItems.filter { $0.category == selectedCategory }
    }
    private var cartCount: Int    { cart.reduce(0) { $0 + $1.quantity } }
    private var subtotal:  Double { cart.reduce(0) { $0 + $1.item.price * Double($1.quantity) } }
    private var discount:  Double {
        if isServd15Active      { return subtotal * 0.15 }
        if isDumpling2025Active { return freeBunPrice }
        return 0
    }
    private var total: Double { subtotal - discount + (subtotal - discount) * 0.13 }

    // MARK: Body

    var body: some View {
        ZStack {
            switch flow {
            case "feedback": feedbackRoot
            case "offer":    offerRoot
            default:         waitlistRoot
            }
        }
        .animation(.spring(duration: 0.35), value: joined)
        .animation(.spring(duration: 0.35), value: feedbackDone)
        .animation(.spring(duration: 0.35), value: showMenu)
        .animation(.spring(duration: 0.35), value: showOfferMenu)
        .animation(.spring(duration: 0.3),  value: showCart)
        .animation(.spring(duration: 0.35), value: orderPlaced)
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: - Waitlist
    // ─────────────────────────────────────────────────────────────

    @ViewBuilder
    private var waitlistRoot: some View {
        if joined {
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.orange)
                        .padding(.top, 48)

                    VStack(spacing: 6) {
                        Text("You're on the list!")
                            .font(.system(size: 24, weight: .bold))
                        Text("Party of \(partySize)  ·  ~15 min wait")
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)
                    }

                    Text("We'll send you a notification\nwhen your table is ready.")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .transition(.opacity.combined(with: .scale(scale: 0.97)))
        } else {
            ScrollView {
                VStack(spacing: 16) {
                    // Hero
                    VStack(spacing: 6) {
                        if let img = UIImage(named: "hero-bg") {
                            Image(uiImage: img)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 120)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        Text("Mom's Golden Dumplings")
                            .font(.system(size: 20, weight: .bold))
                        Text("Reserve a table instantly")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)

                    // Card
                    VStack(spacing: 16) {
                        // Wait time
                        HStack {
                            Label("Current wait", systemImage: "clock.fill")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("~15 min")
                                .fontWeight(.semibold)
                        }
                        .font(.system(size: 15))

                        Divider()

                        // Party size
                        HStack {
                            Label("Party size", systemImage: "person.2.fill")
                                .foregroundStyle(.secondary)
                            Spacer()
                            HStack(spacing: 20) {
                                Button {
                                    if partySize > 1 { partySize -= 1 }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 32))
                                        .foregroundStyle(partySize > 1 ? Color.orange : Color.gray.opacity(0.35))
                                }
                                .buttonStyle(.plain)

                                Text("\(partySize)")
                                    .font(.system(size: 24, weight: .bold))
                                    .monospacedDigit()
                                    .frame(minWidth: 28)

                                Button {
                                    if partySize < 8 { partySize += 1 }
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 32))
                                        .foregroundStyle(partySize < 8 ? Color.orange : Color.gray.opacity(0.35))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .font(.system(size: 15))

                        Button {
                            joined = true
                        } label: {
                            Label("Join Waitlist", systemImage: "checkmark.circle.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(Color.orange)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(18)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: - Feedback → Reward → Menu
    // ─────────────────────────────────────────────────────────────

    @ViewBuilder
    private var feedbackRoot: some View {
        if showMenu {
            menuRoot
                .transition(.move(edge: .trailing).combined(with: .opacity))
        } else if feedbackDone {
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(.orange)
                        .padding(.top, 48)

                    Text("Reward unlocked!")
                        .font(.system(size: 22, weight: .bold))

                    VStack(spacing: 4) {
                        Text("SERVD15")
                            .font(.system(size: 28, weight: .black, design: .monospaced))
                            .foregroundStyle(.orange)
                        Text("15% off takeout · valid tonight")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                    .padding(16)
                    .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.orange.opacity(0.35)))

                    Button {
                        showMenu = true
                    } label: {
                        Label("Browse Takeout Menu", systemImage: "fork.knife")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Color.orange)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .transition(.opacity)
        } else {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 6) {
                        Text("How was your meal?")
                            .font(.system(size: 22, weight: .bold))
                            .padding(.top, 32)
                        Text("Quick feedback · unlock 15% off takeout")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 10) {
                        ForEach(1...5, id: \.self) { star in
                            Button {
                                rating = star
                            } label: {
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .font(.system(size: 42))
                                    .foregroundStyle(star <= rating ? Color.orange : Color.gray.opacity(0.3))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Button {
                        feedbackDone = true
                    } label: {
                        Text("Submit & Claim Reward")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(rating > 0 ? Color.orange : Color.gray.opacity(0.3))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                    .disabled(rating == 0)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: - Menu
    // ─────────────────────────────────────────────────────────────

    @ViewBuilder
    private var menuRoot: some View {
        if orderPlaced {
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.orange)
                        .padding(.top, 48)
                    Text("Order Placed!")
                        .font(.system(size: 24, weight: .bold))
                    Text(String(format: "Total  $%.2f  ·  Ready in ~25 min", total))
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        } else if showCart {
            cartView
                .transition(.move(edge: .trailing).combined(with: .opacity))
        } else {
            menuBrowse
        }
    }

    private var menuBrowse: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // Header + tabs (not scrollable, stays fixed)
                VStack(spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Mom's Golden Dumplings")
                                .font(.system(size: 17, weight: .bold))
                            Text("Takeout order")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if isServd15Active || isDumpling2025Active {
                            Label(isServd15Active ? "SERVD15" : "DUMPLING2025", systemImage: "tag.fill")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.orange)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.orange.opacity(0.1), in: Capsule())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(MenuCategory.allCases, id: \.self) { cat in
                                Button {
                                    selectedCategory = cat
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: cat.icon).font(.system(size: 11))
                                        Text(cat.rawValue).font(.system(size: 12, weight: .medium))
                                    }
                                    .foregroundStyle(selectedCategory == cat ? .white : .primary)
                                    .padding(.horizontal, 12).padding(.vertical, 7)
                                    .background(selectedCategory == cat ? Color.orange : Color(.tertiarySystemFill), in: Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 8)
                .background(Color(.systemBackground))

                Divider()

                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(filtered) { item in
                            menuRow(item)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, cart.isEmpty ? 16 : 84)
                }
                .background(Color(.systemGroupedBackground))
            }

            if !cart.isEmpty {
                Button {
                    showCart = true
                } label: {
                    HStack {
                        Text("\(cartCount) item\(cartCount == 1 ? "" : "s")")
                            .fontWeight(.semibold)
                        Spacer()
                        Text(String(format: "$%.2f", total)).fontWeight(.bold)
                        Image(systemName: "chevron.right").font(.system(size: 12, weight: .bold))
                    }
                    .padding(.horizontal, 20).padding(.vertical, 14)
                    .background(Color.orange)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 16).padding(.bottom, 10)
                }
                .buttonStyle(.plain)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3), value: cart.isEmpty)
    }

    @ViewBuilder
    private func menuRow(_ item: MenuItem) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name).font(.system(size: 14, weight: .semibold))
                Text(item.description)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                HStack {
                    Text(String(format: "$%.2f", item.price)).font(.system(size: 14, weight: .bold))
                    Spacer()
                    Button { addToCart(item) } label: {
                        Label("Add", systemImage: "plus.circle.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.orange)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 2)
            }
            Group {
                if let n = item.imageName, let img = UIImage(named: n) {
                    Image(uiImage: img).resizable().aspectRatio(contentMode: .fill)
                } else {
                    Image(systemName: item.systemImage)
                        .font(.system(size: 22)).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.tertiarySystemFill))
                }
            }
            .frame(width: 72, height: 72)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(12)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Cart

    private var cartView: some View {
        VStack(spacing: 0) {
            HStack {
                Button { showCart = false } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Menu")
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.orange)
                }
                .buttonStyle(.plain)
                Spacer()
                Text("Your Order").font(.system(size: 17, weight: .bold))
                Spacer()
                Color.clear.frame(width: 60)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .background(Color(.systemBackground))

            Divider()

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(cart) { entry in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.item.name).font(.system(size: 14, weight: .semibold))
                                Text(String(format: "$%.2f each", entry.item.price))
                                    .font(.system(size: 12)).foregroundStyle(.secondary)
                            }
                            Spacer()
                            HStack(spacing: 14) {
                                Button { decrement(entry) } label: {
                                    Image(systemName: "minus.circle.fill").font(.system(size: 26)).foregroundStyle(Color.orange)
                                }.buttonStyle(.plain)
                                Text("\(entry.quantity)").font(.system(size: 16, weight: .bold)).frame(width: 20)
                                Button { addToCart(entry.item) } label: {
                                    Image(systemName: "plus.circle.fill").font(.system(size: 26)).foregroundStyle(Color.orange)
                                }.buttonStyle(.plain)
                            }
                        }
                        .padding(14)
                        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 14))
                    }

                    VStack(spacing: 8) {
                        cartRow("Subtotal", subtotal)
                        if isServd15Active {
                            HStack {
                                Label("SERVD15 — 15% off", systemImage: "tag.fill").foregroundStyle(.orange)
                                Spacer()
                                Text(String(format: "-$%.2f", discount)).fontWeight(.semibold).foregroundStyle(.orange)
                            }
                            .font(.system(size: 14))
                        } else if isDumpling2025Active && freeBunPrice > 0 {
                            HStack {
                                Label("DUMPLING2025 — Pan-Fried Buns FREE", systemImage: "tag.fill").foregroundStyle(.orange)
                                Spacer()
                                Text(String(format: "-$%.2f", freeBunPrice)).fontWeight(.semibold).foregroundStyle(.orange)
                            }
                            .font(.system(size: 14))
                        }
                        cartRow("HST (13%)", (subtotal - discount) * 0.13)
                        Divider()
                        HStack {
                            Text("Total").font(.system(size: 16, weight: .bold))
                            Spacer()
                            Text(String(format: "$%.2f", total)).font(.system(size: 16, weight: .bold))
                        }
                    }
                    .padding(14)
                    .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 16)
            }
            .background(Color(.systemGroupedBackground))

            Divider()
            Button { orderPlaced = true } label: {
                HStack(spacing: 8) {
                    Image(systemName: "apple.logo")
                    Text("Pay with Apple Pay").fontWeight(.bold)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 15)
                .background(Color.black).foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16).padding(.vertical, 14)
            .background(Color(.systemBackground))
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }

    @ViewBuilder
    private func cartRow(_ label: String, _ value: Double) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(String(format: "$%.2f", value))
        }
        .font(.system(size: 14))
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: - Offer  (notification 3)
    // ─────────────────────────────────────────────────────────────

    @ViewBuilder
    private var offerRoot: some View {
        if showOfferMenu {
            menuRoot
                .transition(.move(edge: .trailing).combined(with: .opacity))
        } else {
            ScrollView {
                VStack(spacing: 20) {
                    if let img = UIImage(named: "braisedporkpanfriedbuns") {
                        Image(uiImage: img)
                            .resizable().aspectRatio(contentMode: .fill)
                            .frame(height: 160)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .padding(.top, 8)
                    }

                    VStack(spacing: 6) {
                        Text("Tonight Only 🥟")
                            .font(.system(size: 22, weight: .bold))
                        Text("Your free Pan-Fried Buns reward expires at midnight.")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    Label("DUMPLING2025  ·  Pan-Fried Buns FREE", systemImage: "tag.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 14).padding(.vertical, 10)
                        .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.orange.opacity(0.4)))

                    Button { showOfferMenu = true } label: {
                        Label("Order Takeout Now", systemImage: "cart.badge.plus")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity).padding(.vertical, 15)
                            .background(Color.orange)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
    }

    // MARK: - Cart Helpers

    private func addToCart(_ item: MenuItem) {
        if let i = cart.firstIndex(where: { $0.item.id == item.id }) {
            cart[i].quantity += 1
        } else {
            cart.append(CartEntry(item: item, quantity: 1))
        }
    }

    private func decrement(_ entry: CartEntry) {
        guard let i = cart.firstIndex(where: { $0.id == entry.id }) else { return }
        if cart[i].quantity > 1 { cart[i].quantity -= 1 } else { cart.remove(at: i) }
    }
}
