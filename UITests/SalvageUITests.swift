import XCTest

@MainActor final class SalvageUITests: XCTestCase {
    override func tearDown() {
        XCUIDevice.shared.orientation = .portrait
        super.tearDown()
    }
    func testCollectRealPartsAndInstallVisibleRobotRig() throws {
        executionTimeAllowance = 240
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication(); app.launchArguments = ["--ui-testing", "--excitement-qa"]; app.launch()
        XCTAssertTrue(app.buttons["Let’s build something"].waitForExistence(timeout: 20))
        app.buttons["Let’s build something"].tap()
        let tab = app.tabBars.buttons["Battle"]
        if tab.exists { tab.tap() } else { app.descendants(matching: .any).matching(identifier: "Battle").firstMatch.tap() }
        let deploy = app.buttons["salvage-deploy"]
        XCTAssertTrue(deploy.waitForExistence(timeout: 10)); deploy.tap()
        let status = app.descendants(matching: .any).matching(identifier: "salvage-status").firstMatch
        let arena = app.descendants(matching: .any).matching(identifier: "battle-arena").firstMatch
        XCTAssertTrue(status.waitForExistence(timeout: 10))
        var recovered = false
        for _ in 0..<50 {
            let upgrade = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "upgrade-")).firstMatch
            if upgrade.exists { upgrade.tap() }
            let values = try XCTUnwrap(status.value as? String).split(separator: ",").compactMap { Double($0) }
            XCTAssertEqual(values.count, 6)
            guard values.count == 6 else { break }
            if values[4] >= 2 { recovered = true; break }
            let dx = values[2] - values[0], dy = values[3] - values[1]
            let length = hypot(dx, dy)
            if length < 0.025 { Thread.sleep(forTimeInterval: 0.6); continue }
            let start = arena.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            let end = start.withOffset(CGVector(dx: dx / length * 45, dy: -dy / length * 45))
            start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: min(0.7, length / 0.24))
        }
        XCTAssertTrue(recovered, "Recover actual enemy drops through movement before installing a rig")
        guard recovered else { capture("Salvage-recovery-failure"); return }
        app.buttons["salvage-rebuild"].tap()
        let install = app.buttons["salvage-install-weapon"]
        XCTAssertTrue(install.waitForExistence(timeout: 5))
        for _ in 0..<3 where !install.isHittable { app.swipeUp() }
        XCTAssertTrue(install.isEnabled); install.tap()
        XCTAssertFalse(install.isEnabled)
        XCTAssertTrue(app.staticTexts["Installed"].waitForExistence(timeout: 5))
        Thread.sleep(forTimeInterval: 0.5)
        capture("Salvage-06-installed-emitter")
        let resume = app.buttons["salvage-resume"]
        for _ in 0..<4 where !resume.isHittable { app.swipeUp() }
        resume.tap()
        XCTAssertTrue(status.waitForExistence(timeout: 5))
        capture("Salvage-07-visible-rig")
        app.buttons["Pause"].tap()
    }
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
        let arena = app.descendants(matching: .any).matching(identifier: "battle-arena").firstMatch
        XCTAssertGreaterThan(arena.frame.height, 100, "Landscape must retain a usable combat arena")
        XCTAssertTrue(app.buttons["overdrive-button"].isHittable)
        capture("Salvage-08-landscape-combat")
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
