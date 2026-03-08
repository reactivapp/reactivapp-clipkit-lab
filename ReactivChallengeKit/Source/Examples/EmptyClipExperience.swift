//  EmptyClipExperience.swift
//  ReactivChallengeKit
//
//  Copyright © 2025 Reactiv Technologies Inc. All rights reserved.
//

import SwiftUI

// Template clip: copy this file to Submissions/<team-slug>/ and rename the struct.
// Set urlPattern, clipName, clipDescription, teamName to match your clip.
// Choose touchpoint (.discovery, .purchase, .onSite, .reengagement, .utility) and invocationSource.
// Build your UI in the body below (or use building block components when available).

struct EmptyClipExperience: ClipExperience {
    static let urlPattern = "hidden.example.com/empty"
    static let clipName = "Z_Empty (Template)"
    static let clipDescription = "Internal template, do not use."
    static let teamName = "Your Team Name"

    // Touchpoint: where in the journey this clip appears (e.g. .onSite for in-venue).
    static let touchpoint: JourneyTouchpoint = .onSite

    // How the clip is triggered in the real world (e.g. .qrCode, .nfcTag, .iMessage).
    static let invocationSource: InvocationSource = .qrCode

    let context: ClipContext

    // Add @State here for your clip's local state (e.g. selected items, form fields).

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header: replace with your branding or use ArtistBanner/ClipHeader when available.
                    ClipHeader(
                        title: "Your Experience",
                        subtitle: "Which journey touchpoint are you targeting?",
                        systemImage: "music.note"
                    )
                    .padding(.top, 16)

                    // Main content: build your flow here. Optional components when in lab:
                    //   ArtistBanner(artist:venue:), MerchGrid(products:onAddToCart:),
                    //   CartSummary(items:onCheckout:), ClipActionButton(title:icon:),
                    //   ClipSuccessOverlay(message:), NotificationPreview(template:).
                    // Mock data: ChallengeMockData.artists, .products, .venues, .notificationTemplates.

                    GlassEffectContainer {
                        VStack(spacing: 8) {
                            HStack {
                                Text("URL")
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 50, alignment: .trailing)
                                Text(context.invocationURL.absoluteString)
                                    .font(.system(size: 13, design: .monospaced))
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                Spacer()
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 12))

                            HStack {
                                Text("param")
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 50, alignment: .trailing)
                                Text(context.pathParameters["param"] ?? "—")
                                    .font(.system(size: 13, design: .monospaced))
                                    .foregroundStyle(.primary)
                                Spacer()
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 16)
            }
            .scrollIndicators(.hidden)
        }
    }
}

// MARK: - Placeholder components (stubs when Components/ not in repo)

struct ClipHeader: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.system(size: 22, weight: .semibold))
            Text(subtitle)
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct GlassEffectContainer<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

extension View {
    func glassEffect<S>(_ style: S, in shape: RoundedRectangle) -> some View {
        background(shape.fill(.regularMaterial))
    }
}

struct NotificationTemplate {
    let title: String
    let body: String
    let journeyStage: String
    let triggerDescription: String
    let delayFromInvocation: Int
}

struct NotificationPreview: View {
    let template: NotificationTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(template.title)
                .font(.headline)
            Text(template.body)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("\(template.triggerDescription) · \(template.journeyStage)")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
}
