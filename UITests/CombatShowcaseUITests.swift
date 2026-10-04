import XCTest

@MainActor final class CombatShowcaseUITests: XCTestCase {
    func testSquadWalksAndLeavesFootprintsOnlyWhileMoving() throws {
        executionTimeAllowance = 180
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication(); app.launchArguments = ["--ui-testing"]; app.launch()
        XCTAssertTrue(app.buttons["Let’s build something"].waitForExistence(timeout: 20))
        app.buttons["Let’s build something"].tap()
        let compact = app.tabBars.buttons["Battle"]
        if compact.exists { compact.tap() }
        else { app.descendants(matching: .any).matching(identifier: "Battle").firstMatch.tap() }
        let deploy = app.buttons["Deploy squad"]
        for _ in 0..<3 where !deploy.isHittable { app.swipeUp() }
        deploy.tap()
        let arena = app.descendants(matching: .any).matching(identifier: "battle-arena").firstMatch
        XCTAssertTrue(arena.waitForExistence(timeout: 10))
        func state() throws -> [Double] {
            let values = try XCTUnwrap(arena.value as? String).split(separator: ",").compactMap { Double($0) }
            return try XCTUnwrap(values.count == 3 ? values : nil, "Arena must expose position and step count in UI testing")
        }
        let before = try state()
        XCTAssertEqual(before[2], 0)
        let start = arena.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.6))
        let end = arena.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.6))
        start.press(forDuration: 0.1, thenDragTo: end)
        Thread.sleep(forTimeInterval: 0.3)
        let after = try state()
        XCTAssertGreaterThan(after[0], before[0] + 0.005)
        XCTAssertGreaterThan(after[2], 0)
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "Movement-01-ground-footprints"; shot.lifetime = .keepAlways; add(shot)
        Thread.sleep(forTimeInterval: 0.8)
        let stopped = try state()
        XCTAssertEqual(stopped[0], after[0], accuracy: 0.0001)
        XCTAssertEqual(stopped[2], after[2])
        app.buttons["Pause"].tap()
        XCTAssertTrue(app.buttons["Resume"].waitForExistence(timeout: 5))
    }
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
