import SwiftUI
import MapKit

// MARK: - Map Container View
/// Wraps MapKit Map with custom styling and overlays
struct MapContainerView: View {
    @Binding var cameraPosition: MapCameraPosition
    let annotations: [MapAnnotationItem]
    let showTraffic: Bool
    var onMapTap: ((CLLocationCoordinate2D) -> Void)?
    
    var body: some View {
        Map(position: $cameraPosition) {
            UserAnnotation()
            
            ForEach(annotations) { annotation in
                Annotation(annotation.title, coordinate: annotation.coordinate) {
                    MapAnnotationView(annotation: annotation)
                }
            }
        }
        .mapStyle(.standard(
            elevation: .realistic,
            emphasis: .muted,
            pointsOfInterest: .excludingAll,
            showsTraffic: showTraffic
        ))
        .mapControls {
            MapCompass()
            MapScaleView()
        }
    }
}
