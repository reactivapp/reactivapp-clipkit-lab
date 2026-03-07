import Foundation

actor ClipStakesMockBackend {
    static let shared = ClipStakesMockBackend()

    private var clips: [String: ClipStakesClip] = [:]
    private var receipts: [String: ClipStakesReceipt] = [:]
    private var conversions: [ClipStakesConversion] = []
    private var latestPushByClipID: [String: ClipStakesNotificationEvent] = [:]
    private var orderCounter = 1000
    private var demoSeedKey: String?

    private init() {
        let seed = Self.makeSeedData()
        clips = seed.clips
        receipts = seed.receipts
    }

    func getClips(productId: String) async -> [ClipStakesClip] {
        try? await Task.sleep(nanoseconds: 200_000_000)

        return clips.values
            .filter { $0.productID == productId && $0.isActive }
            .sorted {
                if $0.conversions == $1.conversions {
                    return $0.createdAt > $1.createdAt
                }
                return $0.conversions > $1.conversions
            }
    }

    func getReceipt(receiptId: String) async throws -> ClipStakesReceipt {
        try? await Task.sleep(nanoseconds: 150_000_000)

        guard let receipt = receipts[receiptId] else {
            throw ClipStakesBackendError.receiptNotFound
        }

        if receipt.clipCreated {
            throw ClipStakesBackendError.receiptAlreadyUsed
        }

        return receipt
    }

    func createUploadURL(receiptId: String, productId: String) async -> ClipStakesUploadURLResponse {
        let timestamp = Int(Date().timeIntervalSince1970)
        let key = "clips/\(receiptId)/\(productId)/\(timestamp).mp4"
        let uploadURL = URL(string: "https://upload.clipstakes.app/\(key)")!
        let videoURL = URL(string: "https://r2.clipstakes.app/\(key)")!

        return ClipStakesUploadURLResponse(
            uploadURL: uploadURL,
            videoURL: videoURL,
            key: key
        )
    }

    func createClip(
        receiptId: String,
        deviceToken: String?,
        productId: String,
        videoURL: URL,
        textOverlay: String?,
        textPosition: ClipStakesTextPosition,
        durationSeconds: Int
    ) async throws -> ClipStakesCreateClipResponse {
        guard (5...15).contains(durationSeconds) else {
            throw ClipStakesBackendError.invalidDuration
        }

        guard var receipt = receipts[receiptId] else {
            throw ClipStakesBackendError.invalidReceipt
        }

        if receipt.clipCreated {
            throw ClipStakesBackendError.receiptAlreadyUsed
        }

        let clipID = UUID().uuidString.lowercased()
        let couponCode = Self.generateCoupon(prefix: "CLIP")

        let clip = ClipStakesClip(
            id: clipID,
            receiptID: receiptId,
            deviceToken: deviceToken,
            productID: productId,
            videoURL: videoURL,
            textOverlay: textOverlay,
            textPosition: textPosition,
            durationSeconds: durationSeconds,
            couponCode: couponCode,
            couponRedeemed: false,
            conversions: 0,
            bonusCouponCode: nil,
            bonusPushed: false,
            bonusRedeemed: false,
            isActive: true,
            createdAt: Date(),
            expiresAt: Date().addingTimeInterval(8 * 60 * 60)
        )

        clips[clipID] = clip
        receipt.clipCreated = true
        receipts[receiptId] = receipt

        return ClipStakesCreateClipResponse(
            clipID: clipID,
            couponCode: couponCode,
            couponValue: "$5.00",
            passURL: URL(string: "https://api.clipstakes.app/pass/\(clipID)")!,
            message: "Your clip is live! Here's $5 off your next purchase."
        )
    }

    func logConversion(clipId: String, orderId: String) async throws -> ClipStakesConversionResponse {
        guard var clip = clips[clipId] else {
            throw ClipStakesBackendError.clipNotFound
        }

        let conversion = ClipStakesConversion(
            id: UUID().uuidString.lowercased(),
            clipID: clipId,
            orderID: orderId,
            createdAt: Date()
        )
        conversions.append(conversion)

        clip.conversions += 1

        var bonusCouponCode = clip.bonusCouponCode
        if bonusCouponCode == nil {
            bonusCouponCode = Self.generateCoupon(prefix: "BONUS")
            clip.bonusCouponCode = bonusCouponCode
        }

        let withinPushWindow = Date() < clip.expiresAt
        var pushSent = false

        if withinPushWindow, !clip.bonusPushed, clip.deviceToken != nil {
            clip.bonusPushed = true
            pushSent = true

            latestPushByClipID[clip.id] = ClipStakesNotificationEvent(
                clipID: clip.id,
                title: "Your clip just sold!",
                body: "Someone bought because of you. Here's $5 more.",
                bonusPassURL: URL(string: "https://api.clipstakes.app/pass/\(clip.id)/bonus"),
                createdAt: Date()
            )
        }

        clips[clipId] = clip

        return ClipStakesConversionResponse(
            success: true,
            bonusCouponCode: bonusCouponCode,
            bonusPassURL: URL(string: "https://api.clipstakes.app/pass/\(clipId)/bonus"),
            pushSent: pushSent,
            withinPushWindow: withinPushWindow
        )
    }

    func createReceiptFromOrder(orderId: String, productIds: [String]) async -> ClipStakesReceipt {
        if let existing = receipts[orderId] {
            return existing
        }

        let receipt = ClipStakesReceipt(
            id: orderId,
            productIDs: productIds,
            clipCreated: false,
            createdAt: Date()
        )
        receipts[orderId] = receipt
        return receipt
    }

    func performViewerCheckout(productId: String, clipId: String?) async throws -> ClipStakesCheckoutOutcome {
        orderCounter += 1
        let orderId = "order_\(orderCounter)"
        let receipt = await createReceiptFromOrder(orderId: orderId, productIds: [productId])

        let conversionResult: ClipStakesConversionResponse?
        if let clipId {
            conversionResult = try await logConversion(clipId: clipId, orderId: orderId)
        } else {
            conversionResult = nil
        }

        return ClipStakesCheckoutOutcome(
            orderID: orderId,
            receiptID: receipt.id,
            conversion: conversionResult
        )
    }

    func latestNotification(for clipId: String) async -> ClipStakesNotificationEvent? {
        latestPushByClipID[clipId]
    }

    func prepareDemoCatalog(with products: [ClipStakesProduct]) {
        guard !products.isEmpty else { return }

        let primary = products[0].id
        let secondary = products.count > 1 ? products[1].id : primary
        let tertiary = products.count > 2 ? products[2].id : primary

        let key = "\(primary)|\(secondary)|\(tertiary)"
        guard key != demoSeedKey else { return }
        demoSeedKey = key

        let legacyMap: [String: String] = [
            "prod_hoodie": primary,
            "prod_vinyl": secondary,
            "prod_hat": tertiary,
            "prod_shirt": primary,
            "prod_poster": tertiary,
        ]
        let validIDs = Set(products.map(\.id))

        for clipID in clips.keys {
            guard var clip = clips[clipID] else { continue }
            if let mapped = legacyMap[clip.productID] {
                clip.productID = mapped
            } else if !validIDs.contains(clip.productID) {
                clip.productID = primary
            }
            clips[clipID] = clip
        }

        for receiptID in receipts.keys {
            guard var receipt = receipts[receiptID] else { continue }
            receipt.productIDs = receipt.productIDs.map { id in
                if let mapped = legacyMap[id] { return mapped }
                if validIDs.contains(id) { return id }
                return primary
            }
            receipts[receiptID] = receipt
        }

        receipts["order_demo_hoodie"] = ClipStakesReceipt(
            id: "order_demo_hoodie",
            productIDs: [primary, secondary],
            clipCreated: false,
            createdAt: Date().addingTimeInterval(-3600)
        )

        receipts["order_demo_vinyl"] = ClipStakesReceipt(
            id: "order_demo_vinyl",
            productIDs: [secondary],
            clipCreated: false,
            createdAt: Date().addingTimeInterval(-2400)
        )
    }

    // MARK: - Seed Data

    private static func makeSeedData() -> (clips: [String: ClipStakesClip], receipts: [String: ClipStakesReceipt]) {
        var seededClips: [String: ClipStakesClip] = [:]
        var seededReceipts: [String: ClipStakesReceipt] = [:]

        let starterReceipts: [ClipStakesReceipt] = [
            ClipStakesReceipt(id: "order_demo_hoodie", productIDs: ["prod_hoodie", "prod_hat"], clipCreated: false, createdAt: Date().addingTimeInterval(-3600)),
            ClipStakesReceipt(id: "order_demo_vinyl", productIDs: ["prod_vinyl"], clipCreated: false, createdAt: Date().addingTimeInterval(-2400)),
        ]

        for receipt in starterReceipts {
            seededReceipts[receipt.id] = receipt
        }

        let sampleClips = [
            Self.makeSeedClip(
                clipId: "clip_seed_1",
                receiptId: "seed_receipt_1",
                productId: "prod_hoodie",
                text: "OBSESSED",
                position: .bottom,
                conversions: 4,
                minutesAgo: 70,
                creatorToken: "token-seed-1"
            ),
            Self.makeSeedClip(
                clipId: "clip_seed_2",
                receiptId: "seed_receipt_2",
                productId: "prod_hoodie",
                text: "Runs true to size",
                position: .top,
                conversions: 2,
                minutesAgo: 20,
                creatorToken: nil
            ),
            Self.makeSeedClip(
                clipId: "clip_seed_3",
                receiptId: "seed_receipt_3",
                productId: "prod_vinyl",
                text: "Sound quality is insane",
                position: .center,
                conversions: 1,
                minutesAgo: 35,
                creatorToken: "token-seed-3"
            ),
        ]

        for clip in sampleClips {
            seededClips[clip.id] = clip
        }

        return (seededClips, seededReceipts)
    }

    private static func makeSeedClip(
        clipId: String,
        receiptId: String,
        productId: String,
        text: String,
        position: ClipStakesTextPosition,
        conversions: Int,
        minutesAgo: Int,
        creatorToken: String?
    ) -> ClipStakesClip {
        let created = Date().addingTimeInterval(TimeInterval(-60 * minutesAgo))

        return ClipStakesClip(
            id: clipId,
            receiptID: receiptId,
            deviceToken: creatorToken,
            productID: productId,
            videoURL: URL(string: "https://r2.clipstakes.app/seeds/\(clipId).mp4")!,
            textOverlay: text,
            textPosition: position,
            durationSeconds: 9,
            couponCode: Self.generateCoupon(prefix: "CLIP"),
            couponRedeemed: false,
            conversions: conversions,
            bonusCouponCode: conversions > 0 ? Self.generateCoupon(prefix: "BONUS") : nil,
            bonusPushed: false,
            bonusRedeemed: false,
            isActive: true,
            createdAt: created,
            expiresAt: created.addingTimeInterval(8 * 60 * 60)
        )
    }

    private static func generateCoupon(prefix: String) -> String {
        let stamp = String(Int(Date().timeIntervalSince1970), radix: 36).uppercased()
        return "\(prefix)-\(stamp)-\(Int.random(in: 100...999))"
    }
}
