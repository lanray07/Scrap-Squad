import XCTest

@MainActor final class ExcitementUITests: XCTestCase {
    private func deploy() throws -> XCUIApplication {
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication(); app.launchArguments = ["--ui-testing", "--excitement-qa"]; app.launch()
        XCTAssertTrue(app.buttons["Let’s build something"].waitForExistence(timeout: 20))
        app.buttons["Let’s build something"].tap()
        let tab = app.tabBars.buttons["Battle"]
        if tab.exists { tab.tap() } else { app.descendants(matching: .any).matching(identifier: "Battle").firstMatch.tap() }
        let deploy = app.buttons["Deploy squad"]
        for _ in 0..<3 where !deploy.isHittable { app.swipeUp() }
        deploy.tap()
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "battle-arena").firstMatch.waitForExistence(timeout: 10))
        return app
    }
    private func capture(_ name: String) {
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot()); shot.name = name; shot.lifetime = .keepAlways; add(shot)
    }
    func testDashMovesSquadCooldownAndPauseAcrossRotation() throws {
        executionTimeAllowance = 180
        let app = try deploy()
        let arena = app.descendants(matching: .any).matching(identifier: "battle-arena").firstMatch
        func position() throws -> [Double] {
            let values = try XCTUnwrap(arena.value as? String).split(separator: ",").compactMap { Double($0) }
            return try XCTUnwrap(values.count == 3 ? values : nil)
        }
        let before = try position()
        let dash = app.buttons["battle-dash"]
        XCTAssertTrue(dash.isHittable && dash.isEnabled)
        dash.tap(); XCTAssertFalse(dash.isEnabled)
        Thread.sleep(forTimeInterval: 0.35)
        let after = try position()
        XCTAssertGreaterThan(after[1], before[1] + 0.25)
        capture("Excitement-01-dash")
        app.buttons["Pause"].tap()
        let clock = app.staticTexts["battle-clock"].label
        Thread.sleep(forTimeInterval: 0.8)
        XCTAssertEqual(app.staticTexts["battle-clock"].label, clock)
        XCUIDevice.shared.orientation = .landscapeLeft
        app.buttons["Resume"].tap()
        XCTAssertTrue(dash.waitForExistence(timeout: 5) && dash.isHittable)
        capture("Excitement-02-landscape-controls")
        app.buttons["Pause"].tap()
    }
    func testRealUpgradeRecipeWaveEventEvolutionAndCleanRetry() throws {
        executionTimeAllowance = 240
        let app = try deploy()
        let first = app.buttons["upgrade-fire"]
        XCTAssertTrue(first.waitForExistence(timeout: 35)); first.tap()
        app.buttons["battle-ability"].tap()
        let event = app.descendants(matching: .any).matching(identifier: "wave-event").firstMatch
        // Simulator rendering can advance simulation slower than wall time under runner load.
        XCTAssertTrue(event.waitForExistence(timeout: 60))
        capture("Excitement-03-elite-wave-event")
        let second = app.buttons["upgrade-overclock"]
        XCTAssertTrue(second.waitForExistence(timeout: 35)); second.tap()
        let evolution = app.descendants(matching: .any).matching(identifier: "weapon-evolution").firstMatch
        XCTAssertTrue(evolution.waitForExistence(timeout: 5))
        Thread.sleep(forTimeInterval: 1)
        capture("Excitement-04-fire-vortex")
        app.buttons["Pause"].tap(); app.buttons["Retreat"].tap()
        XCTAssertTrue(app.buttons["run-retry"].waitForExistence(timeout: 10))
        app.buttons["run-retry"].tap()
        XCTAssertTrue(app.buttons["battle-dash"].waitForExistence(timeout: 10))
        XCTAssertFalse(evolution.exists)
        app.buttons["Pause"].tap()
    }
    private func verifyEvolution(first: String, second: String, name: String) throws {
        let app = try deploy()
        let primer = app.buttons["upgrade-" + first]
        XCTAssertTrue(primer.waitForExistence(timeout: 35)); primer.tap()
        app.buttons["battle-ability"].tap()
        let partner = app.buttons["upgrade-" + second]
        XCTAssertTrue(partner.waitForExistence(timeout: 35)); partner.tap()
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "weapon-evolution").firstMatch.waitForExistence(timeout: 5))
        Thread.sleep(forTimeInterval: 1)
        capture(name)
        app.buttons["Pause"].tap()
    }
    func testStormCageRecipeAndArenaPresentation() throws {
        executionTimeAllowance = 180
        try verifyEvolution(first: "tesla", second: "drone", name: "Excitement-05-storm-cage")
    }
    func testSiegeBarrageRecipeAndArenaPresentation() throws {
        executionTimeAllowance = 180
        try verifyEvolution(first: "payload", second: "critical", name: "Excitement-06-siege-barrage")
    }
}
