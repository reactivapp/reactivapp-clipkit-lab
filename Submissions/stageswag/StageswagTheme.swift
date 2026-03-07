import SwiftUI

// MARK: - Color Hex Init (own copy since ClipBackground's is private)

extension Color {
    init(stageswagHex hex: String) {
        let trimmed = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: trimmed).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Theme

enum StageswagTheme: String, CaseIterable, Identifiable {
    case neonNight
    case electricStorm
    case sunsetVenue
    case midnightJazz

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .neonNight: return "Neon Night"
        case .electricStorm: return "Electric Storm"
        case .sunsetVenue: return "Sunset Venue"
        case .midnightJazz: return "Midnight Jazz"
        }
    }

    var pickerColor: Color {
        switch self {
        case .neonNight: return Color(stageswagHex: "#B24BF3")
        case .electricStorm: return Color(stageswagHex: "#2563EB")
        case .sunsetVenue: return Color(stageswagHex: "#F97316")
        case .midnightJazz: return Color(stageswagHex: "#312E81")
        }
    }

    var primaryGradient: [Color] {
        switch self {
        case .neonNight:
            return [Color(stageswagHex: "#7C3AED"), Color(stageswagHex: "#EC4899"), Color(stageswagHex: "#06B6D4")]
        case .electricStorm:
            return [Color(stageswagHex: "#1E3A8A"), Color(stageswagHex: "#2563EB"), Color(stageswagHex: "#FACC15")]
        case .sunsetVenue:
            return [Color(stageswagHex: "#EA580C"), Color(stageswagHex: "#F472B6"), Color(stageswagHex: "#F59E0B")]
        case .midnightJazz:
            return [Color(stageswagHex: "#312E81"), Color(stageswagHex: "#4338CA"), Color(stageswagHex: "#F59E0B")]
        }
    }

    var accentColor: Color {
        switch self {
        case .neonNight: return Color(stageswagHex: "#06B6D4")
        case .electricStorm: return Color(stageswagHex: "#FACC15")
        case .sunsetVenue: return Color(stageswagHex: "#F97316")
        case .midnightJazz: return Color(stageswagHex: "#F59E0B")
        }
    }

    var secondaryAccent: Color {
        switch self {
        case .neonNight: return Color(stageswagHex: "#EC4899")
        case .electricStorm: return Color(stageswagHex: "#60A5FA")
        case .sunsetVenue: return Color(stageswagHex: "#F472B6")
        case .midnightJazz: return Color(stageswagHex: "#818CF8")
        }
    }

    var surfaceTint: Color {
        switch self {
        case .neonNight: return Color(stageswagHex: "#7C3AED")
        case .electricStorm: return Color(stageswagHex: "#2563EB")
        case .sunsetVenue: return Color(stageswagHex: "#EA580C")
        case .midnightJazz: return Color(stageswagHex: "#4338CA")
        }
    }

    var textHighlight: Color {
        switch self {
        case .neonNight: return Color(stageswagHex: "#A78BFA")
        case .electricStorm: return Color(stageswagHex: "#93C5FD")
        case .sunsetVenue: return Color(stageswagHex: "#FDBA74")
        case .midnightJazz: return Color(stageswagHex: "#C4B5FD")
        }
    }
}
