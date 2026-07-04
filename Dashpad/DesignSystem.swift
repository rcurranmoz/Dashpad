import SwiftUI

// Dashpad's visual identity: embers in the dark.
// Warm ink-black paper, ideas typeset in serif, a single ember accent.
// Chrome is sans; captured thoughts are serif — a notebook, not a dashboard.
enum Dash {
    enum Colors {
        // Backgrounds — neutral graphite, modern and calm.
        // The ember lives in the accent, not the atmosphere.
        static let background       = Color(hex: "0B0B0D")
        static let bgTop            = Color(hex: "111114")
        static let bgBottom        = Color(hex: "0B0B0D")
        static let emberGlow        = Color(hex: "38200F")   // splash-only radial glow

        // Surfaces — clean charcoal
        static let surface          = Color(hex: "17171B")
        static let surfaceElevated  = Color(hex: "1E1E23")
        static let border           = Color(hex: "2A2A31")
        static let borderSubtle     = Color(hex: "222228")
        static let edgeLight        = Color(hex: "FFFFFF").opacity(0.06) // top-lit card edge

        // Accent: ember
        static let accent           = Color(hex: "FF9F45")
        static let accentBright     = Color(hex: "FFB868")
        static let accentDeep       = Color(hex: "F26B2A")
        static let accentDim        = Color(hex: "FF9F45").opacity(0.22)
        static let accentGradStart  = Color(hex: "FFB868")
        static let accentGradEnd    = Color(hex: "E85D26")

        // Semantic
        static let success          = Color(hex: "8FBF6F")
        static let successDim       = Color(hex: "8FBF6F").opacity(0.25)
        static let warning          = Color(hex: "FFB868")
        static let warningDim       = Color(hex: "FFB868").opacity(0.25)
        static let danger           = Color(hex: "E5484D")
        static let dangerDim        = Color(hex: "E5484D").opacity(0.25)

        // Text — just-off-white, a hint of warmth without going sepia
        static let textPrimary      = Color(hex: "F2F1ED")
        static let textSecondary    = Color(hex: "9E9DA4")
        static let textTertiary     = Color(hex: "65646C")

        // Misc
        static let divider          = Color(hex: "2E2E36")
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
        static let overdueLight             = Color(hex: "F2888C")
        static let overdueGlow              = dangerDim
    }

    enum Typography {
        // Chrome (sans)
        static let largeTitle   = Font.system(size: 32, weight: .bold, design: .serif)
        static let title        = Font.system(size: 22, weight: .semibold, design: .serif)
        static let title2       = Font.system(size: 18, weight: .medium)
        static let headline     = Font.system(size: 16, weight: .semibold)
        static let body         = Font.system(size: 15, weight: .regular)
        static let caption      = Font.system(size: 13, weight: .medium)
        static let micro        = Font.system(size: 11, weight: .semibold)

        // Content (serif) — captured ideas read like set type
        static let idea         = Font.system(size: 17, weight: .medium, design: .serif)
        static let ideaBody     = Font.system(size: 14, weight: .regular, design: .serif)
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
        static let md: CGFloat = 18
        static let lg: CGFloat = 22
        static let xl: CGFloat = 26
    }
}

// MARK: - Card Surface

extension View {
    /// The standard Dashpad card: warm charcoal paper with a faint
    /// top-lit edge, like light falling on it from above.
    func dashCard(cornerRadius: CGFloat = Dash.Radius.md, glow: Color = .clear) -> some View {
        background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Dash.Colors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(
                            LinearGradient(
                                colors: [Dash.Colors.edgeLight, Dash.Colors.border.opacity(0.4)],
                                startPoint: .top, endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.35), radius: 14, y: 6)
                .shadow(color: glow, radius: 18, y: 4)
        )
    }
}

extension View {
    /// Staged entrance: rows rise and fade in one after another,
    /// dealt onto the pad rather than popping in all at once.
    func cascadeIn(index: Int, revealed: Bool) -> some View {
        self
            .opacity(revealed ? 1 : 0)
            .offset(y: revealed ? 0 : 18)
            .animation(
                .spring(response: 0.5, dampingFraction: 0.75)
                    .delay(Double(min(index, 7)) * 0.06),
                value: revealed
            )
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
