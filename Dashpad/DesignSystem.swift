import SwiftUI

enum Dash {
    enum Colors {
        static let background = Color(hex: "09090B")
        static let backgroundGradientTop = Color(hex: "13121A")
        static let backgroundGradientBottom = Color(hex: "09090B")

        static let cardBackground = Color(hex: "18181B")
        static let cardBackgroundElevated = Color(hex: "1F1F23")
        static let cardBorder = Color(hex: "27272A")

        static let accent = Color(hex: "8B5CF6")
        static let accentLight = Color(hex: "A78BFA")
        static let accentGlow = Color(hex: "8B5CF6").opacity(0.4)
        static let accentGradientStart = Color(hex: "8B5CF6")
        static let accentGradientEnd = Color(hex: "6366F1")

        static let success = Color(hex: "34D399")
        static let successGlow = Color(hex: "34D399").opacity(0.4)

        static let warning = Color(hex: "FBBF24")
        static let warningGlow = Color(hex: "FBBF24").opacity(0.3)

        static let overdue = Color(hex: "F87171")
        static let overdueGlow = Color(hex: "F87171").opacity(0.3)

        static let textPrimary = Color(hex: "FAFAFA")
        static let textSecondary = Color(hex: "A1A1AA")
        static let textTertiary = Color(hex: "52525B")

        static let divider = Color(hex: "3F3F46")
    }

    enum Typography {
        static let largeTitle = Font.system(size: 32, weight: .semibold)
        static let title = Font.system(size: 22, weight: .semibold)
        static let title2 = Font.system(size: 18, weight: .medium)
        static let headline = Font.system(size: 17, weight: .semibold)
        static let body = Font.system(size: 16, weight: .regular)
        static let caption = Font.system(size: 13, weight: .medium)
        static let micro = Font.system(size: 11, weight: .semibold)
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
