import CoreLocation
import MapKit

enum CampusRouteGeometry {
    private static let cafeteriaFront = CLLocationCoordinate2D(latitude: 36.16738, longitude: -86.80415)
    private static let libraryEntrance = CLLocationCoordinate2D(latitude: 36.16828, longitude: -86.80395)
    private static let chapelMain = CLLocationCoordinate2D(latitude: 36.16705, longitude: -86.80275)
    private static let parkJohnsonPlaza = CLLocationCoordinate2D(latitude: 36.16792, longitude: -86.80278)
    private static let parkJohnsonEntrance = CLLocationCoordinate2D(latitude: 36.16802, longitude: -86.80265)

    static func coordinate(for landmarkId: String) -> CLLocationCoordinate2D {
        switch landmarkId {
        case "cafeteria_front":
            cafeteriaFront
        case "library_entrance":
            libraryEntrance
        case "chapel_main":
            chapelMain
        case "pj_308", "pj_208", "pj_lobby":
            parkJohnsonEntrance
        default:
            cafeteriaFront
        }
    }

    static func coordinates(for route: IndoorRoute) -> [CLLocationCoordinate2D] {
        walkingPolyline(from: route.startId, to: route.endId)
    }

    static func walkingPolyline(from startId: String, to endId: String) -> [CLLocationCoordinate2D] {
        switch (startId, endId) {
        case ("cafeteria_front", "pj_208"), ("cafeteria_front", "pj_308"):
            return [
                cafeteriaFront,
                CLLocationCoordinate2D(latitude: 36.16752, longitude: -86.80388),
                CLLocationCoordinate2D(latitude: 36.16768, longitude: -86.80355),
                CLLocationCoordinate2D(latitude: 36.16782, longitude: -86.80322),
                parkJohnsonPlaza,
                parkJohnsonEntrance
            ]
        case ("library_entrance", "pj_208"):
            return [
                libraryEntrance,
                CLLocationCoordinate2D(latitude: 36.16818, longitude: -86.80355),
                CLLocationCoordinate2D(latitude: 36.16805, longitude: -86.80315),
                CLLocationCoordinate2D(latitude: 36.16795, longitude: -86.80295),
                parkJohnsonPlaza,
                parkJohnsonEntrance
            ]
        case ("chapel_main", "cafeteria_front"):
            return [
                chapelMain,
                CLLocationCoordinate2D(latitude: 36.16718, longitude: -86.80335),
                CLLocationCoordinate2D(latitude: 36.16728, longitude: -86.80372),
                cafeteriaFront
            ]
        default:
            return walkingPolyline(from: "cafeteria_front", to: "pj_208")
        }
    }

    static func coordinateAlongPolyline(_ coordinates: [CLLocationCoordinate2D], progress: Double) -> CLLocationCoordinate2D {
        guard let first = coordinates.first else { return cafeteriaFront }
        guard coordinates.count > 1 else { return first }

        let clampedProgress = min(max(progress, 0), 1)
        let segmentDistances = zip(coordinates, coordinates.dropFirst()).map { distance(from: $0.0, to: $0.1) }
        let totalDistance = segmentDistances.reduce(0, +)
        guard totalDistance > 0 else { return first }

        let targetDistance = totalDistance * clampedProgress
        var traversedDistance: CLLocationDistance = 0

        for index in segmentDistances.indices {
            let segmentDistance = segmentDistances[index]
            let segmentEnd = traversedDistance + segmentDistance

            if targetDistance <= segmentEnd || index == segmentDistances.count - 1 {
                let ratio = segmentDistance > 0 ? (targetDistance - traversedDistance) / segmentDistance : 0
                return interpolate(from: coordinates[index], to: coordinates[index + 1], ratio: ratio)
            }

            traversedDistance = segmentEnd
        }

        return coordinates.last ?? first
    }

    private static func distance(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) -> CLLocationDistance {
        CLLocation(latitude: start.latitude, longitude: start.longitude)
            .distance(from: CLLocation(latitude: end.latitude, longitude: end.longitude))
    }

    private static func interpolate(
        from start: CLLocationCoordinate2D,
        to end: CLLocationCoordinate2D,
        ratio: CLLocationDistance
    ) -> CLLocationCoordinate2D {
        let clampedRatio = min(max(ratio, 0), 1)
        return CLLocationCoordinate2D(
            latitude: start.latitude + (end.latitude - start.latitude) * clampedRatio,
            longitude: start.longitude + (end.longitude - start.longitude) * clampedRatio
        )
    }

    static func boundingRegion(
        for coordinates: [CLLocationCoordinate2D],
        paddingFactor: Double = 1.35
    ) -> MKCoordinateRegion {
        guard let first = coordinates.first else {
            return MKCoordinateRegion(
                center: cafeteriaFront,
                span: MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002)
            )
        }

        var minLatitude = first.latitude
        var maxLatitude = first.latitude
        var minLongitude = first.longitude
        var maxLongitude = first.longitude

        for coordinate in coordinates {
            minLatitude = min(minLatitude, coordinate.latitude)
            maxLatitude = max(maxLatitude, coordinate.latitude)
            minLongitude = min(minLongitude, coordinate.longitude)
            maxLongitude = max(maxLongitude, coordinate.longitude)
        }

        let center = CLLocationCoordinate2D(
            latitude: (minLatitude + maxLatitude) / 2,
            longitude: (minLongitude + maxLongitude) / 2
        )
        let latitudeDelta = min(max(maxLatitude - minLatitude, 0.00035) * paddingFactor, 0.012)
        let longitudeDelta = min(max(maxLongitude - minLongitude, 0.00035) * paddingFactor, 0.012)

        return MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        )
    }
}
