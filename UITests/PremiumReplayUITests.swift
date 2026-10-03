import XCTest

@MainActor final class PremiumReplayUITests: XCTestCase {
    func testDailyCircuitResultsCardRetryAndMastery() throws {
        executionTimeAllowance = 240
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()
        XCTAssertTrue(app.buttons["Let’s build something"].waitForExistence(timeout: 20))
        app.buttons["Let’s build something"].tap()
        app.buttons["open-journal"].tap()
        XCTAssertTrue(app.staticTexts["The Hall of Scrap"].waitForExistence(timeout: 10))
        capture(app, "Premium-01-mastery")
        app.buttons["Done"].tap()
        app.tabBars.buttons["Battle"].tap()
        let daily = app.buttons["daily-play"]
        for _ in 0..<4 where !daily.isHittable { app.swipeUp() }
        XCTAssertTrue(daily.isHittable)
        capture(app, "Premium-02-daily-circuit")
        daily.tap()
        XCTAssertTrue(app.buttons["overdrive-button"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Pause"].exists)
        app.buttons["Pause"].tap()
        app.buttons["Retreat"].tap()
        XCTAssertTrue(app.buttons["run-retry"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["share-run"].exists)
        capture(app, "Premium-03-results")
        let preview = app.buttons["preview-run"]
        for _ in 0..<3 where !preview.isHittable { app.swipeUp() }
        preview.tap()
        XCTAssertTrue(app.staticTexts["SCRAP SQUAD"].waitForExistence(timeout: 10))
        capture(app, "Premium-04-share-card")
        app.buttons["Done"].tap()
        let retry = app.buttons["run-retry"]
        for _ in 0..<3 where !retry.isHittable { app.swipeUp() }
        retry.tap()
        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 10))
        app.buttons["Pause"].tap(); app.buttons["Retreat"].tap()
        let home = app.buttons["Return to city"]
        for _ in 0..<3 where !home.isHittable { app.swipeUp() }
        home.tap()
        app.tabBars.buttons["City"].tap()
        app.buttons["open-journal"].tap()
        XCTAssertTrue(app.staticTexts["2/3"].waitForExistence(timeout: 10))
        capture(app, "Premium-05-saved-records")
    }
    private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
}
