import Foundation

enum ClipStakesTextPosition: String, Codable, CaseIterable, Identifiable {
    case top
    case center
    case bottom

    var id: String { rawValue }
}

enum ClipStakesCaptureMode: String, Codable {
    case camera
    case simulator
}

struct ClipStakesRecordedVideo: Hashable {
    let fileURL: URL?
    let durationSeconds: Int
    let captureMode: ClipStakesCaptureMode
}

struct ClipStakesProduct: Identifiable, Hashable, Codable {
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

enum ClipStakesCatalog {
    static let fallbackProducts: [ClipStakesProduct] = [
        ClipStakesProduct(id: "prod_hoodie", name: "Venue Hoodie", price: 75.00, systemImage: "tshirt.fill"),
        ClipStakesProduct(id: "prod_shirt", name: "Tour T-Shirt", price: 40.00, systemImage: "tshirt"),
        ClipStakesProduct(id: "prod_vinyl", name: "Limited Vinyl", price: 35.00, systemImage: "opticaldisc.fill"),
        ClipStakesProduct(id: "prod_hat", name: "Snapback Hat", price: 30.00, systemImage: "baseballcap.fill"),
        ClipStakesProduct(id: "prod_poster", name: "Signed Poster", price: 20.00, systemImage: "photo.artframe"),
    ]

    private static let lock = NSLock()
    private static var runtimeProductsByID: [String: ClipStakesProduct] = {
        Dictionary(uniqueKeysWithValues: fallbackProducts.map { ($0.id, $0) })
    }()

    static func updatePublicProducts(_ products: [ClipStakesProduct]) {
        guard !products.isEmpty else { return }
        lock.lock()
        runtimeProductsByID = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })
        lock.unlock()
    }

    static func allProducts() -> [ClipStakesProduct] {
        lock.lock()
        let values = Array(runtimeProductsByID.values)
        lock.unlock()

        return values.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    static func product(for id: String) -> ClipStakesProduct {
        lock.lock()
        let runtime = runtimeProductsByID[id]
        lock.unlock()

        if let runtime {
            return runtime
        }

        return fallbackProducts.first(where: { $0.id == id })
            ?? ClipStakesProduct(
                id: id,
                name: id.replacingOccurrences(of: "_", with: " ").capitalized,
                price: 25.00,
                systemImage: "shippingbox.fill"
            )
    }
}

struct ClipStakesClip: Identifiable, Codable, Hashable {
    let id: String
    let receiptID: String
    let deviceToken: String?
    var productID: String
    let videoURL: URL
    let textOverlay: String?
    let textPosition: ClipStakesTextPosition
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

    var product: ClipStakesProduct {
        ClipStakesCatalog.product(for: productID)
    }
}

struct ClipStakesReceipt: Identifiable, Codable, Hashable {
    let id: String
    var productIDs: [String]
    var clipCreated: Bool
    let createdAt: Date

    var products: [ClipStakesProduct] {
        productIDs.map(ClipStakesCatalog.product(for:))
    }
}

struct ClipStakesConversion: Identifiable, Codable, Hashable {
    let id: String
    let clipID: String
    let orderID: String
    let createdAt: Date
}

struct ClipStakesUploadURLResponse: Hashable {
    let uploadURL: URL
    let videoURL: URL
    let key: String
}

struct ClipStakesCreateClipResponse: Hashable {
    let clipID: String
    let couponCode: String
    let couponValue: String
    let passURL: URL
    let message: String
}

struct ClipStakesConversionResponse: Hashable {
    let success: Bool
    let bonusCouponCode: String?
    let bonusPassURL: URL?
    let pushSent: Bool
    let withinPushWindow: Bool
}

struct ClipStakesCheckoutOutcome: Hashable {
    let orderID: String
    let receiptID: String
    let conversion: ClipStakesConversionResponse?
}

struct ClipStakesValidationResult: Hashable {
    let isValid: Bool
    let message: String
    let confidence: Float
    let usedFoundationModels: Bool
}

struct ClipStakesNotificationEvent: Hashable {
    let clipID: String
    let title: String
    let body: String
    let bonusPassURL: URL?
    let createdAt: Date
}

enum ClipStakesBackendError: LocalizedError {
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
            return "This receipt is invalid for ClipStakes."
        case .clipNotFound:
            return "Clip not found."
        case .invalidDuration:
            return "Video must be between 5 and 15 seconds."
        }
    }
}

extension Date {
    func clipStakesRelativeDescription(reference: Date = Date()) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: reference)
    }
}
