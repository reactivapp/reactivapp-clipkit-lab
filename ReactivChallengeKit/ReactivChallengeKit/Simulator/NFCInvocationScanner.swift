import Foundation

enum NFCInvocationScanner {
    static func normalizeInvocationURL(from rawValue: String) -> String? {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if trimmed.contains("://") {
            return trimmed
        }

        if trimmed.lowercased().hasPrefix("clip.copped.app/") {
            return trimmed
        }

        if let productID = extractProductID(from: trimmed) {
            let encoded = productID.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? productID
            return "clip.copped.app/v/\(encoded)"
        }

        return nil
    }

    private static func extractProductID(from rawValue: String) -> String? {
        let lowered = rawValue.lowercased()

        if lowered.hasPrefix("copped:") {
            let value = String(rawValue.dropFirst("copped:".count))
            if value.contains("/v/") {
                return value.components(separatedBy: "/v/").last
            }
            return value
        }

        if let queryID = extractQueryValue(named: "productid", from: rawValue) {
            return queryID
        }

        if rawValue.hasPrefix("prod_") {
            return rawValue
        }

        if isSimpleIdentifier(rawValue) {
            return rawValue
        }

        return nil
    }

    private static func extractQueryValue(named name: String, from rawValue: String) -> String? {
        let separatorSet = CharacterSet(charactersIn: "?&")
        let tokens = rawValue.components(separatedBy: separatorSet)

        for token in tokens {
            let parts = token.split(separator: "=", maxSplits: 1).map(String.init)
            guard parts.count == 2 else { continue }
            if parts[0].lowercased() == name {
                return parts[1].removingPercentEncoding ?? parts[1]
            }
        }

        return nil
    }

    private static func isSimpleIdentifier(_ value: String) -> Bool {
        guard value.count <= 80 else { return false }
        let invalid = CharacterSet(charactersIn: " /?&=#")
        return value.rangeOfCharacter(from: invalid) == nil
    }
}
