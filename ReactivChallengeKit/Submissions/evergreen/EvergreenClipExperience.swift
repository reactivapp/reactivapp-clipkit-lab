//  EvergreenClipExperience.swift
//  ReactivChallengeKit
//
//  Copyright © 2025 Reactiv Technologies Inc. All rights reserved.
//  hhhh

import SwiftUI
import Combine
import CoreText

/// Evergreen: Single-page scrollable App Clip — gentle intro, optional breath, grow a tree, teaser, CTA.
struct EvergreenClipExperience: ClipExperience {
    static let urlPattern = "evergreen.app/breathe/:venueId"
    static let clipName = "Evergreen"
    static let clipDescription = "A gentle wellness pause in one scroll: start when you're ready, breathe, grow a tree, then explore the full app. Invoke with evergreen.app/breathe/your-venue."
    static let teamName = "Evergreen"
    static let touchpoint: JourneyTouchpoint = .utility
    static let invocationSource: InvocationSource = .qrCode

    let context: ClipContext

    // MARK: - State (user-controlled; no auto-start)

    @State private var hasStartedBreath = false
    @State private var hasCompletedBreath = false
    @State private var breathingSecondsRemaining: Int = 10
    @State private var isTimerRunning = false
    @State private var treeScale: CGFloat = 0.0
    @State private var treeOpacity: Double = 0.0

    private let breathingTotalSeconds = 10

    /// Minimum height for bottom spacer so content always exceeds viewport and scrolls.
    private let bottomSpacerMinHeight: CGFloat = 420

    private var venueId: String {
        context.pathParameters["venueId"] ?? "venue"
    }

    // MARK: - Enchanted-forest palette (whole app)
    //
    // Sampled directly from the painting:
    //   nightSkyTop   — near-black teal at the top of the sky
    //   nightSkyMid   — mid deep-teal, most of the background
    //   barkSage      — the muted sage-green of the tree bark / branches
    //   foliageTop    — darkest canopy green
    //   foliageBottom — slightly lighter forest green
    //   cardFill      — translucent dark-teal for cards (bark-cavity feel)
    //   cardBorder    — faint sage rim on cards
    //   glowAmber     — warm lantern amber inside the treehouse rooms
    //   glowDeep      — deeper orange-amber for gradients / shadows
    //   soilDark      — near-black earthy ground
    //   soilLight     — warm dark soil
    //   textPrimary   — soft warm cream, readable on dark
    //   textSecondary — muted sage-tinted cream for secondary copy

    private static let nightSkyTop    = Color(red: 0.05, green: 0.12, blue: 0.14)
    private static let nightSkyMid    = Color(red: 0.09, green: 0.20, blue: 0.20)
    private static let barkSage       = Color(red: 0.28, green: 0.42, blue: 0.34)
    private static let foliageTop     = Color(red: 0.15, green: 0.33, blue: 0.22)
    private static let foliageBottom  = Color(red: 0.22, green: 0.45, blue: 0.30)
    private static let cardFill       = Color(red: 0.10, green: 0.22, blue: 0.22).opacity(0.82)
    private static let cardBorder     = Color(red: 0.28, green: 0.42, blue: 0.34).opacity(0.55)
    private static let glowAmber      = Color(red: 0.94, green: 0.66, blue: 0.20)
    private static let glowDeep       = Color(red: 0.78, green: 0.44, blue: 0.10)
    private static let soilDark       = Color(red: 0.12, green: 0.08, blue: 0.03)
    private static let soilLight      = Color(red: 0.22, green: 0.14, blue: 0.06)
    private static let textPrimary    = Color(red: 0.96, green: 0.92, blue: 0.82)
    private static let textSecondary  = Color(red: 0.65, green: 0.74, blue: 0.68)

    // MARK: - Body

    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()

            // Ambient fireflies across the whole screen
            EvergreenFirefliesView(count: 28)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    introSection

                    if !hasStartedBreath {
                        breathInvitationSection
                    }

                    if hasStartedBreath {
                        breathingSection
                    }

                    if hasCompletedBreath {
                        resultSection
                        teaserSection
                        ctaSection
                    }

