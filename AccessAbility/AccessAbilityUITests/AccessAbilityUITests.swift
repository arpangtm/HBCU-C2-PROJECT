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
        app.launchArguments += ["-ui-testing", "-use-camera-preview-fallback", "-skip-onboarding"]
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func testHomeScreenShowsGestureControlAndRoutes() throws {
        app.launch()

        XCTAssertTrue(app.otherElements["home.gesturePad"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.otherElements["home.route.navigation"].exists)
        XCTAssertTrue(app.otherElements["home.route.scanSurroundings"].exists)
        XCTAssertTrue(app.otherElements["home.route.adaReport"].exists)
        XCTAssertTrue(app.otherElements["home.route.requestHelp"].exists)
        XCTAssertFalse(app.navigationBars["AccessAbility"].exists)
    }

    @MainActor
    func testHomeGesturesNavigateToScreens() throws {
        app.launch()

        openHomeRoute(.up)
        XCTAssertTrue(app.otherElements["navigation.screen"].waitForExistence(timeout: 2))
        app.navigationBars.buttons.element(boundBy: 0).tap()

        openHomeRoute(.right)
        XCTAssertTrue(app.otherElements["adaReport.screen"].waitForExistence(timeout: 2))
        app.navigationBars.buttons.element(boundBy: 0).tap()

        openHomeRoute(.left)
        XCTAssertTrue(app.otherElements["scanSurroundings.screen"].waitForExistence(timeout: 2))
        app.navigationBars.buttons.element(boundBy: 0).tap()

        openHomeRoute(.down)
        XCTAssertTrue(app.otherElements["requestHelp.screen"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testOnboardingCanReachHomeScreen() throws {
        let onboardingApp = XCUIApplication()
        onboardingApp.launchArguments += ["-ui-testing", "-use-camera-preview-fallback"]
        onboardingApp.launch()

        XCTAssertTrue(onboardingApp.otherElements["onboarding.screen"].waitForExistence(timeout: 2))
        onboardingApp.buttons["onboarding.next"].tap()

        let nameField = onboardingApp.textFields["onboarding.name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 2))
        nameField.tap()
        nameField.typeText("Ada")
        onboardingApp.buttons["onboarding.next"].tap()

        let studentIdField = onboardingApp.textFields["onboarding.studentId"]
        XCTAssertTrue(studentIdField.waitForExistence(timeout: 2))
        studentIdField.tap()
        studentIdField.typeText("12345")
        onboardingApp.buttons["onboarding.next"].tap()

        onboardingApp.buttons["onboarding.next"].tap()
        onboardingApp.buttons["onboarding.next"].tap()

        XCTAssertTrue(onboardingApp.otherElements["home.gesturePad"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testCameraScreensShowCaptureAndRetakeFlow() throws {
        app.launch()

        openHomeRoute(.left)
        XCTAssertTrue(app.otherElements["scanSurroundings.screen"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["camera.capture"].waitForExistence(timeout: 2))
        app.buttons["camera.capture"].tap()
        XCTAssertTrue(app.otherElements["camera.result.card"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["camera.retake"].exists)
        app.navigationBars.buttons.element(boundBy: 0).tap()
    }

    @MainActor
    func testADAReportCaptureSubmitsReport() throws {
        app.launch()

        openHomeRoute(.right)
        XCTAssertTrue(app.otherElements["adaReport.screen"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["camera.capture"].waitForExistence(timeout: 2))
        app.buttons["camera.capture"].tap()
        XCTAssertTrue(app.otherElements["camera.result.card"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.otherElements["adaReport.card"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.otherElements["camera.result.card"].label.contains("Obstacle Detected"))
        XCTAssertTrue(app.buttons["camera.retake"].waitForExistence(timeout: 2))
        app.buttons["camera.retake"].tap()
        app.buttons["camera.capture"].tap()
        XCTAssertTrue(app.otherElements["camera.result.card"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.otherElements["camera.result.card"].label.contains("Inconsistent Desk Arrangement"))
    }

    @MainActor
    func testRequestHelpSwipesReachAudioDetails() throws {
        app.launch()

        openHomeRoute(.down)
        XCTAssertTrue(app.otherElements["requestHelp.screen"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["What kind of Assistance"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Dining"].exists)
        XCTAssertTrue(app.staticTexts["Reading"].exists)
        XCTAssertTrue(app.staticTexts["Escort"].exists)
        XCTAssertTrue(app.staticTexts["Other"].exists)
        openSwipePad("requestHelp.categoryPad", .up)
        XCTAssertTrue(app.otherElements["requestHelp.urgencyPad"].waitForExistence(timeout: 2))
        openSwipePad("requestHelp.urgencyPad", .down)
        XCTAssertTrue(app.otherElements["requestHelp.audioDetails"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    private enum HomeSwipeDirection {
        case up
        case right
        case left
        case down
    }

    private func openHomeRoute(_ direction: HomeSwipeDirection) {
        openSwipePad("home.gesturePad", direction)
    }

    private func openSwipePad(_ identifier: String, _ direction: HomeSwipeDirection) {
        let targetPad = app.otherElements[identifier]
        XCTAssertTrue(targetPad.waitForExistence(timeout: 2))

        let start = targetPad.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let endOffset: CGVector
        switch direction {
        case .up:
            endOffset = CGVector(dx: 0.5, dy: -0.25)
        case .right:
            endOffset = CGVector(dx: 1.25, dy: 0.5)
        case .left:
            endOffset = CGVector(dx: -0.25, dy: 0.5)
        case .down:
            endOffset = CGVector(dx: 0.5, dy: 1.25)
        }

        start.press(forDuration: 0.25, thenDragTo: targetPad.coordinate(withNormalizedOffset: endOffset))
    }
}
