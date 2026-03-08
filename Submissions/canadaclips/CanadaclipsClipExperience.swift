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
        ShopifyAlternativeRedirectView(context: context)
    }
}
