import Foundation

struct IndoorRoute {
    let startId: String
    let endId: String
    let startName: String
    let endName: String
    let steps: [RouteStep]

    struct RouteStep: Identifiable {
        let id = UUID()
        let instruction: String
        let detail: String?
        let approxSteps: Int?
        let isStairsStart: Bool
        let isStairsEnd: Bool
        let sceneImageName: String?

        init(
            instruction: String,
            detail: String? = nil,
            approxSteps: Int? = nil,
            isStairsStart: Bool = false,
            isStairsEnd: Bool = false,
            sceneImageName: String? = nil
        ) {
            self.instruction = instruction
            self.detail = detail
            self.approxSteps = approxSteps
            self.isStairsStart = isStairsStart
            self.isStairsEnd = isStairsEnd
            self.sceneImageName = sceneImageName
        }

        var usesIndoorScene: Bool {
            Self.isIndoorInstruction(instruction)
        }

        static func isIndoorInstruction(_ instruction: String) -> Bool {
            let lower = instruction.lowercased()
            return lower.contains("enter park johnson") ||
                lower.contains("inside the lobby") ||
                lower.contains("second floor") ||
                lower.contains("third floor") ||
                lower.contains("hallway") ||
                lower.contains("room 208") ||
                lower.contains("room 308")
        }
    }

    private static let routes: [String: IndoorRoute] = {
        let cafeteriaTo308 = IndoorRoute(
            startId: "cafeteria_front",
            endId: "pj_308",
            startName: "Cafeteria front door",
            endName: "Park Johnson Room 308",
            steps: [
                RouteStep(instruction: "Leave the cafeteria through the front door.", detail: "Turn left once you're outside."),
                RouteStep(instruction: "Walk straight toward Park Johnson building.", detail: "The building is ahead, about 100 feet."),
                RouteStep(instruction: "Enter Park Johnson through the main entrance.", detail: "The doors are straight ahead.", sceneImageName: "indoor_entrance"),
                RouteStep(instruction: "Inside the lobby, the stairs are ahead and to your right.", detail: "Take the stairs up to the second floor.", isStairsStart: true, sceneImageName: "indoor_lobby"),
                RouteStep(instruction: "On the second floor, turn right at the landing.", detail: "Take the stairs up to the third floor.", isStairsEnd: true, sceneImageName: "indoor_stairs"),
                RouteStep(instruction: "At the top of the stairs on the third floor, turn left.", detail: "Walk straight down the hallway.", sceneImageName: "indoor_hallway"),
                RouteStep(instruction: "Room 308 is on your right, about halfway down the hallway.", detail: "It is the third door on your right. You have arrived.")
            ]
        )

        let libraryTo208 = IndoorRoute(
            startId: "library_entrance",
            endId: "pj_208",
            startName: "Library entrance",
            endName: "Park Johnson Room 208",
            steps: [
                RouteStep(instruction: "From the library entrance, turn right and walk toward the quad.", detail: "Park Johnson is on your left."),
                RouteStep(instruction: "Walk to Park Johnson building and enter the main entrance.", detail: "The lobby is straight ahead.", sceneImageName: "indoor_lobby"),
                RouteStep(instruction: "The stairs are to your right. Take the stairs to the second floor.", isStairsStart: true, sceneImageName: "indoor_stairs"),
                RouteStep(instruction: "On the second floor, turn left at the landing.", detail: "Walk down the hallway.", isStairsEnd: true, sceneImageName: "indoor_hallway"),
                RouteStep(instruction: "Room 208 is on your left, about three doors down.", detail: "You have arrived.", sceneImageName: "indoor_door_208")
            ]
        )

        let chapelToCafeteria = IndoorRoute(
            startId: "chapel_main",
            endId: "cafeteria_front",
            startName: "Fisk Memorial Chapel",
            endName: "Cafeteria front door",
            steps: [
                RouteStep(instruction: "Exit the chapel through the main doors.", detail: "Turn right outside."),
                RouteStep(instruction: "Walk straight along the path toward the cafeteria.", detail: "About 150 feet ahead."),
                RouteStep(instruction: "The cafeteria entrance is on your left.", detail: "You have arrived at the front door.")
            ]
        )

        let cafeteriaTo208 = IndoorRoute(
            startId: "cafeteria_front",
            endId: "pj_208",
            startName: "Cafeteria front door",
            endName: "Park Johnson Room 208",
            steps: [
                RouteStep(instruction: "Walk straight ahead out the door of the cafeteria.", detail: "You're heading toward the path.", approxSteps: 10),
                RouteStep(instruction: "In a few small steps, you'll reach a curb going down.", detail: "Slow down as you approach.", approxSteps: 5, isStairsStart: true),
                RouteStep(instruction: "Step down once off the curb, then turn left and continue walking.", detail: "Park Johnson is ahead along this path.", approxSteps: 15, isStairsEnd: true),
                RouteStep(instruction: "The main entrance is in front of you. Head for the door.", detail: "About a short hallway length ahead.", approxSteps: 10, sceneImageName: "indoor_entrance"),
                RouteStep(instruction: "Enter Park Johnson. Inside the lobby, the stairs are to your right.", detail: "Walk to the stairs and begin going up to the second floor.", approxSteps: 12, isStairsStart: true, sceneImageName: "indoor_lobby"),
                RouteStep(instruction: "On the second floor, step off the stairs and turn left at the landing.", detail: "You're now on level ground in the hallway.", approxSteps: 6, isStairsEnd: true, sceneImageName: "indoor_hallway"),
                RouteStep(instruction: "Walk down the hallway. Room 208 is on your left, about three doors down.", detail: "You'll feel the door frame on your left. You have arrived.", approxSteps: 8, sceneImageName: "indoor_door_208")
            ]
        )

        return [
            key(cafeteriaTo308.startId, cafeteriaTo308.endId): cafeteriaTo308,
            key(libraryTo208.startId, libraryTo208.endId): libraryTo208,
            key(chapelToCafeteria.startId, chapelToCafeteria.endId): chapelToCafeteria,
            key(cafeteriaTo208.startId, cafeteriaTo208.endId): cafeteriaTo208
        ]
    }()

    static var defaultRoute: IndoorRoute {
        routes[key("cafeteria_front", "pj_208")]!
    }

    static func find(from start: Landmark, to end: Landmark) -> IndoorRoute? {
        routes[key(start.id, end.id)]
    }

    private static func key(_ startId: String, _ endId: String) -> String {
        "\(startId)|\(endId)"
    }
}
