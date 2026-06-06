//
//  XCUIApplication+Demo.swift
//  DemoUITests
//

import XCTest

extension XCUIApplication {
    // MARK: - Queries

    private var presentSheetButtons: XCUIElementQuery {
        buttons.matching(identifier: "screen.presentSheet")
    }

    private var nameFields: XCUIElementQuery {
        textFields.matching(identifier: "screen.nameField")
    }

    /// Prefer the topmost, hittable control when multiple screens are in the hierarchy.
    func topmostButton(_ identifier: String) -> XCUIElement {
        let query = buttons.matching(identifier: identifier)
        let elements = query.allElementsBoundByIndex
        if let hittable = elements.last(where: { $0.isHittable }) {
            return hittable
        }
        return elements.last ?? query.firstMatch
    }

    func topmostNameField() -> XCUIElement {
        let elements = nameFields.allElementsBoundByIndex
        if let hittable = elements.last(where: { $0.isHittable }) {
            return hittable
        }
        return elements.last ?? nameFields.firstMatch
    }

    var presentSheetButton: XCUIElement { topmostButton("screen.presentSheet") }
    var presentFullScreenCoverButton: XCUIElement { topmostButton("screen.presentFullScreenCover") }
    var dismissToRootButton: XCUIElement { topmostButton("screen.dismissToRoot") }
    var dismissLast2Button: XCUIElement { topmostButton("screen.dismissLast2") }
    var pushButton: XCUIElement { topmostButton("screen.push") }
    var customSheetButton: XCUIElement { topmostButton("screen.customSheet") }
    var nameField: XCUIElement { topmostNameField() }
    var startTimerButton: XCUIElement { topmostButton("screen.startTimer") }

    // MARK: - Launch

    func launchDemo() {
        launch()
        XCTAssertTrue(tabBars.firstMatch.waitForExistence(timeout: 10))
        XCTAssertTrue(tabBars.buttons["Home"].waitForExistence(timeout: 10))
        XCTAssertTrue(presentSheetButton.waitForExistence(timeout: 10))
    }

    func selectTab(_ name: String) {
        tabBars.buttons[name].tap()
        XCTAssertTrue(presentSheetButton.waitForExistence(timeout: 10))
    }

    // MARK: - Actions

    func setNameField(_ text: String, file: StaticString = #filePath, line: UInt = #line) {
        let field = nameField
        XCTAssertTrue(field.waitForExistence(timeout: 10), file: file, line: line)
        field.clearAndType(text)
    }

    func tapPresentSheet(file: StaticString = #filePath, line: UInt = #line) {
        let button = presentSheetButton
        XCTAssertTrue(button.waitForExistence(timeout: 10), file: file, line: line)
        let before = presentSheetButtons.count
        button.tap()
        waitForPresentationCount(atLeast: before + 1, file: file, line: line)
    }

    func tapPresentFullScreenCover(file: StaticString = #filePath, line: UInt = #line) {
        let button = presentFullScreenCoverButton
        XCTAssertTrue(button.waitForExistence(timeout: 10), file: file, line: line)
        let before = presentSheetButtons.count
        button.tap()
        waitForPresentationCount(atLeast: before + 1, file: file, line: line)
    }

    func tapDismissToRoot(file: StaticString = #filePath, line: UInt = #line) {
        let button = dismissToRootButton
        XCTAssertTrue(button.waitForExistence(timeout: 10), file: file, line: line)
        button.tap()
        waitForPresentationCount(1, file: file, line: line)
    }

    func tapDismissLast2(file: StaticString = #filePath, line: UInt = #line) {
        let button = dismissLast2Button
        XCTAssertTrue(button.waitForExistence(timeout: 10), file: file, line: line)
        let before = presentSheetButtons.count
        button.tap()
        let expected = max(1, before - 2)
        waitForPresentationCount(expected, file: file, line: line)
    }

    func tapPush(file: StaticString = #filePath, line: UInt = #line) {
        let button = pushButton
        XCTAssertTrue(button.waitForExistence(timeout: 10), file: file, line: line)
        button.tap()
    }

    func tapCustomSheet(file: StaticString = #filePath, line: UInt = #line) {
        let button = customSheetButton
        XCTAssertTrue(button.waitForExistence(timeout: 10), file: file, line: line)
        let before = presentSheetButtons.count
        button.tap()
        waitForPresentationCount(atLeast: before + 1, file: file, line: line)
    }

    // MARK: - Expectations

    func waitForPresentationCount(
        _ count: Int,
        timeout: TimeInterval = 10,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let predicate = NSPredicate(format: "count == %d", count)
        let expectation = XCTNSPredicateExpectation(
            predicate: predicate,
            object: presentSheetButtons
        )
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(
            result,
            .completed,
            "Expected \(count) presentation layer(s), found \(presentSheetButtons.count)",
            file: file,
            line: line
        )
    }

    func waitForPresentationCount(
        atLeast count: Int,
        timeout: TimeInterval = 10,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let predicate = NSPredicate(format: "count >= %d", count)
        let expectation = XCTNSPredicateExpectation(
            predicate: predicate,
            object: presentSheetButtons
        )
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(
            result,
            .completed,
            "Expected at least \(count) presentation layer(s), found \(presentSheetButtons.count)",
            file: file,
            line: line
        )
    }

    func waitForNameFieldValue(
        _ value: String,
        timeout: TimeInterval = 10,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let field = nameField
        XCTAssertTrue(field.waitForExistence(timeout: timeout), file: file, line: line)
        let predicate = NSPredicate(format: "value == %@", value)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: field)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(
            result,
            .completed,
            "Expected name field value '\(value)', got '\(field.value as? String ?? "")'",
            file: file,
            line: line
        )
    }

    func nameFieldValue(file: StaticString = #filePath, line: UInt = #line) -> String {
        let field = nameField
        XCTAssertTrue(field.waitForExistence(timeout: 10), file: file, line: line)
        return field.value as? String ?? ""
    }

    func waitForNameFieldValueChange(
        from initial: String,
        timeout: TimeInterval = 5,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> String {
        let field = nameField
        XCTAssertTrue(field.waitForExistence(timeout: timeout), file: file, line: line)
        let predicate = NSPredicate(format: "value != %@", initial)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: field)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(
            result,
            .completed,
            "Expected name field to change from '\(initial)', still '\(field.value as? String ?? "")'",
            file: file,
            line: line
        )
        return field.value as? String ?? ""
    }

    func waitForNumericNameFieldValue(
        timeout: TimeInterval = 5,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> String {
        let field = nameField
        XCTAssertTrue(field.waitForExistence(timeout: timeout), file: file, line: line)
        let predicate = NSPredicate { _, _ in
            guard let value = field.value as? String else { return false }
            return Int(value) != nil
        }
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: field)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(
            result,
            .completed,
            "Expected numeric timer value, got '\(field.value as? String ?? "")'",
            file: file,
            line: line
        )
        return field.value as? String ?? ""
    }

    func tapStartTimer(file: StaticString = #filePath, line: UInt = #line) {
        let button = startTimerButton
        XCTAssertTrue(button.waitForExistence(timeout: 10), file: file, line: line)
        button.tap()
    }
}

extension XCUIElement {
    func clearAndType(_ text: String) {
        tap()
        tap(withNumberOfTaps: 3, numberOfTouches: 1)
        typeText(text)
    }
}
