import SwiftUI
import Combine

// MARK: - Theme Mode
enum ThemeMode: String, CaseIterable {
    case dark = "Dark"
    case oled = "OLED"
    case eco = "Eco-Voyager"
    
    var backgroundColor: Color {
        switch self {
        case .dark:
            return DesignTokens.Colors.backgroundDark
        case .oled, .eco:
            return DesignTokens.Colors.backgroundOLED
        }
    }
    
    var surfaceColor: Color {
        switch self {
        case .dark:
            return DesignTokens.Colors.surfacePrimary
        case .oled:
            return Color(hex: "#0A0A0A")
        case .eco:
            return Color.black
        }
    }
    
    var isAnimationReduced: Bool {
        self == .eco
    }
    
    var iconName: String {
        switch self {
        case .dark:
            return "moon.fill"
        case .oled:
            return "circle.fill"
        case .eco:
            return "leaf.fill"
        }
    }
}

// MARK: - Theme Manager
@MainActor
final class ThemeManager: ObservableObject {
    @Published var currentTheme: ThemeMode = .dark
    @Published var isEcoModeEnabled: Bool = false
    
    var backgroundColor: Color {
        currentTheme.backgroundColor
    }
    
    var surfaceColor: Color {
        currentTheme.surfaceColor
    }
    
    var isAnimationReduced: Bool {
        currentTheme.isAnimationReduced
    }
    
    func toggleEcoMode() {
        withAnimation(DesignTokens.Animation.spring) {
            if isEcoModeEnabled {
                isEcoModeEnabled = false
                currentTheme = .dark
            } else {
                isEcoModeEnabled = true
                currentTheme = .eco
            }
        }
    }
    
    func setTheme(_ theme: ThemeMode) {
        withAnimation(DesignTokens.Animation.spring) {
            currentTheme = theme
            isEcoModeEnabled = theme == .eco
        }
    }
}
