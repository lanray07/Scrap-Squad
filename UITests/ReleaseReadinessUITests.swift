import XCTest

@MainActor final class ReleaseReadinessUITests: XCTestCase {
    func testBackgroundingPausesCombatUntilExplicitResume() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()
        XCTAssertTrue(app.buttons["Let’s build something"].waitForExistence(timeout: 20))
        app.buttons["Let’s build something"].tap()
        tab("Battle", app)
        app.buttons["Deploy squad"].tap()
        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 10))
        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertTrue(app.buttons["Resume"].waitForExistence(timeout: 10))
        let clock = app.staticTexts["battle-clock"]
        let paused = clock.label
        let changed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label != %@", paused), object: clock)
        XCTAssertEqual(XCTWaiter.wait(for: [changed], timeout: 3), .timedOut)
        capture("QA-background-paused")
        app.buttons["Resume"].tap()
        let resumed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label != %@", paused), object: clock)
        XCTAssertEqual(XCTWaiter.wait(for: [resumed], timeout: 5), .completed)
        app.buttons["Pause"].tap()
        app.buttons["Retreat"].tap()
        XCTAssertTrue(app.buttons["run-retry"].waitForExistence(timeout: 10))
    }

    func testLargestDynamicTypeSettingsAndJournalRemainReachable() throws {
        executionTimeAllowance = 180
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        XCTAssertTrue(app.buttons["Let’s build something"].waitForExistence(timeout: 20))
        app.buttons["Let’s build something"].tap()
        let settings = app.buttons["Settings"]
        XCTAssertTrue(settings.waitForExistence(timeout: 10))
        settings.tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 10))
        let motion = app.switches["Reduced motion"]
        XCTAssertTrue(motion.waitForExistence(timeout: 10))
        XCTAssertTrue(motion.isHittable)
        motion.tap()
        capture("QA-largest-text-settings")
        app.buttons["Done"].tap()
        let journal = app.buttons["open-journal"]
        XCTAssertTrue(journal.waitForExistence(timeout: 10))
        journal.tap()
        XCTAssertTrue(app.staticTexts["The Hall of Scrap"].waitForExistence(timeout: 10))
        capture("QA-largest-text-journal")
        XCTAssertTrue(app.buttons["Done"].isHittable)
        app.buttons["Done"].tap()
    }

    func testOnboardingAndSettingsAccessibilityAudit() throws {
        executionTimeAllowance = 180
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()
        XCTAssertTrue(app.buttons["Let’s build something"].waitForExistence(timeout: 20))
        try app.performAccessibilityAudit(for: [.sufficientElementDescription, .hitRegion, .textClipped, .contrast])
        app.buttons["Let’s build something"].tap()
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 10))
        try app.performAccessibilityAudit(for: [.sufficientElementDescription, .hitRegion, .textClipped, .contrast])
        capture("QA-accessibility-settings")
    }

    private func tab(_ name: String, _ app: XCUIApplication) {
        if app.tabBars.buttons[name].exists { app.tabBars.buttons[name].tap() }
        else { app.descendants(matching: .any).matching(identifier: name).firstMatch.tap() }
    }
    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
}
