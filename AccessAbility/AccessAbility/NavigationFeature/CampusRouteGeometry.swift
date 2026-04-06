import CoreLocation

enum CampusRouteGeometry {
    private static let cafeteriaFront = CLLocationCoordinate2D(latitude: 36.16760, longitude: -86.77920)
    private static let cafeteriaPathCorner = CLLocationCoordinate2D(latitude: 36.16764, longitude: -86.77898)
    private static let parkJohnsonWalkway = CLLocationCoordinate2D(latitude: 36.16776, longitude: -86.77878)
    private static let parkJohnsonEntrance = CLLocationCoordinate2D(latitude: 36.16788, longitude: -86.77855)

    private static let libraryEntrance = CLLocationCoordinate2D(latitude: 36.16736, longitude: -86.77906)
    private static let libraryQuadCorner = CLLocationCoordinate2D(latitude: 36.16752, longitude: -86.77886)

    private static let chapelMain = CLLocationCoordinate2D(latitude: 36.16708, longitude: -86.78002)
    private static let chapelWalkway = CLLocationCoordinate2D(latitude: 36.16722, longitude: -86.77978)
    private static let cafeteriaApproach = CLLocationCoordinate2D(latitude: 36.16745, longitude: -86.77946)

    static func coordinates(for route: IndoorRoute) -> [CLLocationCoordinate2D] {
        switch (route.startId, route.endId) {
        case ("cafeteria_front", "pj_208"), ("cafeteria_front", "pj_308"):
            return [
                cafeteriaFront,
                cafeteriaPathCorner,
                parkJohnsonWalkway,
                parkJohnsonEntrance
            ]
        case ("library_entrance", "pj_208"):
            return [
                libraryEntrance,
                libraryQuadCorner,
                parkJohnsonWalkway,
                parkJohnsonEntrance
            ]
        case ("chapel_main", "cafeteria_front"):
            return [
                chapelMain,
                chapelWalkway,
                cafeteriaApproach,
                cafeteriaFront
            ]
        default:
            return [
                cafeteriaFront,
                cafeteriaPathCorner,
                parkJohnsonWalkway,
                parkJohnsonEntrance
            ]
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
}
