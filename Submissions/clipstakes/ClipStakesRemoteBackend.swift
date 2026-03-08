import Foundation

enum ClipStakesRemoteBackendError: LocalizedError {
    case network(URLError)
    case requestFailed(statusCode: Int, message: String)
    case invalidResponse(String)

    var isConnectivityIssue: Bool {
        switch self {
        case .network(let error):
            switch error.code {
            case .cannotFindHost,
                 .cannotConnectToHost,
                 .dnsLookupFailed,
                 .networkConnectionLost,
                 .notConnectedToInternet,
                 .timedOut:
                return true
            default:
                return false
            }
        case .requestFailed, .invalidResponse:
            return false
        }
    }

    var errorDescription: String? {
        switch self {
        case .network(let error):
            return error.localizedDescription
        case .requestFailed(_, let message):
            return message
        case .invalidResponse(let message):
            return message
        }
    }
}

enum ClipStakesRemoteBackend {
    nonisolated static let defaultAPIBaseURL = URL(string: "https://clipstakes.skilled5041.workers.dev")!

    private static let session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 25
        return URLSession(configuration: configuration)
    }()

    nonisolated static func resolveAPIBaseURL(override: String?) -> URL {
        if let override, let url = normalizedURL(from: override) {
            return url
        }

        if let persisted = UserDefaults.standard.string(forKey: "clipstakes.api_base_url"),
           let url = normalizedURL(from: persisted) {
            return url
        }

        return defaultAPIBaseURL
    }

    nonisolated static func fallbackWalletPassURL(apiBaseURL: URL, walletCode: String) -> URL {
        apiBaseURL
            .appendingPathComponent("wallet")
            .appendingPathComponent(walletCode)
            .appendingPathComponent("pass")
    }

    static func getReceipt(
        receiptId: String,
        apiBaseURL: URL,
        deviceID: String
    ) async throws -> ClipStakesReceipt {
        do {
            let response = try await requestJSON(
                apiBaseURL: apiBaseURL,
                paths: ["/receipt/\(receiptId)"],
                method: "GET",
                deviceID: deviceID,
                body: nil
            )
            let payload = payloadDict(from: response)

            let productIDs = productIDsFromReceiptPayload(payload)
            let clipCreated = boolValue(for: ["clip_created", "clipCreated"], in: payload) ?? false
            let createdAt = dateValue(for: ["created_at", "createdAt"], in: payload) ?? Date()

            guard !productIDs.isEmpty else {
                throw ClipStakesRemoteBackendError.invalidResponse("Receipt response did not include product IDs.")
            }

            return ClipStakesReceipt(
                id: receiptId,
                productIDs: productIDs,
                clipCreated: clipCreated,
                createdAt: createdAt
            )
        } catch let error as ClipStakesRemoteBackendError {
            if case .requestFailed(let statusCode, _) = error {
                if statusCode == 404 { throw ClipStakesBackendError.receiptNotFound }
                if statusCode == 409 || statusCode == 422 { throw ClipStakesBackendError.receiptAlreadyUsed }
            }
            throw error
        }
    }

    static func createUploadURL(
        receiptId: String,
        productId: String,
        apiBaseURL: URL,
        deviceID: String
    ) async throws -> ClipStakesUploadURLResponse {
        let requestBody: [String: Any] = [
            "receipt_id": receiptId,
            "product_id": productId
        ]

        let response = try await requestJSON(
            apiBaseURL: apiBaseURL,
            paths: ["/upload", "/upload-url"],
            method: "POST",
            deviceID: deviceID,
            body: requestBody
        )

        let payload = payloadDict(from: response)
        guard let uploadURLString = stringValue(for: ["upload_url", "uploadURL"], in: payload),
              let videoURLString = stringValue(for: ["video_url", "videoURL"], in: payload),
              let uploadURL = makeURL(from: uploadURLString, apiBaseURL: apiBaseURL),
              let videoURL = makeURL(from: videoURLString, apiBaseURL: apiBaseURL)
        else {
            throw ClipStakesRemoteBackendError.invalidResponse("Upload response missing upload_url or video_url.")
        }

        let key = stringValue(for: ["key"], in: payload)
            ?? videoURL.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        return ClipStakesUploadURLResponse(
            uploadURL: uploadURL,
            videoURL: videoURL,
            key: key
        )
    }

    static func createClip(
        receiptId: String,
        deviceID: String,
        productId: String,
        videoURL: URL,
        textOverlay: String?,
        textPosition: ClipStakesTextPosition,
        durationSeconds: Int,
        apiBaseURL: URL
    ) async throws -> ClipStakesCreateClipResponse {
        var requestBody: [String: Any] = [
            "receipt_id": receiptId,
            "product_id": productId,
            "video_url": videoURL.absoluteString,
            "text_position": textPosition.rawValue,
            "duration_seconds": durationSeconds
        ]
        if let textOverlay, !textOverlay.isEmpty {
            requestBody["text_overlay"] = textOverlay
        }

        do {
            let response = try await requestJSON(
                apiBaseURL: apiBaseURL,
                paths: ["/clips"],
                method: "POST",
                deviceID: deviceID,
                body: requestBody
            )
            let payload = payloadDict(from: response)
            let wallet = dictValue(for: ["wallet"], in: payload) ?? [:]

            let clipID = stringValue(for: ["clip_id", "clipId", "id"], in: payload)
                ?? UUID().uuidString.lowercased()

            guard let walletCode = stringValue(
                for: ["code", "wallet_code", "walletCode", "coupon_code", "couponCode"],
                in: wallet,
                fallback: payload
            ) else {
                throw ClipStakesRemoteBackendError.invalidResponse("Clip response missing wallet code.")
            }

            let backendPassURL = urlValue(
                for: ["pass_url", "wallet_pass_url", "passURL", "url"],
                in: wallet,
                apiBaseURL: apiBaseURL
            ) ?? urlValue(
                for: ["pass_url", "wallet_pass_url", "passURL"],
                in: payload,
                apiBaseURL: apiBaseURL
            )

            let passURL = backendPassURL ?? fallbackWalletPassURL(apiBaseURL: apiBaseURL, walletCode: walletCode)

            let instantCreditCents = intValue(
                for: ["instant_credit_cents", "instantCreditCents", "credited_cents", "creditedCents"],
                in: payload
            ) ?? 0

            let availableBalanceCents = intValue(
                for: ["available_balance_cents", "availableBalanceCents", "balance_cents", "balanceCents"],
                in: payload
            ) ?? 0

            let message = stringValue(for: ["message"], in: payload)
                ?? "Clip created."

            return ClipStakesCreateClipResponse(
                clipID: clipID,
                walletCode: walletCode,
                instantCreditCents: instantCreditCents,
                instantCreditDisplay: instantCreditCents.clipStakesCurrencyDisplay,
                passURL: passURL,
                availableBalanceCents: availableBalanceCents,
                availableBalanceDisplay: availableBalanceCents.clipStakesCurrencyDisplay,
                message: message
            )
        } catch let error as ClipStakesRemoteBackendError {
            if case .requestFailed(let statusCode, _) = error, statusCode == 409 {
                throw ClipStakesBackendError.receiptAlreadyUsed
            }
            throw error
        }
    }

    static func getRewards(
        deviceID: String,
        apiBaseURL: URL
    ) async throws -> ClipStakesRewardsSnapshot {
        let response = try await requestJSON(
            apiBaseURL: apiBaseURL,
            paths: ["/rewards/me"],
            method: "GET",
            deviceID: deviceID,
            body: nil
        )

        let payload = payloadDict(from: response)
        let wallet = dictValue(for: ["wallet"], in: payload) ?? payload

        guard let walletCode = stringValue(
            for: ["code", "wallet_code", "walletCode", "coupon_code", "couponCode"],
            in: wallet,
            fallback: payload
        ) else {
            throw ClipStakesRemoteBackendError.invalidResponse("Rewards response missing wallet code.")
        }

        let passURL = urlValue(
            for: ["pass_url", "wallet_pass_url", "passURL", "url"],
            in: wallet,
            apiBaseURL: apiBaseURL
        ) ?? urlValue(
            for: ["pass_url", "wallet_pass_url", "passURL"],
            in: payload,
            apiBaseURL: apiBaseURL
        ) ?? fallbackWalletPassURL(apiBaseURL: apiBaseURL, walletCode: walletCode)

        let availableBalanceCents = intValue(
            for: ["available_balance_cents", "availableBalanceCents", "balance_cents", "balanceCents"],
            in: wallet,
            fallback: payload
        ) ?? 0

        let lifetimeEarnedCents = intValue(
            for: ["lifetime_earned_cents", "lifetimeEarnedCents"],
            in: wallet,
            fallback: payload
        ) ?? availableBalanceCents

        let transactions = parseTransactions(
            from: arrayValue(for: ["transactions"], in: payload)
                ?? arrayValue(for: ["transactions"], in: wallet)
                ?? []
        )

        return ClipStakesRewardsSnapshot(
            walletCode: walletCode,
            passURL: passURL,
            availableBalanceCents: availableBalanceCents,
            availableBalanceDisplay: availableBalanceCents.clipStakesCurrencyDisplay,
            lifetimeEarnedCents: lifetimeEarnedCents,
            lifetimeEarnedDisplay: lifetimeEarnedCents.clipStakesCurrencyDisplay,
            transactions: transactions
        )
    }

    // MARK: - Networking

    private static func requestJSON(
        apiBaseURL: URL,
        paths: [String],
        method: String,
        deviceID: String,
        body: [String: Any]?
    ) async throws -> [String: Any] {
        var lastError: Error?

        for path in paths {
            do {
                return try await requestJSON(
                    apiBaseURL: apiBaseURL,
                    path: path,
                    method: method,
                    deviceID: deviceID,
                    body: body
                )
            } catch let error as ClipStakesRemoteBackendError {
                lastError = error
                if case .requestFailed(let statusCode, _) = error, statusCode == 404 {
                    continue
                }
                throw error
            } catch {
                lastError = error
                throw error
            }
        }

        throw (lastError as? ClipStakesRemoteBackendError)
            ?? ClipStakesRemoteBackendError.invalidResponse("No valid backend endpoint found.")
    }

    private static func requestJSON(
        apiBaseURL: URL,
        path: String,
        method: String,
        deviceID: String,
        body: [String: Any]?
    ) async throws -> [String: Any] {
        let url = urlForPath(path, apiBaseURL: apiBaseURL)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(deviceID, forHTTPHeaderField: "X-Device-ID")

        if let body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ClipStakesRemoteBackendError.invalidResponse("Backend returned a non-HTTP response.")
            }

            let object = try jsonObject(from: data)
            if (200 ... 299).contains(httpResponse.statusCode) {
                return object
            }

            let payload = payloadDict(from: object)
            let message = stringValue(for: ["message", "error", "detail"], in: payload)
                ?? stringValue(for: ["message", "error", "detail"], in: object)
                ?? HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)

            throw ClipStakesRemoteBackendError.requestFailed(
                statusCode: httpResponse.statusCode,
                message: message
            )
        } catch let error as URLError {
            throw ClipStakesRemoteBackendError.network(error)
        } catch let error as ClipStakesRemoteBackendError {
            throw error
        } catch {
            throw ClipStakesRemoteBackendError.invalidResponse(error.localizedDescription)
        }
    }

    // MARK: - Parsing

    private static func parseTransactions(from raw: [[String: Any]]) -> [ClipStakesRewardTransaction] {
        raw.compactMap { item in
            let amount = intValue(for: ["amount_cents", "amountCents", "amount"], in: item) ?? 0
            let kindRaw = stringValue(for: ["kind", "type", "event"], in: item)?.lowercased() ?? ""
            let kind: ClipStakesRewardTransaction.Kind = kindRaw.contains("conversion") ? .conversion : .clipPublished

            return ClipStakesRewardTransaction(
                id: stringValue(for: ["id"], in: item) ?? UUID().uuidString.lowercased(),
                kind: kind,
                amountCents: amount,
                amountDisplay: amount.clipStakesCurrencyDisplay,
                clipID: stringValue(for: ["clip_id", "clipId"], in: item) ?? "",
                orderID: stringValue(for: ["order_id", "orderId"], in: item),
                createdAt: dateValue(for: ["created_at", "createdAt"], in: item) ?? Date()
            )
        }
    }

    private static func productIDsFromReceiptPayload(_ payload: [String: Any]) -> [String] {
        if let ids = stringArrayValue(for: ["product_ids", "productIds"], in: payload), !ids.isEmpty {
            return ids
        }

        if let products = arrayValue(for: ["products"], in: payload) {
            let ids = products.compactMap { stringValue(for: ["id", "product_id", "productId"], in: $0) }
            if !ids.isEmpty { return ids }
        }

        if let items = arrayValue(for: ["items", "line_items", "lineItems"], in: payload) {
            let ids = items.compactMap { stringValue(for: ["product_id", "productId", "id"], in: $0) }
            if !ids.isEmpty { return ids }
        }

        return []
    }

    private static func payloadDict(from object: [String: Any]) -> [String: Any] {
        if let data = object["data"] as? [String: Any] {
            return data
        }
        return object
    }

    private static func jsonObject(from data: Data) throws -> [String: Any] {
        guard !data.isEmpty else { return [:] }
        let json = try JSONSerialization.jsonObject(with: data)
        if let dict = json as? [String: Any] {
            return dict
        }
        if let array = json as? [[String: Any]] {
            return ["items": array]
        }
        return [:]
    }

    private static func urlForPath(_ path: String, apiBaseURL: URL) -> URL {
        if let absolute = URL(string: path), absolute.scheme != nil {
            return absolute
        }
        let trimmed = path.hasPrefix("/") ? String(path.dropFirst()) : path
        return apiBaseURL.appendingPathComponent(trimmed)
    }

    private static func makeURL(from raw: String, apiBaseURL: URL) -> URL? {
        if let absolute = URL(string: raw), absolute.scheme != nil {
            return absolute
        }
        return urlForPath(raw, apiBaseURL: apiBaseURL)
    }

    private nonisolated static func normalizedURL(from raw: String) -> URL? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let parsed = URL(string: trimmed),
              let scheme = parsed.scheme?.lowercased(),
              scheme == "https" || scheme == "http" else {
            return nil
        }

        let path = parsed.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if path.isEmpty { return parsed }

        var components = URLComponents(url: parsed, resolvingAgainstBaseURL: false)
        components?.path = "/\(path)"
        return components?.url ?? parsed
    }

    private static func value(for keys: [String], in object: [String: Any]) -> Any? {
        for key in keys {
            if let value = object[key] {
                return value
            }
        }
        return nil
    }

    private static func dictValue(for keys: [String], in object: [String: Any]) -> [String: Any]? {
        value(for: keys, in: object) as? [String: Any]
    }

    private static func arrayValue(for keys: [String], in object: [String: Any]) -> [[String: Any]]? {
        guard let raw = value(for: keys, in: object) as? [Any] else { return nil }
        return raw.compactMap { $0 as? [String: Any] }
    }

    private static func stringArrayValue(for keys: [String], in object: [String: Any]) -> [String]? {
        guard let raw = value(for: keys, in: object) as? [Any] else { return nil }
        let values = raw.compactMap { item -> String? in
            if let string = item as? String { return string }
            if let number = item as? NSNumber { return number.stringValue }
            return nil
        }
        return values.isEmpty ? nil : values
    }

    private static func stringValue(
        for keys: [String],
        in object: [String: Any],
        fallback: [String: Any]? = nil
    ) -> String? {
        if let value = value(for: keys, in: object) {
            if let string = value as? String { return string }
            if let number = value as? NSNumber { return number.stringValue }
        }

        if let fallback {
            return stringValue(for: keys, in: fallback)
        }

        return nil
    }

    private static func intValue(
        for keys: [String],
        in object: [String: Any],
        fallback: [String: Any]? = nil
    ) -> Int? {
        if let value = value(for: keys, in: object) {
            if let integer = value as? Int { return integer }
            if let number = value as? NSNumber { return number.intValue }
            if let string = value as? String { return Int(string) }
        }

        if let fallback {
            return intValue(for: keys, in: fallback)
        }

        return nil
    }

    private static func boolValue(for keys: [String], in object: [String: Any]) -> Bool? {
        if let value = value(for: keys, in: object) {
            if let bool = value as? Bool { return bool }
            if let number = value as? NSNumber { return number.boolValue }
            if let string = value as? String {
                switch string.lowercased() {
                case "true", "1", "yes":
                    return true
                case "false", "0", "no":
                    return false
                default:
                    return nil
                }
            }
        }
        return nil
    }

    private static func urlValue(for keys: [String], in object: [String: Any], apiBaseURL: URL) -> URL? {
        guard let raw = stringValue(for: keys, in: object) else { return nil }
        return makeURL(from: raw, apiBaseURL: apiBaseURL)
    }

    private static func dateValue(for keys: [String], in object: [String: Any]) -> Date? {
        guard let raw = value(for: keys, in: object) else { return nil }

        if let timestamp = raw as? TimeInterval {
            return Date(timeIntervalSince1970: timestamp)
        }
        if let number = raw as? NSNumber {
            return Date(timeIntervalSince1970: number.doubleValue)
        }
        if let string = raw as? String {
            if let seconds = TimeInterval(string) {
                return Date(timeIntervalSince1970: seconds)
            }

            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = isoFormatter.date(from: string) {
                return date
            }

            let plainFormatter = ISO8601DateFormatter()
            if let date = plainFormatter.date(from: string) {
                return date
            }
        }

        return nil
    }
}
