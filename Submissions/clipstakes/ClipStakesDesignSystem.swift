import SwiftUI

enum ClipStakesPalette {
    static let ink = Color(red: 0.08, green: 0.05, blue: 0.12)
    static let shadowInk = Color(red: 0.04, green: 0.02, blue: 0.08)
    static let neonPink = Color(red: 1.00, green: 0.31, blue: 0.63)
    static let neonOrange = Color(red: 1.00, green: 0.55, blue: 0.20)
    static let neonBlue = Color(red: 0.26, green: 0.69, blue: 1.00)
    static let mint = Color(red: 0.31, green: 0.92, blue: 0.78)
    static let cardBase = Color.white.opacity(0.08)
    static let cardBorder = Color.white.opacity(0.22)

    static let primaryGradient = LinearGradient(
        colors: [neonPink, neonOrange],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let accentGradient = LinearGradient(
        colors: [neonBlue, mint],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct ClipStakesStageBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [ClipStakesPalette.shadowInk, ClipStakesPalette.ink],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(ClipStakesPalette.neonPink.opacity(0.35))
                .blur(radius: 80)
                .frame(width: 260, height: 260)
                .offset(x: 120, y: -240)

            Circle()
                .fill(ClipStakesPalette.neonBlue.opacity(0.25))
                .blur(radius: 90)
                .frame(width: 280, height: 280)
                .offset(x: -120, y: -80)

            Circle()
                .fill(ClipStakesPalette.neonOrange.opacity(0.24))
                .blur(radius: 100)
                .frame(width: 290, height: 290)
                .offset(x: 80, y: 280)

            VStack(spacing: 0) {
                ForEach(0..<16, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.white.opacity(0.015))
                        .frame(height: 1)
                        .padding(.horizontal, 24)
                    Spacer()
                }
            }
            .padding(.vertical, 12)
        }
        .ignoresSafeArea()
    }
}

struct ClipStakesGlassCardModifier: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(ClipStakesPalette.cardBase)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(ClipStakesPalette.cardBorder, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.28), radius: 18, y: 10)
    }
}

extension View {
    func clipStakesGlassCard(cornerRadius: CGFloat = 22) -> some View {
        modifier(ClipStakesGlassCardModifier(cornerRadius: cornerRadius))
    }
}

struct ClipStakesInfoChip: View {
    let title: String
    let icon: String
    var tint: Color = .white

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(title)
        }
        .font(.system(size: 11, weight: .bold, design: .rounded))
        .foregroundStyle(tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .clipStakesGlassCard(cornerRadius: 999)
    }
}

struct ClipStakesPrimaryButtonStyle: ButtonStyle {
    var disabled = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        disabled
                            ? AnyShapeStyle(Color.gray.opacity(0.35))
                            : AnyShapeStyle(ClipStakesPalette.primaryGradient)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.28), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
    }
}

struct ClipStakesSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .clipStakesGlassCard(cornerRadius: 14)
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
    }
}

struct ClipStakesStepPill: View {
    let label: String
    let isActive: Bool

    var body: some View {
        Text(label)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundStyle(isActive ? Color.black : Color.white.opacity(0.85))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isActive ? AnyShapeStyle(ClipStakesPalette.accentGradient) : AnyShapeStyle(Color.white.opacity(0.1)))
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(isActive ? 0.0 : 0.2), lineWidth: 1)
            )
    }
}