                    bottomSpacerSection
                }
                .frame(maxWidth: .infinity, alignment: .top)
                .padding(.horizontal, 28)
                .padding(.top, 56)
                .padding(.bottom, 120)
            }
            .scrollIndicators(.hidden)
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.82), value: hasStartedBreath)
        .animation(.spring(response: 0.5, dampingFraction: 0.82), value: hasCompletedBreath)
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            if hasStartedBreath && isTimerRunning && breathingSecondsRemaining > 0 {
                breathingSecondsRemaining -= 1
                if breathingSecondsRemaining == 0 {
                    isTimerRunning = false
                }
            }
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Self.nightSkyTop, Self.nightSkyMid],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - 1. Intro section

    /// Peach Melon logo font (PostScript name).
    private static let logoFontName = "PeachMelon-Regular"
    private static let logoFontSize: CGFloat = 34

    /// Cached Peach Melon font from bundle (registered once).
    private static var cachedPeachMelonFont: UIFont?

    /// Use Peach Melon from bundle when available; otherwise .custom so it works once registered via Info.plist.
    private var evergreenLogoFont: Font {
        let uiFont = Self.cachedPeachMelonFont ?? Self.loadPeachMelonFromBundle()
        if let font = uiFont {
            return Font(font)
        }
        return .custom(Self.logoFontName, size: Self.logoFontSize)
    }

    /// Load and register Peach Melon from app bundle, return UIFont if successful. Caches result.
    private static func loadPeachMelonFromBundle() -> UIFont? {
        if let cached = cachedPeachMelonFont { return cached }
        let bundleURLs = [
            Bundle.main.url(forResource: "Peach Melon", withExtension: "ttf"),
            Bundle.main.url(forResource: "Peach Melon", withExtension: "ttf", subdirectory: "evergreen"),
        ]
        for url in bundleURLs.compactMap({ $0 }) {
            guard let data = try? Data(contentsOf: url) as CFData,
                  let provider = CGDataProvider(data: data),
                  let cgFont = CGFont(provider) else { continue }
            if CTFontManagerRegisterGraphicsFont(cgFont, nil) {
                if let font = UIFont(name: logoFontName, size: logoFontSize) {
                    cachedPeachMelonFont = font
                    return font
                }
            }
        }
        let fallback = UIFont(name: logoFontName, size: logoFontSize)
            ?? UIFont(name: "Peach Melon Regular", size: logoFontSize)
        if let font = fallback { cachedPeachMelonFont = font }
        return fallback
    }

    private var introSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Evergreen")
                .font(evergreenLogoFont)
                .foregroundStyle(Self.textPrimary)

            Text("Welcome!")
                .font(.system(size: 28, weight: .medium, design: .serif))
                .foregroundStyle(Self.textPrimary)
                .lineSpacing(5)

            Text("Take a quiet pause. See how a small moment can grow into something meaningful in Evergreen.")
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundStyle(Self.textSecondary)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .background(.ultraThinMaterial.opacity(0.45), in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Self.cardBorder.opacity(0.4), lineWidth: 1)
        )
        .padding(.bottom, 92)
    }

    // MARK: - 2. Breath invitation card

    private var breathInvitationSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Let's have a moment together")
                .font(.system(size: 18, weight: .medium, design: .serif))
                .foregroundStyle(Self.textPrimary)

            Text("If we could just take 10 seconds of your time. A little surprise will be waiting for you.")
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundStyle(Self.textSecondary)
                .lineSpacing(3)

            Button {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
                    hasStartedBreath = true
                    breathingSecondsRemaining = breathingTotalSeconds
                    isTimerRunning = true
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "wind")
                        .font(.system(size: 16, weight: .medium))
                    Text("Breathe with us :)")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundStyle(Self.nightSkyTop)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        colors: [Self.glowAmber, Self.glowDeep],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 16)
                )
                .shadow(color: Self.glowAmber.opacity(0.35), radius: 10, y: 4)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 32)
        .padding(.vertical, 28)
        .background(Self.cardFill, in: RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(Self.cardBorder, lineWidth: 1)
        )
        .padding(.bottom, 88)
    }

    // MARK: - 3. Breathing section

    private var breathingSection: some View {
        VStack(alignment: .center, spacing: 0) {
            Text("Breathe with us :)")
                .font(.system(size: 20, weight: .medium, design: .serif))
                .foregroundStyle(Self.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 28)

            ZStack {
                Circle()
                    .stroke(Self.barkSage.opacity(0.3), lineWidth: 10)
                    .frame(width: 152, height: 152)
                Circle()
                    .trim(from: 0, to: CGFloat(breathingSecondsRemaining) / CGFloat(breathingTotalSeconds))
                    .stroke(
                        LinearGradient(
                            colors: [Self.glowAmber, Self.glowDeep],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 152, height: 152)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: breathingSecondsRemaining)
                    .shadow(color: Self.glowAmber.opacity(0.5), radius: 8)
                Text("\(breathingSecondsRemaining)")
                    .font(.system(size: 38, weight: .medium, design: .rounded))
                    .foregroundStyle(Self.textPrimary)
            }
            .padding(.vertical, 24)

            Text("\(breathingSecondsRemaining) sec left")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundStyle(Self.textSecondary)
                .padding(.bottom, 28)

            Button {
                isTimerRunning = false
                withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
                    hasCompletedBreath = true
                    treeScale = 0.01
                    treeOpacity = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                    withAnimation(.easeOut(duration: 1.0)) {
                        treeScale = 1.0
                        treeOpacity = 1.0
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                    Text("Continue")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundStyle(Self.nightSkyTop)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Self.glowAmber, Self.glowDeep],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 16)
                )
                .shadow(color: Self.glowAmber.opacity(0.35), radius: 10, y: 4)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .padding(.vertical, 36)
        .padding(.horizontal, 12)
        .background(Self.cardFill, in: RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(Self.cardBorder, lineWidth: 1)
        )
        .padding(.bottom, 96)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - 4. Result section (tree grew)

    private var resultSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("You're growing a tree!!!")
                .font(.system(size: 26, weight: .medium, design: .serif))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Self.glowAmber, Color(red: 1.0, green: 0.88, blue: 0.60)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Self.nightSkyTop)
                    .frame(height: 148)

                EvergreenFirefliesView(count: 18)
                    .frame(maxWidth: .infinity)
                    .frame(height: 148)
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [Self.soilDark, Self.soilLight],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 52)
                    .padding(.horizontal, 44)
                    .shadow(color: Self.glowAmber.opacity(0.12), radius: 12, y: -4)

                SmallTreeShape()
                    .fill(
                        LinearGradient(
                            colors: [Self.foliageTop, Self.foliageBottom],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 76, height: 112)
                    .scaleEffect(treeScale)
                    .opacity(treeOpacity)
                    .offset(y: 26)
                    .shadow(color: Self.glowAmber.opacity(0.35), radius: 18, y: 8)
            }
            .frame(height: 148)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.45), radius: 16, y: 6)
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .padding(.bottom, 72)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - 5. Teaser section

    private var teaserSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("In the full Evergreen app, this tree keeps evolving.")
                .font(.system(size: 19, weight: .medium, design: .serif))
                .foregroundStyle(Self.textPrimary)

            Text("Unlock rooms in your own treehouse, bring yourself to improve your look on life. There is no pressure, whenever you're ready.")
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundStyle(Self.textSecondary)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .background(.ultraThinMaterial.opacity(0.45), in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Self.cardBorder.opacity(0.4), lineWidth: 1)
        )
        .padding(.bottom, 64)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - 6. CTA section

    private var ctaSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("One step at a time.")
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundStyle(Self.textSecondary)
                .lineSpacing(3)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                // TODO: Replace with App Store / deep link when available.
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 18))
                    Text("See the full tree")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundStyle(Self.nightSkyTop)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        colors: [Self.glowAmber, Self.glowDeep],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 16)
                )
                .shadow(color: Self.glowAmber.opacity(0.35), radius: 10, y: 4)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .padding(.bottom, 64)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Bottom spacer

    private var bottomSpacerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "leaf")
                .font(.system(size: 24, weight: .light))
                .foregroundStyle(Self.barkSage.opacity(0.6))
            Text("Scroll to explore")
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(Self.textSecondary.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: bottomSpacerMinHeight)
    }
}

