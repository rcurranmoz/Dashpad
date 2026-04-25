import SwiftUI

enum Dash {
    enum Colors {
        // Backgrounds — deep navy-black
        static let background       = Color(hex: "070A10")
        static let bgTop            = Color(hex: "0C1018")
        static let bgBottom         = Color(hex: "070A10")

        // Surfaces
        static let surface          = Color(hex: "0C1018")
        static let surfaceElevated  = Color(hex: "111822")
        static let border           = Color(hex: "1A2030")
        static let borderSubtle     = Color(hex: "131B27")

        // Accent: electric sky blue / cyan
        static let accent           = Color(hex: "0EA5E9")   // sky-500
        static let accentBright     = Color(hex: "38BDF8")   // sky-400
        static let accentDim        = Color(hex: "0EA5E9").opacity(0.25)
        static let accentGradStart  = Color(hex: "38BDF8")
        static let accentGradEnd    = Color(hex: "0284C7")

        // Semantic
        static let success          = Color(hex: "10B981")
        static let successDim       = Color(hex: "10B981").opacity(0.25)
        static let warning          = Color(hex: "F59E0B")
        static let warningDim       = Color(hex: "F59E0B").opacity(0.25)
        static let danger           = Color(hex: "F87171")
        static let dangerDim        = Color(hex: "F87171").opacity(0.25)

        // Text
        static let textPrimary      = Color(hex: "F1F5F9")   // slate-100
        static let textSecondary    = Color(hex: "94A3B8")   // slate-400
        static let textTertiary     = Color(hex: "475569")   // slate-600

        // Misc
        static let divider          = Color(hex: "1E2A3A")
        static let scrim            = Color(hex: "000000").opacity(0.6)

        // Legacy aliases so existing code compiles without changes
        static let backgroundGradientTop    = bgTop
        static let backgroundGradientBottom = bgBottom
        static let cardBackground           = surface
        static let cardBackgroundElevated   = surfaceElevated
        static let cardBorder               = border
        static let accentLight              = accentBright
        static let accentGlow               = accentDim
        static let accentGradientStart      = accentGradStart
        static let accentGradientEnd        = accentGradEnd
        static let successGlow              = successDim
        static let warningGlow              = warningDim
        static let overdue                  = danger
        static let overdueLight             = Color(hex: "FCA5A5")
        static let overdueGlow              = dangerDim
    }

    enum Typography {
        static let largeTitle   = Font.system(size: 36, weight: .black)
        static let title        = Font.system(size: 22, weight: .semibold, design: .rounded)
        static let title2       = Font.system(size: 18, weight: .medium)
        static let headline     = Font.system(size: 16, weight: .semibold)
        static let body         = Font.system(size: 15, weight: .regular)
        static let caption      = Font.system(size: 13, weight: .medium)
        static let micro        = Font.system(size: 11, weight: .semibold)
    }

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 28
    }

    enum Radius {
        static let sm: CGFloat = 10
        static let md: CGFloat = 14
        static let lg: CGFloat = 18
        static let xl: CGFloat = 24
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
