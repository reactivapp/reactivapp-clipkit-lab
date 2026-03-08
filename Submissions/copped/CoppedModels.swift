import Foundation

enum CoppedTextPosition: String, Codable, CaseIterable, Identifiable {
    case top
    case center
    case bottom

    var id: String { rawValue }
}

enum CoppedCaptureMode: String, Codable {
    case camera
    case simulator
}

struct CoppedRecordedVideo: Hashable {
    let fileURL: URL?
    let durationSeconds: Int
    let captureMode: CoppedCaptureMode
}

struct CoppedProduct: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let price: Double
    let systemImage: String
    let imageURL: URL?

    init(
        id: String,
        name: String,
        price: Double,
        systemImage: String,
        imageURL: URL? = nil
    ) {
        self.id = id
        self.name = name
        self.price = price
        self.systemImage = systemImage
        self.imageURL = imageURL
    }

    var formattedPrice: String {
        String(format: "$%.2f", price)
    }
}

enum CoppedCatalog {
    static let fallbackProducts: [CoppedProduct] = [
        CoppedProduct(id: "prod_hoodie", name: "Venue Hoodie", price: 75.00, systemImage: "tshirt.fill"),
        CoppedProduct(id: "prod_shirt", name: "Tour T-Shirt", price: 40.00, systemImage: "tshirt"),
        CoppedProduct(id: "prod_vinyl", name: "Limited Vinyl", price: 35.00, systemImage: "opticaldisc.fill"),
        CoppedProduct(id: "prod_hat", name: "Snapback Hat", price: 30.00, systemImage: "baseballcap.fill"),
        CoppedProduct(id: "prod_poster", name: "Signed Poster", price: 20.00, systemImage: "photo.artframe"),
    ]

    private static let lock = NSLock()
    private static var runtimeProductsByID: [String: CoppedProduct] = {
        Dictionary(uniqueKeysWithValues: fallbackProducts.map { ($0.id, $0) })
    }()

    static func updatePublicProducts(_ products: [CoppedProduct]) {
        guard !products.isEmpty else { return }
        lock.lock()
        runtimeProductsByID = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })
        lock.unlock()
    }

    static func allProducts() -> [CoppedProduct] {
        lock.lock()
        let values = Array(runtimeProductsByID.values)
        lock.unlock()

        return values.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    static func product(for id: String) -> CoppedProduct {
        lock.lock()
        let runtime = runtimeProductsByID[id]
        lock.unlock()

        if let runtime {
            return runtime
        }

        return fallbackProducts.first(where: { $0.id == id })
            ?? CoppedProduct(
                id: id,
                name: id.replacingOccurrences(of: "_", with: " ").capitalized,
                price: 25.00,
                systemImage: "shippingbox.fill"
            )
    }
}

struct CoppedClip: Identifiable, Codable, Hashable {
    let id: String
    let receiptID: String
    let creatorDeviceID: String
    var productID: String
    let videoURL: URL
    let textOverlay: String?
    let textPosition: CoppedTextPosition
    let durationSeconds: Int
    let couponCode: String
    var couponRedeemed: Bool
    var conversions: Int
    var bonusCouponCode: String?
    var bonusPushed: Bool
    var bonusRedeemed: Bool
    var isActive: Bool
    let createdAt: Date
    let expiresAt: Date

    var product: CoppedProduct {
        CoppedCatalog.product(for: productID)
    }
}

struct CoppedReceipt: Identifiable, Codable, Hashable {
    let id: String
    var productIDs: [String]
    var clipCreated: Bool
    let createdAt: Date

    var products: [CoppedProduct] {
        productIDs.map(CoppedCatalog.product(for:))
    }
}

struct CoppedConversion: Identifiable, Codable, Hashable {
    let id: String
    let clipID: String
    let orderID: String
    let createdAt: Date
}

struct CoppedUploadURLResponse: Hashable {
    let uploadURL: URL
    let videoURL: URL
    let key: String
}

struct CoppedCreateClipResponse: Hashable {
    let clipID: String
    let walletCode: String
    let instantCreditCents: Int
    let instantCreditDisplay: String
    let passURL: URL
    let availableBalanceCents: Int
    let availableBalanceDisplay: String
    let message: String
}

struct CoppedConversionResponse: Hashable {
    let success: Bool
    let creditedCents: Int
    let creditedDisplay: String
    let availableBalanceCents: Int
    let availableBalanceDisplay: String
    let pushSent: Bool
    let withinPushWindow: Bool
}

struct CoppedCheckoutOutcome: Hashable {
    let orderID: String
    let receiptID: String
    let conversion: CoppedConversionResponse?
}

struct CoppedValidationResult: Hashable {
    let isValid: Bool
    let message: String
    let confidence: Float
    let usedFoundationModels: Bool
}

struct CoppedNotificationEvent: Hashable {
    let clipID: String
    let title: String
    let body: String
    let passURL: URL?
    let createdAt: Date
}

struct CoppedRewardTransaction: Identifiable, Hashable {
    enum Kind: String, Hashable {
        case clipPublished
        case conversion
    }

    let id: String
    let kind: Kind
    let amountCents: Int
    let amountDisplay: String
    let clipID: String
    let orderID: String?
    let createdAt: Date
}

struct CoppedRewardsSnapshot: Hashable {
    let walletCode: String
    let passURL: URL
    let availableBalanceCents: Int
    let availableBalanceDisplay: String
    let lifetimeEarnedCents: Int
    let lifetimeEarnedDisplay: String
    let transactions: [CoppedRewardTransaction]
}

enum CoppedBackendError: LocalizedError {
    case receiptNotFound
    case receiptAlreadyUsed
    case invalidReceipt
    case clipNotFound
    case invalidDuration

    var errorDescription: String? {
        switch self {
        case .receiptNotFound:
            return "Receipt not found. Try scanning a valid creator receipt QR."
        case .receiptAlreadyUsed:
            return "You already created a clip for this receipt."
        case .invalidReceipt:
            return "This receipt is invalid for Copped."
        case .clipNotFound:
            return "Clip not found."
        case .invalidDuration:
            return "Video must be between 5 and 15 seconds."
        }
    }
}

extension Date {
    nonisolated func clipStakesRelativeDescription(reference: Date = Date()) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: reference)
    }
}

extension Int {
    nonisolated var clipStakesCurrencyDisplay: String {
        String(format: "$%.2f", Double(self) / 100.0)
    }
}
