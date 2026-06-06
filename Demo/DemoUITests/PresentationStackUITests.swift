//
//  PresentationStackUITests.swift
//  DemoUITests
//

import XCTest

final class PresentationStackUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Basics

    @MainActor
    func testHomeScreenShowsPresentationControls() throws {
        app.launchDemo()

        XCTAssertTrue(app.presentSheetButton.exists)
        XCTAssertTrue(app.presentFullScreenCoverButton.exists)
        XCTAssertTrue(app.dismissToRootButton.exists)
        XCTAssertTrue(app.dismissLast2Button.exists)
        XCTAssertTrue(app.pushButton.exists)
        XCTAssertTrue(app.customSheetButton.exists)
        XCTAssertTrue(app.nameField.exists)
        XCTAssertEqual(app.buttons.matching(identifier: "screen.presentSheet").count, 1)
    }

    // MARK: - Sheet presentation

    @MainActor
    func testPresentSheetShowsDestination() throws {
        app.launchDemo()
        app.setNameField("sheet-one")
        app.tapPresentSheet()

        XCTAssertEqual(app.buttons.matching(identifier: "screen.presentSheet").count, 2)
        app.waitForNameFieldValue("sheet-one")
    }

    @MainActor
    func testPresentStackedSheets() throws {
        app.launchDemo()
        app.setNameField("level-1")
        app.tapPresentSheet()
        app.waitForNameFieldValue("level-1")

        app.setNameField("level-2")
        app.tapPresentSheet()
        XCTAssertEqual(app.buttons.matching(identifier: "screen.presentSheet").count, 3)
        app.waitForNameFieldValue("level-2")

        app.tapDismissToRoot()
        XCTAssertEqual(app.buttons.matching(identifier: "screen.presentSheet").count, 1)
    }

    @MainActor
    func testDismissToRootClosesAllSheets() throws {
        app.launchDemo()
        app.setNameField("first")
        app.tapPresentSheet()

        app.setNameField("second")
        app.tapPresentSheet()
        XCTAssertEqual(app.buttons.matching(identifier: "screen.presentSheet").count, 3)

        app.tapDismissToRoot()
        XCTAssertEqual(app.buttons.matching(identifier: "screen.presentSheet").count, 1)
        XCTAssertTrue(app.tabBars.buttons["Home"].exists)
    }

    @MainActor
    func testDismissLastTwoPopsTwoSheets() throws {
        app.launchDemo()

        app.setNameField("first")
        app.tapPresentSheet()
        app.setNameField("second")
        app.tapPresentSheet()
        XCTAssertEqual(app.buttons.matching(identifier: "screen.presentSheet").count, 3)

        app.tapDismissLast2()
        XCTAssertEqual(app.buttons.matching(identifier: "screen.presentSheet").count, 1)
        XCTAssertTrue(app.tabBars.buttons["Home"].exists)
    }

    // MARK: - Full screen cover

    @MainActor
    func testPresentFullScreenCoverShowsDestination() throws {
        app.launchDemo()
        app.setNameField("fullscreen")
        app.tapPresentFullScreenCover()

        XCTAssertGreaterThanOrEqual(app.buttons.matching(identifier: "screen.presentSheet").count, 2)
        app.waitForNameFieldValue("fullscreen")

        app.tapDismissToRoot()
        XCTAssertEqual(app.buttons.matching(identifier: "screen.presentSheet").count, 1)
    }

    // MARK: - withPresentationStack integration

    @MainActor
    func testCustomSheetUsesPresentationStack() throws {
        app.launchDemo()
        app.tapCustomSheet()
        XCTAssertGreaterThanOrEqual(app.buttons.matching(identifier: "screen.presentSheet").count, 2)

        app.setNameField("custom")
        app.tapPresentSheet()
        XCTAssertGreaterThanOrEqual(app.buttons.matching(identifier: "screen.presentSheet").count, 3)
        app.waitForNameFieldValue("custom")

        app.tapDismissToRoot()
        XCTAssertEqual(app.buttons.matching(identifier: "screen.presentSheet").count, 1)
        XCTAssertTrue(app.tabBars.buttons["Home"].exists)
    }

    // MARK: - Navigation + presentation

    @MainActor
    func testPushThenPresentSheetFromPushedScreen() throws {
        app.launchDemo()
        app.setNameField("pushed-screen")
        app.tapPush()

        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 10))
        app.waitForNameFieldValue("pushed-screen")

        app.tapPresentSheet()
        XCTAssertEqual(app.buttons.matching(identifier: "screen.presentSheet").count, 2)
        app.waitForNameFieldValue("pushed-screen")

        app.tapDismissToRoot()
        XCTAssertEqual(app.buttons.matching(identifier: "screen.presentSheet").count, 1)
    }

    // MARK: - Tabs

    @MainActor
    func testPresentSheetFromAnotherTab() throws {
        app.launchDemo()
        app.selectTab("Favorites")
        app.setNameField("favorites-sheet")
        app.tapPresentSheet()

        XCTAssertEqual(app.buttons.matching(identifier: "screen.presentSheet").count, 2)
        app.waitForNameFieldValue("favorites-sheet")

        app.tapDismissToRoot()
        XCTAssertEqual(app.buttons.matching(identifier: "screen.presentSheet").count, 1)
    }

    // MARK: - Timer value propagation

    @MainActor
    func testTimerValueSyncsAcrossPushAndPresent() throws {
        app.launchDemo()

        // Timer writes into stringValue, which is shown in the name field.
        app.tapStartTimer()
        let initialValue = app.waitForNumericNameFieldValue()
        let updatedValue = app.waitForNameFieldValueChange(from: initialValue)
        XCTAssertNotEqual(initialValue, updatedValue, "Timer did not update the name field")

        // After push, the top screen should keep receiving the same timer value.
        app.tapPush()
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 3))
        let pushedValue = app.waitForNumericNameFieldValue()
        XCTAssertGreaterThanOrEqual(
            Int(pushedValue) ?? 0,
            Int(updatedValue) ?? 0,
            "Pushed screen did not inherit the current timer value"
        )
        let pushedUpdatedValue = app.waitForNameFieldValueChange(from: pushedValue)

        // After present, the sheet should continue syncing the timer value.
        app.tapPresentSheet()
        let presentedValue = app.waitForNumericNameFieldValue()
        XCTAssertGreaterThanOrEqual(
            Int(presentedValue) ?? 0,
            Int(pushedUpdatedValue) ?? 0,
            "Presented sheet did not inherit the current timer value"
        )
        _ = app.waitForNameFieldValueChange(from: presentedValue)

        app.setNameField("update value against timer")
        app.tapPresentSheet()
        XCTAssertEqual((app.nameField.value as? String), "update value against timer")
        
        app.tapDismissToRoot()
        XCTAssertEqual(app.buttons.matching(identifier: "screen.presentSheet").count, 1)
        
        app.selectTab("Favorites")
        XCTAssertEqual((app.nameField.value as? String), "default value")
        app.tapPush()
        XCTAssertEqual((app.nameField.value as? String), "default value")
        app.tapCustomSheet()
        XCTAssertEqual((app.nameField.value as? String), "default value")
    }
}
