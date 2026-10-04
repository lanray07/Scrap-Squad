import XCTest

@MainActor final class PremiumReplayUITests: XCTestCase {
    override func tearDown() {
        XCUIDevice.shared.orientation = .portrait
        super.tearDown()
    }
    func testLandscapeNavigationAndCombatRotation() throws {
        executionTimeAllowance = 180
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()
        XCTAssertTrue(app.buttons["Let’s build something"].waitForExistence(timeout: 20))
        app.buttons["Let’s build something"].tap()
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(app.staticTexts["Welcome to Scrap City"].waitForExistence(timeout: 10))
        openJournal(in: app)
        XCTAssertTrue(app.staticTexts["The Hall of Scrap"].waitForExistence(timeout: 10))
        capture(app, "Layout-01-landscape-mastery")
        app.buttons["Done"].tap()
        selectTab("Battle", in: app)
        let daily = app.buttons["daily-play"]
        for _ in 0..<6 where !daily.isHittable { app.swipeUp() }
        XCTAssertTrue(daily.isHittable)
        daily.tap()
        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Pause"].isHittable)
        capture(app, "Layout-02-landscape-combat")
        pauseBattle(in: app)
        XCTAssertTrue(app.buttons["Retreat"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Retreat"].isHittable)
        capture(app, "Layout-03-landscape-pause")
        XCUIDevice.shared.orientation = .portrait
        app.buttons["Retreat"].tap()
        XCTAssertTrue(app.buttons["run-retry"].waitForExistence(timeout: 10))
        capture(app, "Layout-04-rotated-results")
    }
    func testDailyCircuitResultsCardRetryAndMastery() throws {
        executionTimeAllowance = 240
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()
        XCTAssertTrue(app.buttons["Let’s build something"].waitForExistence(timeout: 20))
        app.buttons["Let’s build something"].tap()
        openJournal(in: app)
        XCTAssertTrue(app.staticTexts["The Hall of Scrap"].waitForExistence(timeout: 10))
        capture(app, "Premium-01-mastery")
        app.buttons["Done"].tap()
        selectTab("Battle", in: app)
        let daily = app.buttons["daily-play"]
        for _ in 0..<4 where !daily.isHittable { app.swipeUp() }
        XCTAssertTrue(daily.isHittable)
        capture(app, "Premium-02-daily-circuit")
        daily.tap()
        XCTAssertTrue(app.buttons["overdrive-button"].waitForExistence(timeout: 10))
        // Earn charge through combat, handling real timed upgrade interruptions.
        for _ in 0..<35 where !app.buttons["overdrive-button"].isEnabled {
            if app.staticTexts["Choose your upgrade"].exists { chooseOfferedUpgrade(in: app) }
            else {
                let charged = XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: app.buttons["overdrive-button"])
                _ = XCTWaiter.wait(for: [charged], timeout: 2)
            }
        }
        XCTAssertTrue(app.buttons["overdrive-button"].isEnabled)
        app.buttons["overdrive-button"].tap()
        XCTAssertTrue(app.staticTexts["OVERDRIVE ACTIVE"].waitForExistence(timeout: 3))
        capture(app, "Premium-06-overdrive")
        XCTAssertTrue(app.buttons["Pause"].exists)
        pauseBattle(in: app)
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
        let clock = app.staticTexts["battle-clock"]
        let initialClock = clock.label
        let resumed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label != %@", initialClock), object: clock)
        XCTAssertEqual(XCTWaiter.wait(for: [resumed], timeout: 6), .completed)
        pauseBattle(in: app); app.buttons["Retreat"].tap()
        let home = app.buttons["Return to city"]
        for _ in 0..<3 where !home.isHittable { app.swipeUp() }
        home.tap()
        selectTab("City", in: app)
        openJournal(in: app)
        XCTAssertTrue(app.staticTexts["2/3"].waitForExistence(timeout: 10))
        capture(app, "Premium-05-saved-records")
    }
    private func pauseBattle(in app: XCUIApplication) {
        // A timed upgrade can appear between the last snapshot and a pause tap.
        // Choose a real offered upgrade, then pause; do not tap through its modal.
        for _ in 0..<3 {
            if app.staticTexts["Choose your upgrade"].exists {
                chooseOfferedUpgrade(in: app)
            }
            app.buttons["Pause"].tap()
            if app.buttons["Retreat"].waitForExistence(timeout: 3) { return }
        }
        XCTFail("Pause did not present its retreat control")
    }
    private func chooseOfferedUpgrade(in app: XCUIApplication) {
        let names = ["Tesla Coil", "Fire Core", "Cryo Core", "Drone Core", "Ricochet Chip", "Splitter Module", "Explosive Payload", "Plasma Cell", "Critical Processor", "Repair Nanites", "Overclock Module"]
        for name in names {
            let offer = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", name + ",")).firstMatch
            if offer.exists { offer.tap(); return }
        }
        XCTFail("The upgrade screen has no selectable offer")
    }
    private func openJournal(in app: XCUIApplication) {
        let journal = app.buttons["open-journal"]
        XCTAssertTrue(journal.waitForExistence(timeout: 10))
        // XCTest scrolls this element into view. Full-screen swipes can overshoot
        // the short journal row on a compact device.
        journal.tap()
    }
    private func selectTab(_ name: String, in app: XCUIApplication) {
        let compact = app.tabBars.buttons[name]
        if compact.exists { compact.tap() }
        else {
            let regular = app.descendants(matching: .any).matching(identifier: name).firstMatch
            XCTAssertTrue(regular.waitForExistence(timeout: 10))
            regular.tap()
        }
    }
    private func capture(_ app: XCUIApplication, _ name: String) {
        // Capture the display rather than the application's rotated bounding box.
        let screenshot = XCUIScreen.main.screenshot()
        if name.contains("landscape") {
            XCTAssertGreaterThan(screenshot.image.size.width, screenshot.image.size.height)
        }
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
}
