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
    func objectMockAlwaysReturnsBottle() async {
        let service = MockAnalyzingService(delayNanoseconds: 0)

        let result = await service.analyze(mode: .object)

        #expect(result == MockAnalysisResult(title: "Bottle", spokenMessage: "This is a bottle."))
    }

    @MainActor
    @Test
    func signMockAlwaysReturns17thAvenue() async {
        let service = MockAnalyzingService(delayNanoseconds: 0)

        let result = await service.analyze(mode: .sign)

        #expect(result == MockAnalysisResult(title: "17th Avenue", spokenMessage: "The street sign says 17th Avenue."))
    }

    @MainActor
    @Test
    func spokenMessagesStayShortAndFriendly() async {
        let service = MockAnalyzingService(delayNanoseconds: 0)

        let objectResult = await service.analyze(mode: .object)
        let signResult = await service.analyze(mode: .sign)

        #expect(objectResult.spokenMessage.count < 40)
        #expect(signResult.spokenMessage.count < 50)
        #expect(signResult.spokenMessage.contains("17th Avenue"))
    }
}
