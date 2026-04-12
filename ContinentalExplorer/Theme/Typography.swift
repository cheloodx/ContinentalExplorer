import SwiftUI

// MARK: - Typography
/// Continental Explorer Typography System
/// Headlines: Space Grotesk
/// Body: Inter / Plus Jakarta Sans
/// Falls back to system fonts when custom fonts unavailable

enum Typography {
    
    // MARK: - Font Names
    private static let headlineFamily = "SpaceGrotesk"
    private static let bodyFamily = "Inter"
    
    // MARK: - Headlines
    static func headline(_ size: HeadlineSize) -> Font {
        .custom("\(headlineFamily)-Bold", size: size.rawValue, relativeTo: size.textStyle)
    }
    
    static func headlineMedium(_ size: HeadlineSize) -> Font {
        .custom("\(headlineFamily)-Medium", size: size.rawValue, relativeTo: size.textStyle)
    }
    
    // MARK: - Body
    static func body(_ size: BodySize) -> Font {
        .custom("\(bodyFamily)-Regular", size: size.rawValue, relativeTo: size.textStyle)
    }
    
    static func bodyMedium(_ size: BodySize) -> Font {
        .custom("\(bodyFamily)-Medium", size: size.rawValue, relativeTo: size.textStyle)
    }
    
    static func bodySemiBold(_ size: BodySize) -> Font {
        .custom("\(bodyFamily)-SemiBold", size: size.rawValue, relativeTo: size.textStyle)
    }
    
    // MARK: - HUD Display (monospaced for speed/numbers)
    static func hudDisplay(size: CGFloat = 48) -> Font {
        .system(size: size, weight: .bold, design: .monospaced)
    }
    
    static func hudLabel(size: CGFloat = 14) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }
    
    // MARK: - Headline Sizes
    enum HeadlineSize: CGFloat {
        case hero = 40
        case h1 = 32
        case h2 = 28
        case h3 = 24
        case h4 = 20
        case h5 = 18
        
        var textStyle: Font.TextStyle {
            switch self {
            case .hero: return .largeTitle
            case .h1: return .title
            case .h2: return .title2
            case .h3: return .title3
            case .h4: return .headline
            case .h5: return .subheadline
            }
        }
    }
    
    // MARK: - Body Sizes
    enum BodySize: CGFloat {
        case lg = 18
        case md = 16
        case sm = 14
        case xs = 12
        case xxs = 10
        
        var textStyle: Font.TextStyle {
            switch self {
            case .lg: return .body
            case .md: return .callout
            case .sm: return .subheadline
            case .xs: return .footnote
            case .xxs: return .caption2
            }
        }
    }
}

// MARK: - View Modifier
struct ContinentalTextStyle: ViewModifier {
    let font: Font
    let color: Color
    
    func body(content: Content) -> some View {
        content
            .font(font)
            .foregroundStyle(color)
    }
}

extension View {
    func continentalHeadline(_ size: Typography.HeadlineSize = .h3, color: Color = DesignTokens.Colors.textPrimary) -> some View {
        modifier(ContinentalTextStyle(font: Typography.headline(size), color: color))
    }
    
    func continentalBody(_ size: Typography.BodySize = .md, color: Color = DesignTokens.Colors.textSecondary) -> some View {
        modifier(ContinentalTextStyle(font: Typography.body(size), color: color))
    }
}
