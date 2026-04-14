import SwiftUI

// MARK: - Map Annotation View
/// Custom annotation rendering for different alert types on the map
struct MapAnnotationView: View {
    let annotation: MapAnnotationItem
    
    @State private var isPulsing = false
    
    var body: some View {
        ZStack {
            // Pulse ring for active alerts
            Circle()
                .fill(annotationColor.opacity(0.2))
                .frame(width: 40, height: 40)
                .scaleEffect(isPulsing ? 1.5 : 1.0)
                .opacity(isPulsing ? 0 : 0.6)
                .animation(
                    .easeOut(duration: 1.5).repeatForever(autoreverses: false),
                    value: isPulsing
                )
            
            // Background circle
            Circle()
                .fill(annotationColor.opacity(0.9))
                .frame(width: 32, height: 32)
                .shadow(color: annotationColor.opacity(0.5), radius: 6, x: 0, y: 2)
            
            // Icon
            Image(systemName: iconName)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
        }
        .onAppear {
            isPulsing = true
        }
    }
    
    private var annotationColor: Color {
        switch annotation.type {
        case .radar(let radarType):
            switch radarType {
            case .fixed: return DesignTokens.Colors.radarFixed
            case .mobile: return DesignTokens.Colors.radarMobile
            case .average: return DesignTokens.Colors.radarAverage
            case .redLight: return DesignTokens.Colors.danger
            case .section: return DesignTokens.Colors.warning
            }
        case .communityReport(let category):
            switch category.severity {
            case .low: return DesignTokens.Colors.info
            case .medium: return DesignTokens.Colors.warning
            case .high: return DesignTokens.Colors.secondaryAccent
            case .critical: return DesignTokens.Colors.danger
            }
        case .userLocation:
            return DesignTokens.Colors.primaryAccent
        case .destination:
            return DesignTokens.Colors.success
        }
    }
    
    private var iconName: String {
        switch annotation.type {
        case .radar(let radarType):
            return radarType.iconName
        case .communityReport(let category):
            return category.iconName
        case .userLocation:
            return "location.fill"
        case .destination:
            return "flag.fill"
        }
    }
}

#Preview {
    ZStack {
        Color(hex: "#101223").ignoresSafeArea()
        
        HStack(spacing: 24) {
            MapAnnotationView(annotation: MapAnnotationItem(
                id: UUID(),
                coordinate: .init(latitude: 0, longitude: 0),
                type: .radar(.fixed),
                title: "Fixed"
            ))
            
            MapAnnotationView(annotation: MapAnnotationItem(
                id: UUID(),
                coordinate: .init(latitude: 0, longitude: 0),
                type: .radar(.mobile),
                title: "Mobile"
            ))
            
            MapAnnotationView(annotation: MapAnnotationItem(
                id: UUID(),
                coordinate: .init(latitude: 0, longitude: 0),
                type: .communityReport(.police),
                title: "Police"
            ))
        }
    }
}
