import XCTest

@MainActor final class SalvageUITests: XCTestCase {
    func testOperationControlsPausedRebuildAndRotation() throws {
        executionTimeAllowance = 180
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--excitement-qa"]
        app.launch()
        let welcome = app.buttons["Let’s build something"]
        XCTAssertTrue(welcome.waitForExistence(timeout: 20)); welcome.tap()
        let tab = app.tabBars.buttons["Battle"]
        if tab.exists { tab.tap() } else { app.descendants(matching: .any).matching(identifier: "Battle").firstMatch.tap() }
        let deploy = app.buttons["salvage-deploy"]
        XCTAssertTrue(deploy.waitForExistence(timeout: 10))
        for _ in 0..<3 where !deploy.isHittable { app.swipeUp() }
        capture("Salvage-01-briefing")
        deploy.tap()
        let rebuild = app.buttons["salvage-rebuild"]
        XCTAssertTrue(rebuild.waitForExistence(timeout: 10))
        app.buttons["salvage-target-drive"].tap()
        capture("Salvage-02-scout-and-extraction")
        rebuild.tap()
        let resume = app.buttons["salvage-resume"]
        XCTAssertTrue(resume.waitForExistence(timeout: 10))
        let emitter = app.buttons["salvage-install-weapon"]
        XCTAssertTrue(emitter.exists); XCTAssertFalse(emitter.isEnabled)
        let clock = app.staticTexts["battle-clock"].label
        Thread.sleep(forTimeInterval: 1)
        XCTAssertEqual(app.staticTexts["battle-clock"].label, clock)
        capture("Salvage-03-rebuild-costs")
        XCUIDevice.shared.orientation = .landscapeLeft
        for _ in 0..<4 where !resume.isHittable { app.swipeUp() }
        XCTAssertTrue(resume.isHittable)
        capture("Salvage-04-landscape-rebuild")
        resume.tap()
        XCTAssertTrue(rebuild.waitForExistence(timeout: 5))
        app.buttons["Pause"].tap(); app.buttons["Retreat"].tap()
        XCTAssertTrue(app.buttons["run-retry"].waitForExistence(timeout: 10))
        capture("Salvage-05-results")
        app.buttons["run-retry"].tap()
        XCTAssertTrue(rebuild.waitForExistence(timeout: 10))
        rebuild.tap()
        XCTAssertTrue(emitter.waitForExistence(timeout: 5)); XCTAssertFalse(emitter.isEnabled)
    }
    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
}
