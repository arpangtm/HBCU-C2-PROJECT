//
//  AccessAbilityTests.swift
//  AccessAbilityTests
//
//  Created by Rohan Ray Yadav on 4/6/26.
//

import Testing
@testable import AccessAbility

struct AccessAbilityTests {
    @MainActor
    @Test
    func scanAnalysisReturnsScriptedSequence() async {
        let service = LocalVisionAnalyzingService(delayNanoseconds: 0)

        let first = await service.analyze(mode: .scan)
        let second = await service.analyze(mode: .scan)
        let third = await service.analyze(mode: .scan)
        let fourth = await service.analyze(mode: .scan)

        #expect(first.title == "Homework Due April 10th")
        #expect(first.spokenMessage.contains("white board"))
        #expect(first.spokenMessage.contains("April 10th"))
        #expect(second.title == "Bottle")
        #expect(second.spokenMessage == "The object is bottle.")
        #expect(third.title == "Bus Stop")
        #expect(third.spokenMessage.contains("Bus Stop"))
        #expect(fourth.title == "Homework Due April 10th")
        #expect(fourth.spokenMessage == first.spokenMessage)
    }

    @MainActor
    @Test
    func adaComplianceAnalysisReturnsScriptedReports() async {
        let service = LocalVisionAnalyzingService(delayNanoseconds: 0)

        let first = await service.analyze(mode: .adaCompliance)
        let second = await service.analyze(mode: .adaCompliance)
        let third = await service.analyze(mode: .adaCompliance)

        #expect(first.title == "Obstacle Detected")
        #expect(first.spokenMessage.contains("Obstacle detected"))
        #expect(first.spokenMessage.contains("university"))
        #expect(second.title == "Inconsistent Desk Arrangement")
        #expect(second.spokenMessage.contains("classroom"))
        #expect(second.spokenMessage.contains("university"))
        #expect(third.title == "Obstacle Detected")
        #expect(third.spokenMessage == first.spokenMessage)
    }

    @MainActor
    @Test
    func spokenMessagesStayShortAndFriendly() async {
        let service = LocalVisionAnalyzingService(delayNanoseconds: 0)

        let scanResult = await service.analyze(mode: .scan)
        let reportResult = await service.analyze(mode: .adaCompliance)

        #expect(scanResult.spokenMessage.count < 100)
        #expect(reportResult.spokenMessage.count < 100)
        #expect(scanResult.spokenMessage.contains("homework"))
    }
}