// MARK: - Firefly model

private struct EvergreenFirefly: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let phase: Double
    let speed: Double
}

// MARK: - EvergreenFirefliesView
// Outer view generates stable positions once and passes them to the Canvas renderer.
// Keeping positions in @State here (not inside Canvas) means parent re-renders
// (e.g. the countdown timer) never reseed the random values.

private struct EvergreenFirefliesView: View {
    let count: Int

    // Generated once in onAppear; stable across all parent re-renders.
    @State private var fireflies: [EvergreenFirefly] = []

    var body: some View {
        // Only render the canvas once we have positions — avoids the empty-array
        // first-frame problem where Canvas captures an empty snapshot.
        if fireflies.isEmpty {
            Color.clear
                .onAppear { seed() }
        } else {
            EvergreenFirefliesCanvas(fireflies: fireflies)
                .allowsHitTesting(false)
        }
    }

    private func seed() {
        fireflies = (0..<count).map { _ in
            EvergreenFirefly(
                x: CGFloat.random(in: 0...1),
                y: CGFloat.random(in: 0...1),
                size: CGFloat.random(in: 2.5...5.5),
                phase: Double.random(in: 0...(2 * .pi)),
                speed: Double.random(in: 1.4...3.2)
            )
        }
    }
}

// Separate view so SwiftUI identity is stable; receives the fixed array as a let.
private struct EvergreenFirefliesCanvas: View {
    let fireflies: [EvergreenFirefly]

