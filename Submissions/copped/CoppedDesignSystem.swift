import SwiftUI

enum CoppedPalette {
    static let ink = Color(red: 0.08, green: 0.05, blue: 0.12)
    static let shadowInk = Color(red: 0.04, green: 0.02, blue: 0.08)
    static let neonPink = Color(red: 1.00, green: 0.31, blue: 0.63)
    static let neonOrange = Color(red: 1.00, green: 0.55, blue: 0.20)
    static let neonBlue = Color(red: 0.26, green: 0.69, blue: 1.00)
    static let mint = Color(red: 0.31, green: 0.92, blue: 0.78)
    static let cardBase = Color.white.opacity(0.07)
    static let cardBorder = Color.white.opacity(0.14)
    static let surfaceElevated = Color.white.opacity(0.10)

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

    static let subtleGradient = LinearGradient(
        colors: [Color.white.opacity(0.08), Color.white.opacity(0.02)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct CoppedStageBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [CoppedPalette.shadowInk, CoppedPalette.ink],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(CoppedPalette.neonPink.opacity(0.22))
                .blur(radius: 100)
                .frame(width: 220, height: 220)
                .offset(x: 120, y: -260)

            Circle()
                .fill(CoppedPalette.neonBlue.opacity(0.16))
                .blur(radius: 110)
                .frame(width: 240, height: 240)
                .offset(x: -130, y: -60)

            Circle()
                .fill(CoppedPalette.neonOrange.opacity(0.14))
                .blur(radius: 120)
                .frame(width: 250, height: 250)
                .offset(x: 80, y: 300)
        }
        .ignoresSafeArea()
    }
}

struct CoppedGlassCardModifier: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(CoppedPalette.cardBase)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(CoppedPalette.cardBorder, lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.22), radius: 12, y: 6)
    }
}

extension View {
    func clipStakesGlassCard(cornerRadius: CGFloat = 22) -> some View {
        modifier(CoppedGlassCardModifier(cornerRadius: cornerRadius))
    }
}

struct CoppedInfoChip: View {
    let title: String
    let icon: String
    var tint: Color = .white

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .bold))
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .rounded))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(tint.opacity(0.12), in: Capsule())
        .overlay(Capsule().stroke(tint.opacity(0.25), lineWidth: 0.5))
    }
}

struct CoppedPrimaryButtonStyle: ButtonStyle {
    var disabled = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        disabled
                            ? AnyShapeStyle(Color.gray.opacity(0.3))
                            : AnyShapeStyle(CoppedPalette.primaryGradient)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(disabled ? 0.1 : 0.2), lineWidth: 0.5)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct CoppedSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundStyle(.white.opacity(0.9))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct CoppedStepPill: View {
    let label: String
    let isActive: Bool

    var body: some View {
        Text(label)
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundStyle(isActive ? Color.black : Color.white.opacity(0.6))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(isActive ? AnyShapeStyle(CoppedPalette.accentGradient) : AnyShapeStyle(Color.white.opacity(0.08)))
            )
            .animation(.easeInOut(duration: 0.25), value: isActive)
    }
}
