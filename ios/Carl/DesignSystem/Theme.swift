import SwiftUI

/// Carl's brand palette, derived from the logo (navy #1B2A4A + royal blue #2563EB)
/// and the Claude Design handoff.
enum CarlColor {
    static let navy = Color(hex: 0x1B2A4A)
    static let navyDeep = Color(hex: 0x16223D)
    static let navyDeeper = Color(hex: 0x0E1830)
    static let ink = Color(hex: 0x0A0E1A)
    static let royal = Color(hex: 0x2563EB)
    static let royalSoft = Color(hex: 0x5B8DEF)

    // Surfaces
    static let canvas = Color(hex: 0xE7E9F0)
    static let screenBG = Color(hex: 0xF5F7FB)
    static let settingsBG = Color(hex: 0xF0F2F7)
    static let card = Color.white
    static let faceCream = Color(hex: 0xF4F8FF)
    static let tintFill = Color(hex: 0xEEF3FF)
    static let tintFillAlt = Color(hex: 0xF7F9FC)

    // Text
    static let textStrong = Color(hex: 0x1B2A4A)
    static let textBody = Color(hex: 0x3D4759)
    static let textMuted = Color(hex: 0x5B6478)
    static let textSoft = Color(hex: 0x7A8499)
    static let textFaint = Color(hex: 0x8A93A6)
    static let textGhost = Color(hex: 0x9AA3B5)
    static let textOnNavyMuted = Color(hex: 0x9DB0D8)
    static let textOnNavySoft = Color(hex: 0xC7D4EE)

    // Lines
    static let border = Color(hex: 0xDCE3F1)
    static let borderSoft = Color(hex: 0xE1E7F2)
    static let hairline = Color(hex: 0xEEF1F7)
    static let hairlineCool = Color(hex: 0xE4E9F2)
    static let track = Color(hex: 0xE2E7F1)

    // Status
    static let green = Color(hex: 0x16A34A)
    static let greenDeep = Color(hex: 0x15803D)
    static let greenBG = Color(hex: 0xEAF7EF)
    static let red = Color(hex: 0xE0382B)
    static let gold = Color(hex: 0xFFD166)
    static let mint = Color(hex: 0x7FE3B0)

    // Accents used for source/avatar chips
    static let greenhouse = Color(hex: 0x0E7C66)
    static let lever = Color(hex: 0x6D28D9)
    static let ashby = Color(hex: 0xB4541E)
    static let slate = Color(hex: 0x475569)
}

/// Typography. The design calls for Plus Jakarta Sans. If the TTFs are added to
/// the bundle (and registered via Info.plist `UIAppFonts`) `usePlusJakarta`
/// picks them up; otherwise we fall back to the system rounded design, which is
/// the closest friendly-geometric match out of the box.
enum CarlFont {
    static let usePlusJakarta = false
    private static let family = "PlusJakartaSans"

    static func custom(_ size: CGFloat, _ weight: Font.Weight) -> Font {
        if usePlusJakarta {
            return .custom(jakartaName(weight), size: size)
        }
        return .system(size: size, weight: weight, design: .rounded)
    }

    private static func jakartaName(_ weight: Font.Weight) -> String {
        switch weight {
        case .bold, .heavy, .black: return "\(family)-Bold"
        case .semibold: return "\(family)-SemiBold"
        case .medium: return "\(family)-Medium"
        default: return "\(family)-Regular"
        }
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

extension Text {
    func carl(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Text {
        font(CarlFont.custom(size, weight))
    }
}

extension View {
    func carlFont(_ size: CGFloat, _ weight: Font.Weight = .regular) -> some View {
        font(CarlFont.custom(size, weight))
    }
}