    var body: some View {
        TimelineView(.animation) { context in
            Canvas { ctx, size in
                let t = context.date.timeIntervalSinceReferenceDate
                for fly in fireflies {
                    let driftX = fly.x * size.width
                        + sin(t * 0.18 + fly.phase) * size.width * 0.07
                    let driftY = fly.y * size.height
                        + cos(t * 0.13 + fly.phase * 1.3) * size.height * 0.06

                    let blink = (sin(t / fly.speed * .pi * 2 + fly.phase) + 1) / 2
                    let opacity = 0.15 + blink * 0.85

                    ctx.fill(
                        Path(ellipseIn: CGRect(
                            x: driftX - fly.size * 3,
                            y: driftY - fly.size * 3,
                            width: fly.size * 6,
                            height: fly.size * 6
                        )),
                        with: .color(Color(red: 0.85, green: 1.0, blue: 0.55).opacity(opacity * 0.18))
                    )
                    ctx.fill(
                        Path(ellipseIn: CGRect(
                            x: driftX - fly.size / 2,
                            y: driftY - fly.size / 2,
                            width: fly.size,
                            height: fly.size
                        )),
                        with: .color(Color(red: 0.92, green: 1.0, blue: 0.70).opacity(opacity))
                    )
                }
            }
        }
    }
}

// MARK: - Tree shape (simple sapling — unchanged)

private struct SmallTreeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.addRect(CGRect(x: w * 0.4, y: h * 0.5, width: w * 0.2, height: h * 0.5))
        path.addEllipse(in: CGRect(x: 0, y: 0, width: w, height: h * 0.65))
        return path
    }
}

// MARK: - Lab protocol & types (minimal stubs)
// Remove this block when building with the full ClipKit Lab template.

protocol ClipExperience: View {
    static var urlPattern: String { get }
    static var clipName: String { get }
    static var clipDescription: String { get }
    static var teamName: String { get }
    static var touchpoint: JourneyTouchpoint { get }
    static var invocationSource: InvocationSource { get }
    var context: ClipContext { get }
}

struct ClipContext {
    var invocationURL: URL
    var pathParameters: [String: String]
}

enum JourneyTouchpoint {
    case discovery, purchase, onSite, reengagement, utility
}

enum InvocationSource {
    case qrCode, nfcTag, iMessage, smartBanner, appleMaps, siri
}

struct ClipActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(Color.accentColor, in: .capsule)
        }
        .buttonStyle(.plain)
    }
}
