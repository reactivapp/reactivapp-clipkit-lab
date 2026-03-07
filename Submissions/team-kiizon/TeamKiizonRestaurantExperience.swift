import SwiftUI

// MARK: - Private Data Models

private enum MenuCategory: String, CaseIterable {
    case recommended
    case appetizers
    case mains
    case drinks
    case desserts

    var displayName: String {
        switch self {
        case .recommended: return "For You"
        case .appetizers: return "Starters"
        case .mains: return "Mains"
        case .drinks: return "Drinks"
        case .desserts: return "Desserts"
        }
    }

    var displayNameFR: String {
        switch self {
        case .recommended: return "Pour Vous"
        case .appetizers: return "Entrees"
        case .mains: return "Plats"
        case .drinks: return "Boissons"
        case .desserts: return "Desserts"
        }
    }

    var icon: String {
        switch self {
        case .recommended: return "sparkles"
        case .appetizers: return "leaf"
        case .mains: return "fork.knife"
        case .drinks: return "wineglass"
        case .desserts: return "birthday.cake.fill"
        }
    }
}

private struct BistroMenuItem: Identifiable {
    let id = UUID()
    let name: String
    let nameFR: String
    let description: String
    let descriptionFR: String
    let price: Double
    let category: MenuCategory
    let systemImage: String
    let allergens: [String]
    let calories: Int
}

private struct RestaurantCartEntry: Identifiable {
    let id = UUID()
    let menuItem: BistroMenuItem
    var quantity: Int
    var modifications: String = ""
}

// MARK: - Context Models

private enum WeatherCondition: String {
    case hot, cold, rainy, snowy, mild

    var label: String {
        switch self {
        case .hot:   return "Hot day"
        case .cold:  return "Cold out"
        case .rainy: return "Rainy day"
        case .snowy: return "Snowy"
        case .mild:  return "Nice out"
        }
    }

    var labelFR: String {
        switch self {
        case .hot:   return "Journee chaude"
        case .cold:  return "Froid dehors"
        case .rainy: return "Jour de pluie"
        case .snowy: return "Enneige"
        case .mild:  return "Temps agreable"
        }
    }

    var icon: String {
        switch self {
        case .hot:   return "sun.max.fill"
        case .cold:  return "thermometer.snowflake"
        case .rainy: return "cloud.rain.fill"
        case .snowy: return "snowflake"
        case .mild:  return "cloud.sun.fill"
        }
    }

    var chipColor: Color {
        switch self {
        case .hot:   return .orange
        case .cold:  return .cyan
        case .rainy: return .indigo
        case .snowy: return .teal
        case .mild:  return .green
        }
    }

    var boostedItemNames: Set<String> {
        switch self {
        case .hot:
            return ["Caesar Cocktail", "Craft Beer Flight", "Maple Glazed Salmon",
                    "Wild Arctic Char", "Maple Old Fashioned", "Maple Creme Brulee", "Butter Tart"]
        case .cold, .snowy:
            return ["Classic Poutine", "French Onion Soup", "Tourtiere",
                    "Niagara Hot Apple Cider", "East Coast Lobster Bisque", "Wild Mushroom Risotto"]
        case .rainy:
            return ["French Onion Soup", "Wild Mushroom Risotto", "Classic Poutine",
                    "Tourtiere", "East Coast Lobster Bisque", "Niagara Hot Apple Cider"]
        case .mild:
            return []
        }
    }
}

private enum Holiday: String {
    case canadaDay    = "canada_day"
    case thanksgiving = "thanksgiving"
    case christmas    = "christmas"
    case valentines   = "valentines"
    case halloween    = "halloween"
    case victoriaDay  = "victoria_day"
    case newYears     = "new_years"

