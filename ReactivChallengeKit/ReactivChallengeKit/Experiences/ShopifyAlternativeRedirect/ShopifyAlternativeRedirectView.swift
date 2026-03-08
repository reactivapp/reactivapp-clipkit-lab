//  ShopifyAlternativeRedirectView.swift
//  ReactivChallengeKit
//
//  Copyright © 2025 Reactiv Technologies Inc. All rights reserved.
//

import SwiftUI

@MainActor
struct ShopifyAlternativeRedirectView: View {
    let context: ClipContext

    @Environment(\.openURL) private var openURL
    @StateObject private var viewModel = ShopifyAlternativeViewModel()
    @FocusState private var isInputFocused: Bool

    var body: some View {
        ZStack(alignment: .bottom) {
            ClipBackground()
                .blur(radius: 28)
                .overlay(Color.black.opacity(0.2))
                .ignoresSafeArea()

            Color.black.opacity(0.08)
                .ignoresSafeArea()

            bottomSheet
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
        }
        .task {
            await viewModel.loadIfNeeded(from: context)
        }
    }

    private var bottomSheet: some View {
        VStack(alignment: .leading, spacing: 12) {
            Capsule()
                .fill(Color.white.opacity(0.5))
                .frame(width: 46, height: 5)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)

            VStack(alignment: .leading, spacing: 4) {
                Text("Shopify Alternatives")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.primary)

                Text(sourceContextLabel)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 4)

            urlInputRow

            content
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.white.opacity(0.16), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: -4)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            LoadingView()
        case .loaded:
            if viewModel.products.isEmpty {
                emptyState
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    if let note = viewModel.discoveryNote {
                        Text(note)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)
                    }

                    ScrollView {
                        LazyVStack(spacing: 14) {
                            ForEach(viewModel.products) { product in
                                ProductCardView(product: product) {
                                    openStore(for: product)
                                }
                            }
                        }
                        .padding(.top, 2)
                        .padding(.bottom, 8)
                    }
                    .scrollIndicators(.hidden)
                    .frame(maxHeight: 430)
                }
            }
        case .error(let message):
            errorState(message: message)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.secondary)

            Text(viewModel.emptyStateMessage)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    private func errorState(message: String) -> some View {
        VStack(spacing: 12) {
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                Task {
                    await viewModel.submitURL()
                }
            } label: {
                Text("Try Again")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(.blue, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private var urlInputRow: some View {
        HStack(spacing: 10) {
            TextField("Paste product URL...", text: $viewModel.inputURLText)
                .font(.system(size: 14))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)
                .submitLabel(.search)
                .focused($isInputFocused)
                .onSubmit {
                    Task { await viewModel.submitURL() }
                }

            Button {
                isInputFocused = false
                Task { await viewModel.submitURL() }
            } label: {
                Text("Find")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.blue, in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(!canFind)
            .opacity(canFind ? 1.0 : 0.6)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 12))
    }

    private var canFind: Bool {
        !viewModel.isLoading && !viewModel.inputURLText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var sourceContextLabel: String {
        guard let host = viewModel.sourceProductURL?.host?.replacingOccurrences(of: "www.", with: "") else {
            return "Paste a product URL below."
        }
        return "Source: \(host)"
    }

    private func openStore(for product: AlternativeProduct) {
        guard let productURL = product.resolvedProductURL else { return }
        openURL(productURL)
    }
}
