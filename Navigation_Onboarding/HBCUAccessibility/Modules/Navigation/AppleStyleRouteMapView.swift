//
//  AppleStyleRouteMapView.swift
//  HBCUAccessibility
//
//  MKMapView wrapper styled like Apple Maps: blue route line, green start marker,
//  red destination marker, and a user dot that travels along the polyline.
//
//  Uses MKPointAnnotation for all pins. Do not use custom NSObject + manual KVO on
//  coordinate — MapKit registers its own observers and conflicting KVO causes crashes.
//

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
        let map = MKMapView()
        map.delegate = context.coordinator
        map.isRotateEnabled = true
        map.isPitchEnabled = false
        map.showsCompass = true
        map.showsScale = true
        map.pointOfInterestFilter = .includingAll
        if #available(iOS 16.0, *) {
            map.preferredConfiguration = MKStandardMapConfiguration(emphasisStyle: .muted)
        } else {
            map.mapType = .mutedStandard
        }
        return map
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
        private var lastFitSignature: String?

        /// Reused pins — MapKit updates coordinate safely on MKPointAnnotation.
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
                if let r = routeOverlay { mapView.removeOverlay(r) }
                routeOverlay = nil
                lastFitSignature = nil
                return
            }

            let fitSig = signature(for: routeCoordinates)
            let needsRefit = lastFitSignature != fitSig
            if needsRefit {
                lastFitSignature = fitSig
                if let old = routeOverlay {
                    mapView.removeOverlay(old)
                }
                var coords = routeCoordinates
                let poly = MKPolyline(coordinates: &coords, count: coords.count)
                routeOverlay = poly
                mapView.addOverlay(poly)

                mapView.removeAnnotations(mapView.annotations)

                startAnnotation.coordinate = routeCoordinates[0]
                startAnnotation.title = "Start"
                startAnnotation.subtitle = startLabel

                endAnnotation.coordinate = routeCoordinates[routeCoordinates.count - 1]
                endAnnotation.title = "Destination"
                endAnnotation.subtitle = endLabel

                let userCoord = CampusMapGeometry.coordinateAlongPolyline(routeCoordinates, progress: userFraction)
                userAnnotation.coordinate = userCoord
                userAnnotation.title = "You"
                userAnnotation.subtitle = nil

                mapView.addAnnotations([startAnnotation, endAnnotation, userAnnotation])

                let region = CampusMapGeometry.boundingRegion(for: routeCoordinates, paddingFactor: 1.45)
                mapView.setRegion(region, animated: false)
            } else {
                let newCoord = CampusMapGeometry.coordinateAlongPolyline(routeCoordinates, progress: userFraction)
                updateUserCoordinate(mapView: mapView, to: newCoord)
            }
        }

        private func updateUserCoordinate(mapView: MKMapView, to coordinate: CLLocationCoordinate2D) {
            guard mapView.window != nil else { return }
            let old = userAnnotation.coordinate
            guard abs(old.latitude - coordinate.latitude) > 1e-9 || abs(old.longitude - coordinate.longitude) > 1e-9 else {
                return
            }
            userAnnotation.coordinate = coordinate
            mapView.setCenter(coordinate, animated: true)
        }

        private func signature(for coords: [CLLocationCoordinate2D]) -> String {
            guard let f = coords.first, let l = coords.last else { return "" }
            return "\(coords.count)|\(f.latitude),\(f.longitude)|\(l.latitude),\(l.longitude)"
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let poly = overlay as? MKPolyline {
                let r = MKPolylineRenderer(polyline: poly)
                r.strokeColor = UIColor.systemBlue
                r.lineWidth = 6
                r.lineCap = .round
                r.lineJoin = .round
                return r
            }
            return MKOverlayRenderer(overlay: overlay)
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation { return nil }

            if annotation === startAnnotation {
                let id = "startMarker"
                let v = mapView.dequeueReusableAnnotationView(withIdentifier: id) as? MKMarkerAnnotationView
                    ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: id)
                v.annotation = annotation
                v.markerTintColor = .systemGreen
                v.glyphImage = UIImage(systemName: "figure.walk")
                v.displayPriority = .required
                v.canShowCallout = true
                return v
            }
            if annotation === endAnnotation {
                let id = "destMarker"
                let v = mapView.dequeueReusableAnnotationView(withIdentifier: id) as? MKMarkerAnnotationView
                    ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: id)
                v.annotation = annotation
                v.markerTintColor = .systemRed
                v.glyphImage = UIImage(systemName: "mappin")
                v.displayPriority = .required
                v.canShowCallout = true
                return v
            }
            if annotation === userAnnotation {
                let id = "userDot"
                let v = mapView.dequeueReusableAnnotationView(withIdentifier: id) as? UserAnnotationView
                    ?? UserAnnotationView(annotation: annotation, reuseIdentifier: id)
                v.annotation = annotation
                v.canShowCallout = false
                return v
            }
            return nil
        }
    }
}

// MARK: - User dot

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
        circle.backgroundColor = UIColor.systemBlue
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