    var label: String {
        switch self {
        case .canadaDay:    return "Canada Day"
        case .thanksgiving: return "Thanksgiving"
        case .christmas:    return "Christmas"
        case .valentines:   return "Valentine's Day"
        case .halloween:    return "Halloween"
        case .victoriaDay:  return "Victoria Day"
        case .newYears:     return "New Year's"
        }
    }

    var labelFR: String {
        switch self {
        case .canadaDay:    return "Fete du Canada"
        case .thanksgiving: return "Action de graces"
        case .christmas:    return "Noel"
        case .valentines:   return "Saint-Valentin"
        case .halloween:    return "Halloween"
        case .victoriaDay:  return "Fete de Victoria"
        case .newYears:     return "Jour de l'An"
        }
    }

    var icon: String {
        switch self {
        case .canadaDay:    return "maple.leaf"
        case .thanksgiving: return "leaf.fill"
        case .christmas:    return "snowflake"
        case .valentines:   return "heart.fill"
        case .halloween:    return "moon.stars.fill"
        case .victoriaDay:  return "crown.fill"
        case .newYears:     return "sparkles"
        }
    }

    var chipColor: Color {
        switch self {
        case .canadaDay:    return .red
        case .thanksgiving: return .orange
        case .christmas:    return .green
        case .valentines:   return .pink
        case .halloween:    return .purple
        case .victoriaDay:  return .blue
        case .newYears:     return .yellow
        }
    }

    var featuredItemNames: Set<String> {
        switch self {
        case .canadaDay:
            return ["Classic Poutine", "Caesar Cocktail", "Maple Glazed Salmon",
                    "Maple Old Fashioned", "Maple Creme Brulee"]
        case .thanksgiving:
            return ["Tourtiere", "Quebec Cheese Plate", "Maple Creme Brulee",
                    "East Coast Lobster Bisque", "Craft Beer Flight"]
        case .christmas:
            return ["Tourtiere", "Niagara Hot Apple Cider", "Quebec Cheese Plate",
                    "Maple Creme Brulee", "French Onion Soup"]
        case .valentines:
            return ["Wild Arctic Char", "Maple Creme Brulee", "Maple Old Fashioned",
                    "Quebec Cheese Plate", "East Coast Lobster Bisque"]
        case .halloween:
            return ["Classic Poutine", "Butter Tart", "Maple Old Fashioned",
                    "Craft Beer Flight", "Wild Mushroom Risotto"]
        case .victoriaDay:
            return ["Caesar Cocktail", "Craft Beer Flight", "Classic Poutine",
                    "Maple Glazed Salmon", "Quebec Cheese Plate"]
        case .newYears:
            return ["Maple Old Fashioned", "Quebec Cheese Plate", "Wild Arctic Char",
                    "Maple Creme Brulee", "East Coast Lobster Bisque"]
        }
    }
}

private struct MenuContext {
    let weather: WeatherCondition?
    let holiday: Holiday?
    let hour: Int
}

// MARK: - Mock Menu Data

