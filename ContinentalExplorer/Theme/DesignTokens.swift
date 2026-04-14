import SwiftUI

// MARK: - Design Tokens
/// Continental Explorer Design System
/// Primary Accent: #4CD6FF (Cyan Neon)
/// Secondary Accent: #FFB68D (Amber Alert)
/// Background Dark: #101223
/// Background OLED: #000000

enum DesignTokens {
    
    // MARK: - Colors
    enum Colors {
        static let primaryAccent = Color(hex: "#4CD6FF")
        static let secondaryAccent = Color(hex: "#FFB68D")
        static let backgroundDark = Color(hex: "#101223")
        static let backgroundOLED = Color.black
        
        static let surfacePrimary = Color(hex: "#1A1D35")
        static let surfaceSecondary = Color(hex: "#252845")
        static let surfaceElevated = Color(hex: "#2F3358")
        
        static let textPrimary = Color.white
        static let textSecondary = Color(hex: "#A0A3BD")
        static let textTertiary = Color(hex: "#6E7191")
        
        static let success = Color(hex: "#00D68F")
        static let warning = Color(hex: "#FFB68D")
        static let danger = Color(hex: "#FF6B6B")
        static let info = Color(hex: "#4CD6FF")
        
        static let speedSafe = Color(hex: "#00D68F")
        static let speedWarning = Color(hex: "#FFB68D")
        static let speedDanger = Color(hex: "#FF6B6B")
        
        static let radarFixed = Color(hex: "#FF6B6B")
        static let radarMobile = Color(hex: "#FFB68D")
        static let radarAverage = Color(hex: "#B68DFF")
    }
    
    // MARK: - Spacing
    enum Spacing {
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        static let xxxl: CGFloat = 64
    }
    
    // MARK: - Corner Radius
    enum CornerRadius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let pill: CGFloat = 999
    }
    
    // MARK: - Shadows
    enum Shadows {
        static let glow = Color(hex: "#4CD6FF").opacity(0.3)
        static let alertGlow = Color(hex: "#FFB68D").opacity(0.4)
        static let dangerGlow = Color(hex: "#FF6B6B").opacity(0.4)
    }
    
    // MARK: - Animation
    enum Animation {
        static let fast: Double = 0.15
        static let normal: Double = 0.3
        static let slow: Double = 0.5
        static let spring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.8)
        static let easeOut = SwiftUI.Animation.easeOut(duration: 0.3)
    }
    
    // MARK: - HUD
    enum HUD {
        static let materialOpacity: Double = 0.85
        static let blurRadius: CGFloat = 20
        static let borderWidth: CGFloat = 0.5
        static let borderColor = Color.white.opacity(0.1)
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
