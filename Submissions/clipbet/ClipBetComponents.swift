//  ClipBetComponents.swift
//  ClipBet
//
//  Reusable UI components following the editorial-minimal design system.
//  Cormorant Garamond for emotional/structural content.
//  DM Mono for functional UI.
//

import SwiftUI

// MARK: - Status Indicator

struct StatusIndicator: View {
    let status: EventStatus
    @State private var pulsing = false

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(status.dotColor)
                .frame(width: 6, height: 6)
                .opacity(pulsing ? 0.4 : 1.0)

            Text(status.rawValue)
                .font(.custom("DM Mono", size: 11))
                .kerning(2)
                .foregroundColor(ClipBetColors.textSecondary)
                .textCase(.uppercase)
        }
        .onAppear {
            if status.isPulsing {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    pulsing = true
                }
            }
        }
    }
}

// MARK: - Outcome Row

struct OutcomeRow: View {
    let outcome: BetOutcome
    let percentage: Double
    let isFirst: Bool

    private var color: Color {
        isFirst ? ClipBetColors.yes : ClipBetColors.no
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(outcome.name)
                    .font(.custom("DM Mono", size: 14))
                    .foregroundColor(ClipBetColors.textPrimary)

                Spacer()

                Text(String(format: "%.0f%%", percentage))
                    .font(.custom("Cormorant Garamond", size: 28))
                    .fontWeight(.light)
                    .foregroundColor(color)
            }

            // 3px progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(ClipBetColors.divider)
                        .frame(height: 3)

                    Rectangle()
                        .fill(color)
                        .frame(width: geo.size.width * (percentage / 100), height: 3)
                }
            }
            .frame(height: 3)

            HStack {
                Text(outcome.formattedAmount)
                    .font(.custom("DM Mono", size: 11))
                    .foregroundColor(ClipBetColors.textSecondary)

                Spacer()

                Text("\(outcome.betCount) bets")
                    .font(.custom("DM Mono", size: 11))
                    .foregroundColor(ClipBetColors.textFaint)
            }
        }
        .padding(.vertical, 16)
    }
}

// MARK: - Hairline Divider

struct ClipBetDivider: View {
    var body: some View {
        Rectangle()
            .fill(ClipBetColors.divider)
            .frame(height: 1)
    }
}

// MARK: - Vertical Divider

struct ClipBetVerticalDivider: View {
    var height: CGFloat = 40

    var body: some View {
        Rectangle()
            .fill(ClipBetColors.divider)
            .frame(width: 1, height: height)
    }
}

// MARK: - Dark Confirm Divider

struct ClipBetDarkDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(height: 1)
    }
}

// MARK: - Mono Label (Centered)

struct MonoLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.custom("DM Mono", size: 11))
            .kerning(1.8)
            .foregroundColor(ClipBetColors.textSecondary)
            .textCase(.uppercase)
            .multilineTextAlignment(.center)
    }
}

// MARK: - Mono Label (Left Aligned)

struct MonoLabelLeft: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.custom("DM Mono", size: 10))
            .kerning(2)
            .foregroundColor(ClipBetColors.textSecondary)
            .textCase(.uppercase)
    }
}

// MARK: - Stat Column (Newspaper Style)

struct StatColumn: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.custom("Cormorant Garamond", size: 26))
                .fontWeight(.light)
                .foregroundColor(ClipBetColors.textPrimary)

            Text(label)
                .font(.custom("DM Mono", size: 9))
                .kerning(1.6)
                .foregroundColor(ClipBetColors.textSecondary)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Primary CTA Button

struct ClipBetPrimaryButton: View {
    let title: String
    var icon: String? = nil
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                }
                Text(title)
                    .font(.custom("DM Mono", size: 13))
                    .kerning(2.4)
            }
            .foregroundColor(ClipBetColors.bg)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isEnabled ? ClipBetColors.dark : ClipBetColors.textFaint)
            .clipShape(RoundedRectangle(cornerRadius: 2))
        }
        .disabled(!isEnabled)
    }
}

// MARK: - Secondary Button

struct ClipBetSecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.custom("DM Mono", size: 11))
                .kerning(1.4)
                .foregroundColor(ClipBetColors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(ClipBetColors.divider, lineWidth: 1)
                )
        }
    }
}

// MARK: - Amount Selector Button

struct AmountButton: View {
    let amount: Double
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("$\(Int(amount))")
                .font(.custom("DM Mono", size: 14))
                .foregroundColor(isSelected ? ClipBetColors.bg : ClipBetColors.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(isSelected ? ClipBetColors.dark : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(isSelected ? Color.clear : ClipBetColors.divider, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 2))
        }
    }
}

// MARK: - Back Button

struct ClipBetBackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 12))
                Text("BACK")
                    .font(.custom("DM Mono", size: 11))
                    .kerning(1.6)
            }
            .foregroundColor(ClipBetColors.textSecondary)
        }
    }
}

// MARK: - Confirm Row (Dark Background)

struct ConfirmRow: View {
    let label: String
    let value: String
    var isMultiline: Bool = false
    var valueColor: Color = .white

    var body: some View {
        HStack(alignment: isMultiline ? .top : .center) {
            Text(label)
                .font(.custom("DM Mono", size: 10))
                .kerning(1.6)
                .foregroundColor(ClipBetColors.textFaint)
                .frame(width: 90, alignment: .leading)

            Text(value)
                .font(.custom("DM Mono", size: 13))
                .foregroundColor(valueColor)
                .lineLimit(isMultiline ? 3 : 1)

            Spacer()
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Receipt Row (Light Background)

struct ReceiptRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.custom("DM Mono", size: 10))
                .kerning(1.6)
                .foregroundColor(ClipBetColors.textSecondary)
                .frame(width: 90, alignment: .leading)

            Text(value)
                .font(.custom("DM Mono", size: 13))
                .foregroundColor(ClipBetColors.textPrimary)
                .lineLimit(2)

            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Text Field (Editorial Style)

struct ClipBetTextField: View {
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .never

    var body: some View {
        TextField(placeholder, text: $text)
            .font(.custom("DM Mono", size: 14))
            .foregroundColor(ClipBetColors.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(ClipBetColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 2))
            .textInputAutocapitalization(autocapitalization)
            .keyboardType(keyboardType)
    }
}

// MARK: - Tag Badge

struct ClipBetTag: View {
    let text: String
    var color: Color = ClipBetColors.accent

    var body: some View {
        Text(text)
            .font(.custom("DM Mono", size: 9))
            .kerning(1.2)
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(color, lineWidth: 1)
            )
    }
}
