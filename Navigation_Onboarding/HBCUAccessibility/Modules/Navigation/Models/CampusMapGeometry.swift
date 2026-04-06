//
//  CampusMapGeometry.swift
//  HBCUAccessibility
//
//  Mock map coordinates for demo routes — aligned so outdoor segments start at the
//  Cafeteria (and other starts) on the map, with plausible walking polylines.
//

import CoreLocation
import Foundation
import MapKit

enum CampusMapGeometry {
    // Approximate Fisk University campus framing (Nashville). Small offsets read as ~10–40 m.
    private static let cafeteria = CLLocationCoordinate2D(latitude: 36.16738, longitude: -86.80415)
    private static let library = CLLocationCoordinate2D(latitude: 36.16828, longitude: -86.80395)
    private static let chapel = CLLocationCoordinate2D(latitude: 36.16705, longitude: -86.80275)
    /// Park Johnson building / plaza — shared destination for PJ rooms & lobby.
    private static let parkJohnson = CLLocationCoordinate2D(latitude: 36.16792, longitude: -86.80278)
    private static let parkJohnsonNorth = CLLocationCoordinate2D(latitude: 36.16802, longitude: -86.80265)

    /// Pin for a landmark id (used for labels and fallbacks).
    static func coordinate(for landmarkId: String) -> CLLocationCoordinate2D {
        switch landmarkId {
        case "cafeteria_front": return cafeteria
        case "library_entrance": return library
        case "chapel_main": return chapel
        case "pj_308", "pj_208", "pj_lobby": return parkJohnsonNorth
        default: return cafeteria
        }
    }

    /// Multi-point path between two landmarks so the line follows walkways instead of one long jump.
    static func walkingPolyline(from startId: String, to endId: String) -> [CLLocationCoordinate2D] {
        let key = "\(startId)|\(endId)"
        switch key {
        case "cafeteria_front|pj_308", "cafeteria_front|pj_208":
            return [
                cafeteria,
                CLLocationCoordinate2D(latitude: 36.16752, longitude: -86.80388),
                CLLocationCoordinate2D(latitude: 36.16768, longitude: -86.80355),
                CLLocationCoordinate2D(latitude: 36.16782, longitude: -86.80322),
                parkJohnson,
                parkJohnsonNorth,
            ]
        case "library_entrance|pj_208":
            return [
                library,
                CLLocationCoordinate2D(latitude: 36.16818, longitude: -86.80355),
                CLLocationCoordinate2D(latitude: 36.16805, longitude: -86.80315),
                CLLocationCoordinate2D(latitude: 36.16795, longitude: -86.80295),
                parkJohnson,
                parkJohnsonNorth,
            ]
        case "chapel_main|cafeteria_front":
            return [
                chapel,
                CLLocationCoordinate2D(latitude: 36.16718, longitude: -86.80335),
                CLLocationCoordinate2D(latitude: 36.16728, longitude: -86.80372),
                cafeteria,
            ]
        default:
            return walkingPolyline(from: "cafeteria_front", to: "pj_208")
        }
    }

    /// Position along the polyline for progress 0...1 (total path length).
    static func coordinateAlongPolyline(_ polyline: [CLLocationCoordinate2D], progress: Double) -> CLLocationCoordinate2D {
        guard polyline.count >= 2 else { return polyline.first ?? cafeteria }
        let p = min(max(progress, 0), 1)
        var segmentLengths: [CLLocationDistance] = []
        var total: CLLocationDistance = 0
        for i in 0..<(polyline.count - 1) {
            let a = CLLocation(latitude: polyline[i].latitude, longitude: polyline[i].longitude)
            let b = CLLocation(latitude: polyline[i + 1].latitude, longitude: polyline[i + 1].longitude)
            let d = a.distance(from: b)
            segmentLengths.append(d)
            total += d
        }
        guard total > 0 else { return polyline[0] }
        let target = total * p
        var acc: CLLocationDistance = 0
        for i in 0..<segmentLengths.count {
            let d = segmentLengths[i]
            if acc + d >= target {
                let t = d > 0 ? (target - acc) / d : 0
                return interpolate(polyline[i], polyline[i + 1], t: t)
            }
            acc += d
        }
        return polyline.last!
    }

    private static func interpolate(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D, t: Double) -> CLLocationCoordinate2D {
        let tt = min(max(t, 0), 1)
        return CLLocationCoordinate2D(
            latitude: a.latitude + (b.latitude - a.latitude) * tt,
            longitude: a.longitude + (b.longitude - a.longitude) * tt
        )
    }

    /// Region that fits all points with padding (for initial camera).
    static func boundingRegion(for coordinates: [CLLocationCoordinate2D], paddingFactor: Double = 1.35) -> MKCoordinateRegion {
        guard !coordinates.isEmpty else {
            return MKCoordinateRegion(center: cafeteria, span: MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002))
        }
        var minLat = coordinates[0].latitude
        var maxLat = coordinates[0].latitude
        var minLon = coordinates[0].longitude
        var maxLon = coordinates[0].longitude
        for c in coordinates {
            minLat = min(minLat, c.latitude)
            maxLat = max(maxLat, c.latitude)
            minLon = min(minLon, c.longitude)
            maxLon = max(maxLon, c.longitude)
        }
        let midLat = (minLat + maxLat) / 2
        let midLon = (minLon + maxLon) / 2
        var latDelta = max(maxLat - minLat, 0.00035) * paddingFactor
        var lonDelta = max(maxLon - minLon, 0.00035) * paddingFactor
        latDelta = min(latDelta, 0.012)
        lonDelta = min(lonDelta, 0.012)
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: midLat, longitude: midLon),
            span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        )
    }
}
