import XCTest

@MainActor final class CombatShowcaseUITests: XCTestCase {
    func testBossRushTelegraphAndPause() throws {
        executionTimeAllowance = 180
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()
        XCTAssertTrue(app.buttons["Let’s build something"].waitForExistence(timeout: 20))
        app.buttons["Let’s build something"].tap()
        let compact = app.tabBars.buttons["Battle"]
        if compact.exists { compact.tap() }
        else { app.descendants(matching: .any).matching(identifier: "Battle").firstMatch.tap() }
        app.buttons["battle-mode"].tap()
        XCTAssertTrue(app.buttons["Boss Rush"].waitForExistence(timeout: 5))
        app.buttons["Boss Rush"].tap()
        let deploy = app.buttons["Deploy squad"]
        for _ in 0..<3 where !deploy.isHittable { app.swipeUp() }
        deploy.tap()
        XCTAssertTrue(app.staticTexts.matching(identifier: "The Scrap Titan").firstMatch.waitForExistence(timeout: 12))
        let clock = app.staticTexts["battle-clock"]
        let warningTime = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == '0:05' OR label == '0:06'"), object: clock)
        XCTAssertEqual(XCTWaiter.wait(for: [warningTime], timeout: 12), .completed)
        let capture = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        capture.name = "Combat-01-boss-encounter"; capture.lifetime = .keepAlways; add(capture)
        app.buttons["Pause"].tap()
        XCTAssertTrue(app.buttons["Retreat"].waitForExistence(timeout: 5))
        app.buttons["Retreat"].tap()
        XCTAssertTrue(app.buttons["run-retry"].waitForExistence(timeout: 10))
    }
}