private let bistroMenu: [BistroMenuItem] = [
    BistroMenuItem(
        name: "Classic Poutine",
        nameFR: "Poutine Classique",
        description: "Hand-cut fries, St-Albert cheese curds, rich veal gravy.",
        descriptionFR: "Frites maison, fromage en grains St-Albert, sauce au veau.",
        price: 16.99, category: .mains, systemImage: "flame.fill",
        allergens: ["Dairy", "Gluten"], calories: 890
    ),
    BistroMenuItem(
        name: "Smoked Meat Sandwich",
        nameFR: "Sandwich au Smoked Meat",
        description: "Montreal-style beef brisket on rye with Dijon mustard.",
        descriptionFR: "Brisket style Montreal sur seigle, moutarde de Dijon.",
        price: 19.99, category: .mains, systemImage: "tray.fill",
        allergens: ["Gluten", "Mustard"], calories: 720
    ),
    BistroMenuItem(
        name: "Maple Glazed Salmon",
        nameFR: "Saumon Glace a l'Erable",
        description: "Atlantic salmon, Quebec maple glaze, wild rice, seasonal greens.",
        descriptionFR: "Saumon Atlantique, glaçage a l'erable, riz sauvage.",
        price: 32.99, category: .mains, systemImage: "fish.fill",
        allergens: ["Fish"], calories: 580
    ),
    BistroMenuItem(
        name: "Tourtiere",
        nameFR: "Tourtiere",
        description: "Traditional Quebec meat pie, pork and veal, with spiced chutney.",
        descriptionFR: "Tourtiere quebecoise, porc et veau, chutney epice.",
        price: 22.99, category: .mains, systemImage: "pie.chart.fill",
        allergens: ["Gluten", "Dairy"], calories: 810
    ),
    BistroMenuItem(
        name: "Caesar Cocktail",
        nameFR: "Cesar",
        description: "Invented in Calgary. Clamato, vodka, Worcestershire, hot sauce, celery salt rim.",
        descriptionFR: "Invente a Calgary. Clamato, vodka, Worcestershire, tabasco.",
        price: 14.99, category: .drinks, systemImage: "wineglass.fill",
        allergens: ["Shellfish", "Celery"], calories: 180
    ),
    BistroMenuItem(
        name: "East Coast Lobster Bisque",
        nameFR: "Bisque de Homard des Maritimes",
        description: "East Coast lobster, cream, sherry, fresh chives.",
        descriptionFR: "Homard des Maritimes, creme, sherry, ciboulette fraiche.",
        price: 14.99, category: .appetizers, systemImage: "cup.and.saucer.fill",
        allergens: ["Shellfish", "Dairy"], calories: 310
    ),
    BistroMenuItem(
        name: "Butter Tart",
        nameFR: "Tartelette au Sucre",
        description: "Flaky pastry shell, brown sugar filling, optional pecans.",
        descriptionFR: "Pate feuilletee, garniture au sucre brun, noix de pecan en option.",
        price: 5.99, category: .desserts, systemImage: "star.fill",
        allergens: ["Gluten", "Dairy", "Eggs"], calories: 290
    ),
    BistroMenuItem(
        name: "French Onion Soup",
        nameFR: "Soupe a l'Oignon Gratinee",
        description: "Caramelized Vidalia onions, beef broth, Gruyere crouton.",
        descriptionFR: "Oignons Vidalia caramelises, bouillon de boeuf, crouton Gruyere.",
        price: 13.99, category: .appetizers, systemImage: "flame",
        allergens: ["Gluten", "Dairy"], calories: 420
    ),
    BistroMenuItem(
        name: "Wild Mushroom Risotto",
        nameFR: "Risotto aux Champignons Sauvages",
        description: "Chanterelles, porcini, aged Parmesan, truffle oil.",
        descriptionFR: "Girolles, cepes, Parmesan affine, huile de truffe.",
        price: 24.99, category: .mains, systemImage: "leaf.fill",
        allergens: ["Dairy"], calories: 640
    ),
    BistroMenuItem(
        name: "Craft Beer Flight",
        nameFR: "Plateau de Bieres Artisanales",
        description: "Four 4oz pours from local Canadian craft breweries.",
        descriptionFR: "Quatre 120ml de brasseries artisanales canadiennes.",
        price: 18.99, category: .drinks, systemImage: "mug.fill",
        allergens: ["Gluten"], calories: 320
    ),
    BistroMenuItem(
        name: "Maple Old Fashioned",
        nameFR: "Vieux Fashioned a l'Erable",
        description: "Rye whisky, Quebec maple syrup, Angostura bitters, orange zest.",
        descriptionFR: "Whisky de seigle, sirop d'erable, bitters Angostura, zeste d'orange.",
        price: 16.99, category: .drinks, systemImage: "drop.fill",
        allergens: [], calories: 210
    ),
    BistroMenuItem(
        name: "Quebec Cheese Plate",
        nameFR: "Plateau de Fromages du Quebec",
        description: "Three artisan Quebec cheeses, honeycomb, fig jam, and crackers.",
        descriptionFR: "Trois fromages artisanaux quebecois, miel, confiture de figues, biscuits.",
        price: 22.99, category: .appetizers, systemImage: "square.grid.2x2.fill",
        allergens: ["Dairy", "Gluten"], calories: 580
    ),
    BistroMenuItem(
        name: "Wild Arctic Char",
        nameFR: "Omble Chevalier Sauvage",
        description: "Wild Canadian Arctic char, lemon beurre blanc, grilled asparagus.",
        descriptionFR: "Omble chevalier canadien, beurre blanc citron, asperges grillees.",
        price: 36.99, category: .mains, systemImage: "water.waves",
        allergens: ["Fish", "Dairy"], calories: 490
    ),
    BistroMenuItem(
        name: "Maple Creme Brulee",
        nameFR: "Creme Brulee a l'Erable",
        description: "Classic creme brulee with a Quebec maple sugar crust.",
        descriptionFR: "Creme brulee classique, croute de sucre d'erable du Quebec.",
        price: 10.99, category: .desserts, systemImage: "sparkles",
        allergens: ["Dairy", "Eggs"], calories: 380
    ),
    BistroMenuItem(
        name: "Niagara Hot Apple Cider",
        nameFR: "Cidre Chaud du Niagara",
        description: "Warmed Niagara apple cider with cinnamon and cloves.",
        descriptionFR: "Cidre de pommes chaud du Niagara, cannelle et clous de girofle.",
        price: 6.99, category: .drinks, systemImage: "cup.and.saucer",
        allergens: [], calories: 140
    ),
]

