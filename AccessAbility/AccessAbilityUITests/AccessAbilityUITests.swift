//
//  AccessAbilityUITests.swift
//  AccessAbilityUITests
//
//  Created by Rohan Ray Yadav on 4/6/26.
//

import XCTest

final class AccessAbilityUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-ui-testing", "-use-mock-camera-preview"]
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func testHomeScreenShowsFourSupportTiles() throws {
        app.launch()

        XCTAssertTrue(app.buttons["home.tile.navigation"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["home.tile.readSigns"].exists)
        XCTAssertTrue(app.buttons["home.tile.identifyObject"].exists)
        XCTAssertTrue(app.buttons["home.tile.requestHelp"].exists)
    }

    @MainActor
    func testPlaceholderTilesNavigateToPlaceholderScreens() throws {
        app.launch()

        app.buttons["home.tile.navigation"].tap()
        XCTAssertTrue(app.otherElements["navigation.screen"].waitForExistence(timeout: 2))
        app.navigationBars.buttons.element(boundBy: 0).tap()

        app.buttons["home.tile.requestHelp"].tap()
        XCTAssertTrue(app.otherElements["requestHelp.screen"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testCameraScreensShowCaptureAndRetakeFlow() throws {
        app.launch()

        app.buttons["home.tile.identifyObject"].tap()
        XCTAssertTrue(app.otherElements["identifyObject.screen"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["camera.capture"].waitForExistence(timeout: 2))
        app.buttons["camera.capture"].tap()
        XCTAssertTrue(app.otherElements["camera.result.card"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["camera.retake"].exists)
        app.navigationBars.buttons.element(boundBy: 0).tap()

        app.buttons["home.tile.readSigns"].tap()
        XCTAssertTrue(app.otherElements["readSigns.screen"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["camera.capture"].waitForExistence(timeout: 2))
        app.buttons["camera.capture"].tap()
        XCTAssertTrue(app.otherElements["camera.result.card"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["camera.retake"].exists)
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
