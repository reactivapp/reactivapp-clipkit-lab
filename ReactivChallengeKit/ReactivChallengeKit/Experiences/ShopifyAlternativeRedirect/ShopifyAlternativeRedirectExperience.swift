//  ShopifyAlternativeRedirectExperience.swift
//  ReactivChallengeKit
//
//  Copyright © 2025 Reactiv Technologies Inc. All rights reserved.
//

import SwiftUI

struct ShopifyAlternativeRedirectExperience: ClipExperience {
    static let urlPattern = "localclip.ai/p"
    static let clipName = "Shopify Alternatives"
    static let clipDescription = "Redirect marketplace demand to independent Shopify merchants."
    static let touchpoint: JourneyTouchpoint = .purchase
    static let invocationSource: InvocationSource = .iMessage
    static let sampleInvocationURL = "https://localclip.ai/p?url=https://amazon.com/dp/B0TEST"

    let context: ClipContext

    var body: some View {
        ShopifyAlternativeRedirectView(context: context)
    }
}
