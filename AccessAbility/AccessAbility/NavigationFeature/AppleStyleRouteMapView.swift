import MapKit
import SwiftUI
import UIKit

struct AppleStyleRouteMapView: UIViewRepresentable {
    var routeCoordinates: [CLLocationCoordinate2D]
    var userFraction: Double
    var startLabel: String
    var endLabel: String

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.isRotateEnabled = true
        mapView.isPitchEnabled = false
        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.pointOfInterestFilter = .includingAll

        if #available(iOS 16.0, *) {
            mapView.preferredConfiguration = MKStandardMapConfiguration(emphasisStyle: .muted)
        } else {
            mapView.mapType = .mutedStandard
        }

        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        context.coordinator.apply(
            mapView: mapView,
            routeCoordinates: routeCoordinates,
            userFraction: userFraction,
            startLabel: startLabel,
            endLabel: endLabel
        )
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        private var routeOverlay: MKPolyline?
        private var lastRouteSignature: String?

        private let startAnnotation = MKPointAnnotation()
        private let endAnnotation = MKPointAnnotation()
        private let userAnnotation = MKPointAnnotation()

        func apply(
            mapView: MKMapView,
            routeCoordinates: [CLLocationCoordinate2D],
            userFraction: Double,
            startLabel: String,
            endLabel: String
        ) {
            guard routeCoordinates.count >= 2 else {
                mapView.removeAnnotations(mapView.annotations)
                if let routeOverlay {
                    mapView.removeOverlay(routeOverlay)
                }
                routeOverlay = nil
                lastRouteSignature = nil
                return
            }

            let routeSignature = signature(for: routeCoordinates)
            if lastRouteSignature != routeSignature {
                rebuildRoute(
                    mapView: mapView,
                    routeCoordinates: routeCoordinates,
                    userFraction: userFraction,
                    startLabel: startLabel,
                    endLabel: endLabel
                )
                lastRouteSignature = routeSignature
            } else {
                let userCoordinate = CampusRouteGeometry.coordinateAlongPolyline(routeCoordinates, progress: userFraction)
                updateUserCoordinate(mapView: mapView, to: userCoordinate)
            }
        }

        private func rebuildRoute(
            mapView: MKMapView,
            routeCoordinates: [CLLocationCoordinate2D],
            userFraction: Double,
            startLabel: String,
            endLabel: String
        ) {
            if let routeOverlay {
                mapView.removeOverlay(routeOverlay)
            }
            mapView.removeAnnotations(mapView.annotations)

            var coordinates = routeCoordinates
            let polyline = MKPolyline(coordinates: &coordinates, count: coordinates.count)
            routeOverlay = polyline

            startAnnotation.coordinate = routeCoordinates[0]
            startAnnotation.title = "Start"
            startAnnotation.subtitle = startLabel

            endAnnotation.coordinate = routeCoordinates[routeCoordinates.count - 1]
            endAnnotation.title = "Destination"
            endAnnotation.subtitle = endLabel

            userAnnotation.coordinate = CampusRouteGeometry.coordinateAlongPolyline(routeCoordinates, progress: userFraction)
            userAnnotation.title = "You"
            userAnnotation.subtitle = nil

            mapView.addOverlay(polyline)
            mapView.addAnnotations([startAnnotation, endAnnotation, userAnnotation])
            mapView.setRegion(CampusRouteGeometry.boundingRegion(for: routeCoordinates, paddingFactor: 1.45), animated: false)
        }

        private func updateUserCoordinate(mapView: MKMapView, to coordinate: CLLocationCoordinate2D) {
            let oldCoordinate = userAnnotation.coordinate
            guard abs(oldCoordinate.latitude - coordinate.latitude) > 1e-9 ||
                abs(oldCoordinate.longitude - coordinate.longitude) > 1e-9 else {
                return
            }

            userAnnotation.coordinate = coordinate
            if mapView.window != nil {
                mapView.setCenter(coordinate, animated: true)
            }
        }

        private func signature(for coordinates: [CLLocationCoordinate2D]) -> String {
            coordinates
                .map { "\($0.latitude),\($0.longitude)" }
                .joined(separator: "|")
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let polyline = overlay as? MKPolyline else {
                return MKOverlayRenderer(overlay: overlay)
            }

            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = .systemBlue
            renderer.lineWidth = 6
            renderer.lineCap = .round
            renderer.lineJoin = .round
            return renderer
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation { return nil }

            if annotation === startAnnotation {
                let identifier = "start-marker"
                let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView ??
                    MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.annotation = annotation
                view.markerTintColor = .systemGreen
                view.glyphImage = UIImage(systemName: "figure.walk")
                view.displayPriority = .required
                view.canShowCallout = true
                return view
            }

            if annotation === endAnnotation {
                let identifier = "destination-marker"
                let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView ??
                    MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.annotation = annotation
                view.markerTintColor = .systemRed
                view.glyphImage = UIImage(systemName: "mappin")
                view.displayPriority = .required
                view.canShowCallout = true
                return view
            }

            if annotation === userAnnotation {
                let identifier = "user-dot"
                let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? UserAnnotationView ??
                    UserAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.annotation = annotation
                view.canShowCallout = false
                return view
            }

            return nil
        }
    }
}

private final class UserAnnotationView: MKAnnotationView {
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        let size: CGFloat = 22
        frame = CGRect(x: 0, y: 0, width: size + 4, height: size + 4)

        let circle = UIView(frame: CGRect(x: 2, y: 2, width: size, height: size))
        circle.backgroundColor = .systemBlue
        circle.layer.cornerRadius = size / 2
        circle.layer.borderWidth = 3
        circle.layer.borderColor = UIColor.white.cgColor
        circle.layer.shadowColor = UIColor.black.cgColor
        circle.layer.shadowOpacity = 0.25
        circle.layer.shadowRadius = 4
        circle.layer.shadowOffset = CGSize(width: 0, height: 2)
        addSubview(circle)
    }
}