private let restaurantNotifications: [NotificationTemplate] = [
    NotificationTemplate(
        title: "How was your meal at Bistro Nordique?",
        body: "Share your experience and help us improve. Takes 30 seconds.",
        journeyStage: "Post-Meal",
        triggerDescription: "Sent 2 hours after order",
        delayFromInvocation: 60 * 60 * 2
    ),
    NotificationTemplate(
        title: "Craving more? Order ahead for pickup.",
        body: "Skip the wait. Browse our menu and pay with Apple Pay before you arrive.",
        journeyStage: "Re-engagement",
        triggerDescription: "Sent 6 hours after order",
        delayFromInvocation: 60 * 60 * 6
    ),
]

// MARK: - Menu Item Card

private struct BistroMenuItemCard: View {
    let item: BistroMenuItem
    let isFrench: Bool
    let onAdd: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: item.systemImage)
                .font(.system(size: 20))
                .foregroundStyle(.secondary)
                .frame(width: 44, height: 44)
                .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .top) {
                    Text(isFrench ? item.nameFR : item.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                    Spacer()
                    Text(String(format: "$%.2f", item.price))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.primary)
                }

                Text(isFrench ? item.descriptionFR : item.description)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                HStack(spacing: 4) {
                    ForEach(item.allergens.prefix(3), id: \.self) { allergen in
                        Text(allergen)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(.quaternarySystemFill), in: Capsule())
                    }
                    Spacer()
                    Text("\(item.calories) cal")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }

                Button(action: onAdd) {
                    Label(isFrench ? "Ajouter" : "Add to order", systemImage: "plus.circle.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            }
        }
        .padding(14)
        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Main Experience

struct TeamKiizonRestaurantExperience: ClipExperience {
    static let urlPattern = "example.com/team-kiizon/:tableNumber"
    static let clipName = "Bistro Nordique"
    static let clipDescription = "AI-powered ordering that adapts to weather, holidays, and time of day. Pay with Apple Pay."
    static let teamName = "Team Kiizon"
    static let touchpoint: JourneyTouchpoint = .onSite
    static let invocationSource: InvocationSource = .qrCode

    let context: ClipContext

    private enum OrderScreen { case browsing, cart, orderConfirmed, feedback }

    @State private var screen: OrderScreen = .browsing
    @State private var selectedCategory: MenuCategory = .recommended
    @State private var cartEntries: [RestaurantCartEntry] = []
    @State private var starRating: Int = 0
    @State private var feedbackText: String = ""
    @State private var feedbackSubmitted: Bool = false
    @State private var expandedModificationID: UUID?

    // MARK: Computed Helpers

    private var tableNumber: String {
        context.pathParameters["tableNumber"] ?? "1"
    }

    private var isFrench: Bool {
        Locale.current.language.languageCode?.identifier == "fr"
    }

    private var menuContext: MenuContext {
        let hourOverride = context.queryParameters["hour"].flatMap { Int($0) }
        let hour = hourOverride ?? Calendar.current.component(.hour, from: Date())
        let weather = context.queryParameters["weather"].flatMap { WeatherCondition(rawValue: $0) }
        let holiday = context.queryParameters["holiday"].flatMap { Holiday(rawValue: $0) }
        return MenuContext(weather: weather, holiday: holiday, hour: hour)
    }

    private func timeBasedCategories(hour: Int) -> Set<MenuCategory> {
        switch hour {
        case 6..<11:  return [.drinks, .appetizers]
        case 11..<14: return [.mains, .appetizers]
        case 17..<21: return [.appetizers, .mains]
        case 21..<24: return [.desserts, .drinks]
        default:      return [.mains, .drinks]
        }
    }

    private func timeLabel(hour: Int) -> String {
        switch hour {
        case 6..<11:  return isFrench ? "Matin"       : "Morning"
        case 11..<14: return isFrench ? "Diner"        : "Lunch"
        case 14..<17: return isFrench ? "Apres-midi"  : "Afternoon"
        case 17..<21: return isFrench ? "Souper"       : "Dinner"
        default:      return isFrench ? "Soiree"       : "Late night"
        }
    }

    private func timeIcon(hour: Int) -> String {
        switch hour {
        case 6..<12:  return "sunrise.fill"
        case 12..<17: return "sun.max.fill"
        case 17..<21: return "sunset.fill"
        default:      return "moon.fill"
        }
    }

    private func itemScore(_ item: BistroMenuItem, ctx: MenuContext) -> Int {
        var score = 0
        if timeBasedCategories(hour: ctx.hour).contains(item.category) { score += 1 }
        if let weather = ctx.weather, weather.boostedItemNames.contains(item.name) { score += 3 }
        if let holiday = ctx.holiday, holiday.featuredItemNames.contains(item.name) { score += 5 }
        return score
    }

    private var aiRecommended: [BistroMenuItem] {
        let ctx = menuContext
        return bistroMenu.sorted { itemScore($0, ctx: ctx) > itemScore($1, ctx: ctx) }.prefix(6).map { $0 }
    }

    private var filteredMenu: [BistroMenuItem] {
        selectedCategory == .recommended
            ? aiRecommended
            : bistroMenu.filter { $0.category == selectedCategory }
    }

    private var cartCount: Int {
        cartEntries.reduce(0) { $0 + $1.quantity }
    }

    private var subtotal: Double {
        cartEntries.reduce(0) { $0 + $1.menuItem.price * Double($1.quantity) }
    }

    private var hst: Double { subtotal * 0.13 }
    private var orderTotal: Double { subtotal + hst }

    // MARK: Cart Mutations

    private func addToCart(_ item: BistroMenuItem) {
        if let i = cartEntries.firstIndex(where: { $0.menuItem.id == item.id }) {
            cartEntries[i].quantity += 1
        } else {
            cartEntries.append(RestaurantCartEntry(menuItem: item, quantity: 1))
        }
    }

    private func incrementEntry(_ entry: RestaurantCartEntry) {
        if let i = cartEntries.firstIndex(where: { $0.id == entry.id }) {
            cartEntries[i].quantity += 1
        }
    }

    private func decrementEntry(_ entry: RestaurantCartEntry) {
        if let i = cartEntries.firstIndex(where: { $0.id == entry.id }) {
            if cartEntries[i].quantity > 1 {
                cartEntries[i].quantity -= 1
            } else {
                cartEntries.remove(at: i)
            }
        }
    }

    private func modificationBinding(for entry: RestaurantCartEntry) -> Binding<String> {
        Binding(
            get: { cartEntries.first(where: { $0.id == entry.id })?.modifications ?? "" },
            set: { newVal in
                if let i = cartEntries.firstIndex(where: { $0.id == entry.id }) {
                    cartEntries[i].modifications = newVal
                }
            }
        )
    }

    private func currentModification(for entry: RestaurantCartEntry) -> String {
        cartEntries.first(where: { $0.id == entry.id })?.modifications ?? ""
    }

    // MARK: Body

    var body: some View {
        ZStack {
            ClipBackground()
            switch screen {
            case .browsing:
                browsingScreen
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            case .cart:
                cartScreen
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .orderConfirmed:
                confirmedScreen
                    .transition(.scale(scale: 0.95).combined(with: .opacity))
            case .feedback:
                feedbackScreen
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.35), value: screen)
    }

    // MARK: - Browsing Screen

    private var browsingScreen: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 16) {
                    ClipHeader(
                        title: "Bistro Nordique",
                        subtitle: "Table \(tableNumber)",
                        systemImage: "fork.knife"
                    )
                    .padding(.top, 12)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(MenuCategory.allCases, id: \.self) { cat in
                                categoryPill(cat)
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    if selectedCategory == .recommended {
                        contextBanner
                    }

                    LazyVStack(spacing: 10) {
                        ForEach(filteredMenu) { item in
                            BistroMenuItemCard(
                                item: item,
                                isFrench: isFrench,
                                onAdd: { addToCart(item) }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, cartEntries.isEmpty ? 16 : 88)
                }
            }
            .scrollIndicators(.hidden)

            if !cartEntries.isEmpty {
                floatingCartBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3), value: cartEntries.isEmpty)
    }

    private func categoryPill(_ category: MenuCategory) -> some View {
        Button {
            withAnimation(.spring(duration: 0.25)) { selectedCategory = category }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.system(size: 12, weight: .medium))
                Text(isFrench ? category.displayNameFR : category.displayName)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(selectedCategory == category ? .white : .primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                selectedCategory == category ? Color.blue : Color(.tertiarySystemFill),
                in: Capsule()
            )
        }
        .buttonStyle(.plain)
    }

    private var contextBanner: some View {
        let ctx = menuContext
        return VStack(alignment: .leading, spacing: 6) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    contextChip(
                        icon: timeIcon(hour: ctx.hour),
                        label: timeLabel(hour: ctx.hour),
                        color: .blue
                    )
                    if let weather = ctx.weather {
                        contextChip(
                            icon: weather.icon,
                            label: isFrench ? weather.labelFR : weather.label,
                            color: weather.chipColor
                        )
                    }
                    if let holiday = ctx.holiday {
                        contextChip(
                            icon: holiday.icon,
                            label: isFrench ? holiday.labelFR : holiday.label,
                            color: holiday.chipColor
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
            Text(isFrench ? "Personnalise pour votre visite" : "Personalized for your visit")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)
        }
    }

    private func contextChip(icon: String, label: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
            Text(label)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.15), in: Capsule())
    }

    private var floatingCartBar: some View {
        Button {
            withAnimation(.spring(duration: 0.35)) { screen = .cart }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.25))
                        .frame(width: 28, height: 28)
                    Text("\(cartCount)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                }
                Text(isFrench ? "Voir le panier" : "View Cart")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer()
                Text(String(format: "$%.2f", subtotal))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(.blue, in: RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    // MARK: - Cart Screen

    private var cartScreen: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack {
                    Button {
                        withAnimation(.spring(duration: 0.35)) { screen = .browsing }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Menu")
                                .font(.system(size: 15, weight: .medium))
                        }
                        .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                ClipHeader(
                    title: isFrench ? "Votre commande" : "Your Order",
                    subtitle: "Table \(tableNumber)",
                    systemImage: "cart.fill"
                )

                VStack(spacing: 8) {
                    ForEach(cartEntries) { entry in
                        cartItemRow(entry)
                    }
                }
                .padding(.horizontal, 16)

                VStack(spacing: 0) {
                    pricingRow(label: isFrench ? "Sous-total" : "Subtotal", value: subtotal)
                    Divider().padding(.horizontal, 14)
                    pricingRow(label: isFrench ? "TPS/TVH (13%)" : "HST (13%)", value: hst)
                    Divider().padding(.horizontal, 14)
                    pricingRow(label: "Total", value: orderTotal, isBold: true)
                }
                .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 16)

                ClipActionButton(
                    title: isFrench ? "Payer avec Apple Pay" : "Pay with Apple Pay",
                    icon: "apple.logo",
                    style: .primary
                ) {
                    withAnimation(.spring(duration: 0.35)) { screen = .orderConfirmed }
                }
                .padding(.bottom, 16)
            }
        }
        .scrollIndicators(.hidden)
    }

    private func cartItemRow(_ entry: RestaurantCartEntry) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: entry.menuItem.systemImage)
                    .font(.system(size: 18))
                    .foregroundStyle(.secondary)
                    .frame(width: 36, height: 36)
                    .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 2) {
                    Text(isFrench ? entry.menuItem.nameFR : entry.menuItem.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text(String(format: "$%.2f", entry.menuItem.price))
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 14) {
                    Button { decrementEntry(entry) } label: {
                        Image(systemName: entry.quantity == 1 ? "trash" : "minus.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(entry.quantity == 1 ? Color.red : Color.secondary)
                    }
                    .buttonStyle(.plain)

                    Text("\(entry.quantity)")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(minWidth: 18)

                    Button { incrementEntry(entry) } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(14)

            if expandedModificationID == entry.id {
                VStack(alignment: .leading, spacing: 8) {
                    TextField(
                        isFrench ? "Sans oignons, sauce supplementaire..." : "No onions, extra sauce...",
                        text: modificationBinding(for: entry),
                        axis: .vertical
                    )
                    .font(.system(size: 13))
                    .lineLimit(1...3)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.secondarySystemFill), in: RoundedRectangle(cornerRadius: 8))
                    .padding(.horizontal, 14)

                    Button(isFrench ? "Terminer" : "Done") {
                        withAnimation(.spring(duration: 0.2)) { expandedModificationID = nil }
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.blue)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal, 14)
                }
                .padding(.bottom, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            } else if !currentModification(for: entry).isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "note.text")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Text(currentModification(for: entry))
                        .font(.system(size: 12))
                        .italic()
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Spacer()
                    Button {
                        withAnimation(.spring(duration: 0.2)) { expandedModificationID = entry.id }
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 12))
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 10)
                .transition(.opacity)
            } else {
                Button {
                    withAnimation(.spring(duration: 0.2)) { expandedModificationID = entry.id }
                } label: {
                    Label(
                        isFrench ? "Ajouter une note" : "Add note",
                        systemImage: "note.text"
                    )
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 14)
                .padding(.bottom, 10)
            }
        }
        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 14))
        .animation(.spring(duration: 0.2), value: expandedModificationID)
    }

    private func pricingRow(label: String, value: Double, isBold: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: isBold ? .semibold : .regular))
                .foregroundStyle(AnyShapeStyle(isBold ? .primary : .secondary))
            Spacer()
            Text(String(format: "$%.2f", value))
                .font(.system(size: 13, weight: isBold ? .bold : .medium))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: - Order Confirmed Screen

    private var confirmedScreen: some View {
        ScrollView {
            VStack(spacing: 20) {
                ClipSuccessOverlay(
                    message: isFrench ? "Commande envoyee en cuisine!" : "Order sent to kitchen!"
                )
                .padding(.top, 16)

                VStack(spacing: 8) {
                    Label("Table \(tableNumber)", systemImage: "fork.knife")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                    Label(
                        isFrench ? "Attente estimee: 15 minutes" : "Estimated wait: 15 minutes",
                        systemImage: "clock"
                    )
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(isFrench ? "VOTRE COMMANDE" : "YOUR ORDER")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(1.2)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 20)

                    VStack(spacing: 0) {
                        ForEach(cartEntries) { entry in
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(isFrench ? entry.menuItem.nameFR : entry.menuItem.name)
                                        .font(.system(size: 13))
                                        .foregroundStyle(.secondary)
                                    if entry.quantity > 1 {
                                        Text("x\(entry.quantity)")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundStyle(.tertiary)
                                    }
                                    Spacer()
                                    Text(String(format: "$%.2f", entry.menuItem.price * Double(entry.quantity)))
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(.primary)
                                }
                                if !entry.modifications.isEmpty {
                                    Text(entry.modifications)
                                        .font(.system(size: 11))
                                        .italic()
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                        }
                        Divider().padding(.horizontal, 14)
                        HStack {
                            Text("Total")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(String(format: "$%.2f", orderTotal))
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.primary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                    }
                    .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 16)
                }

                ClipActionButton(
                    title: isFrench ? "Donnez votre avis" : "Rate Your Experience",
                    icon: "star.fill",
                    style: .secondary
                ) {
                    withAnimation(.spring(duration: 0.35)) { screen = .feedback }
                }

                NotificationTimeline(templates: restaurantNotifications)

                Spacer(minLength: 24)
            }
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Feedback Screen

    private var feedbackScreen: some View {
        ScrollView {
            VStack(spacing: 24) {
                HStack {
                    Button {
                        withAnimation(.spring(duration: 0.35)) { screen = .orderConfirmed }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text(isFrench ? "Retour" : "Back")
                                .font(.system(size: 15, weight: .medium))
                        }
                        .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                if feedbackSubmitted {
                    ClipSuccessOverlay(
                        message: isFrench ? "Merci pour votre avis!" : "Thanks for your feedback!",
                        icon: "heart.fill"
                    )
                    .padding(.top, 40)
                } else {
                    ClipHeader(
                        title: isFrench ? "Votre avis" : "Rate Your Experience",
                        subtitle: "Bistro Nordique",
                        systemImage: "star.fill"
                    )

                    HStack(spacing: 10) {
                        ForEach(1...5, id: \.self) { star in
                            Button {
                                withAnimation(.spring(duration: 0.2)) { starRating = star }
                            } label: {
                                Image(systemName: star <= starRating ? "star.fill" : "star")
                                    .font(.system(size: 38))
                                    .foregroundStyle(star <= starRating ? Color.yellow : Color(.tertiaryLabel))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(isFrench ? "Commentaires (facultatif)" : "Comments (optional)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 20)

                        TextField(
                            isFrench ? "Partagez votre experience..." : "Share your experience...",
                            text: $feedbackText,
                            axis: .vertical
                        )
                        .lineLimit(3...6)
                        .padding(14)
                        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal, 16)
                    }

                    if starRating > 0 {
                        ClipActionButton(
                            title: isFrench ? "Envoyer" : "Submit",
                            icon: "checkmark.circle.fill",
                            style: .primary
                        ) {
                            withAnimation(.spring(duration: 0.35)) { feedbackSubmitted = true }
                        }
                    }
                }
            }
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
    }
}
