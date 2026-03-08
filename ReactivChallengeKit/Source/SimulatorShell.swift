//  SimulatorShell.swift
//  ReactivChallengeKit
//
//  Copyright © 2025 Reactiv Technologies Inc. All rights reserved.
//
//  ClipKit URL simulator: SimulatorShell → InvocationConsole → ClipRouter → ClipExperience.
//  Launch the app to the simulator; enter a URL (e.g. evergreen.app/breathe/waterloo) to open the clip.

import SwiftUI

// MARK: - SimulatorShell (root)

/// Root view for the ClipKit simulator. Shows the URL invocation console;
/// when a URL is invoked, presents the clip via ClipRouter with a way to return.
struct SimulatorShell: View {
    @State private var invokedURL: URL?

    var body: some View {
        Group {
            if let url = invokedURL {
                ClipRouterView(invocationURL: url) {
                    Button {
                        invokedURL = nil
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial, in: Capsule())
                        .overlay(Capsule().strokeBorder(.white.opacity(0.25), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 8)
                    .padding(.leading, 16)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
            } else {
                InvocationConsole { url in
                    invokedURL = url
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: invokedURL != nil)
    }
}

// MARK: - InvocationConsole

/// Demo URL for Evergreen clip (matches pattern evergreen.app/breathe/:venueId).
private let evergreenDemoURLString = "evergreen.app/breathe/demo"

/// URL input screen: enter a clip URL and tap "Open" to launch the clip.
struct InvocationConsole: View {
    @State private var urlString: String = evergreenDemoURLString
    @FocusState private var isFieldFocused: Bool

    let onInvoke: (URL) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("ClipKit URL Simulator")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.primary)

                Text("Enter a clip URL to launch the experience, or use the demo shortcut below.")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                // Demo shortcut: one-tap launch
                Button {
                    launchEvergreenDemo()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 22))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Launch Evergreen Demo")
                                .font(.system(size: 17, weight: .semibold))
                            Text(evergreenDemoURLString)
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.85))
                        }
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(20)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)

                Text("Or enter any URL")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)

                VStack(alignment: .leading, spacing: 8) {
                    Text("URL")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                    TextField("evergreen.app/breathe/waterloo", text: $urlString)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .keyboardType(.URL)
                        .focused($isFieldFocused)
                }

                Button {
                    openURL()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                        Text("Open clip")
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .disabled(!isValidURL(urlString))

                if !SubmissionRegistry.all.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Registered clip patterns")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)
                        ForEach(0..<SubmissionRegistry.all.count, id: \.self) { index in
                            Text(SubmissionRegistry.all[index].urlPattern)
                                .font(.system(size: 14, design: .monospaced))
                                .foregroundStyle(.primary)
                        }
                    }
                    .padding(.top, 8)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private func launchEvergreenDemo() {
        guard let url = URL(string: "https://" + evergreenDemoURLString) else { return }
        isFieldFocused = false
        onInvoke(url)
    }

    private func isValidURL(_ string: String) -> Bool {
        normalizeURLString(string).flatMap { URL(string: $0) } != nil
    }

    private func openURL() {
        guard let url = normalizeURLString(urlString).flatMap({ URL(string: $0) }) else { return }
        isFieldFocused = false
        onInvoke(url)
    }

    /// Accept "evergreen.app/breathe/waterloo" or "https://evergreen.app/breathe/waterloo"
    private func normalizeURLString(_ input: String) -> String? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if trimmed.contains("://") {
            return trimmed
        }
        return "https://" + trimmed
    }
}

// MARK: - ClipRouterView

/// Resolves the invocation URL to a registered ClipExperience and presents it.
struct ClipRouterView<Overlay: View>: View {
    let invocationURL: URL
    @ViewBuilder let overlay: () -> Overlay

    var body: some View {
        ZStack(alignment: .topLeading) {
            if let view = ClipRouter.resolve(url: invocationURL) {
                view
            } else {
                unresolvedView
            }
            overlay()
        }
        .ignoresSafeArea(.container, edges: .bottom)
    }

    private var unresolvedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "link.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No clip matched this URL")
                .font(.system(size: 20, weight: .semibold))
            Text(invocationURL.absoluteString)
                .font(.system(size: 14, design: .monospaced))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - ClipRouter (URL → ClipExperience)

enum ClipRouter {
    /// Match URL against registered clip urlPatterns; return the matching clip view or nil.
    static func resolve(url: URL) -> AnyView? {
        let pathString = urlPathString(from: url)
        for clipType in SubmissionRegistry.all {
            if var params = match(pattern: clipType.urlPattern, pathString: pathString) {
                let context = ClipContext(
                    invocationURL: url,
                    pathParameters: params
                )
                if let view = makeView(for: clipType, context: context) {
                    return view
                }
            }
        }
        return nil
    }

    /// Build path string for matching: "host/path/components" (no scheme, no leading slash).
    private static func urlPathString(from url: URL) -> String {
        var comps = [String]()
        if let host = url.host(), !host.isEmpty {
            comps.append(host)
        }
        let path = url.path
        if !path.isEmpty {
            comps.append(contentsOf: url.pathComponents.filter { $0 != "/" })
        }
        return comps.joined(separator: "/")
    }

    /// Match path string to pattern "domain.com/path/:param". Returns path parameters or nil.
    private static func match(pattern: String, pathString: String) -> [String: String]? {
        let patternParts = pattern.split(separator: "/").map(String.init)
        let pathParts = pathString.split(separator: "/").map(String.init)
        guard patternParts.count == pathParts.count else { return nil }
        var params = [String: String]()
        for (i, patternPart) in patternParts.enumerated() {
            if patternPart.hasPrefix(":") {
                let key = String(patternPart.dropFirst())
                params[key] = pathParts[i]
            } else if patternPart != pathParts[i] {
                return nil
            }
        }
        return params
    }

    /// Instantiate the concrete ClipExperience type with the given context.
    private static func makeView(for type: any ClipExperience.Type, context: ClipContext) -> AnyView? {
        if type == EvergreenClipExperience.self {
            return AnyView(EvergreenClipExperience(context: context))
        }
        if type == EmptyClipExperience.self {
            return AnyView(EmptyClipExperience(context: context))
        }
        if type == OasisExperience.self {
            return AnyView(OasisExperience(context: context))
        }
        return nil
    }
}
