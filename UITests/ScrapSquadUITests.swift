import XCTest

@MainActor final class ScrapSquadUITests: XCTestCase {
    func testStoreScreenshotTour() throws {
        executionTimeAllowance = 240
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()
        let start = app.buttons["Let’s build something"]
        XCTAssertTrue(start.waitForExistence(timeout: 20))
        capture(app, "Store-01-onboarding")
        start.tap()
        XCTAssertTrue(app.staticTexts["Welcome to Scrap City"].waitForExistence(timeout: 10))
        capture(app, "Store-02-city")
        selectTab("Squad", in: app)
        XCTAssertTrue(app.staticTexts.matching(identifier: "BOLT").firstMatch.waitForExistence(timeout: 10))
        capture(app, "Store-03-squad")
        selectTab("Blueprints", in: app)
        XCTAssertTrue(app.staticTexts["0 / 12"].waitForExistence(timeout: 10))
        capture(app, "Store-04-blueprints")
        selectTab("City", in: app)
        app.buttons["Open Workshop"].tap()
        XCTAssertTrue(app.staticTexts["Invent something outrageous"].waitForExistence(timeout: 10))
        capture(app, "Store-05-workshop")
        app.segmentedControls.buttons.element(boundBy: 1).tap()
        capture(app, "Store-06-roulette")
        app.segmentedControls.buttons.element(boundBy: 0).tap()
        app.buttons.matching(identifier: "Fuse weapon").firstMatch.tap()
        XCTAssertTrue(app.staticTexts["New weapon discovered"].waitForExistence(timeout: 10))
        capture(app, "Store-07-fusion")
        app.buttons["fusion-equip"].tap()
        app.buttons["workshop-done"].tap()
        selectTab("Battle", in: app)
        XCTAssertTrue(app.buttons["Deploy squad"].waitForExistence(timeout: 10))
        capture(app, "Store-08-lobby")
        app.buttons["Deploy squad"].tap()
        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 10))
        capture(app, "Store-09-battle")
        app.buttons["Pause"].tap()
        XCTAssertTrue(app.staticTexts["Mission paused"].waitForExistence(timeout: 10))
        capture(app, "Store-10-pause")
    }

    func testOnboardingCityAndFusion() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()
        let start = app.buttons["Let’s build something"]
        XCTAssertTrue(start.waitForExistence(timeout: 20))
        start.tap()
        XCTAssertTrue(app.staticTexts["Welcome to Scrap City"].waitForExistence(timeout: 10))
        capture(app, "Scrap City")
        app.buttons["Open Workshop"].tap()
        XCTAssertTrue(app.staticTexts["Invent something outrageous"].waitForExistence(timeout: 10))
        let fuse = app.buttons.matching(identifier: "Fuse weapon").firstMatch
        XCTAssertTrue(fuse.waitForExistence(timeout: 10))
        XCTAssertTrue(fuse.isEnabled)
        fuse.tap()
        XCTAssertTrue(app.staticTexts["New weapon discovered"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Flame Blaster"].exists)
        capture(app, "First Fusion")
    }

    func testBattleNavigationAndLaunch() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()
        let start = app.buttons["Let’s build something"]
        XCTAssertTrue(start.waitForExistence(timeout: 20))
        start.tap()
        selectTab("Battle", in: app)
        let deploy = app.buttons["Deploy squad"]
        XCTAssertTrue(deploy.waitForExistence(timeout: 10))
        deploy.tap()
        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 10))
        capture(app, "Rust Flats Battle")
        app.buttons["Pause"].tap()
        XCTAssertTrue(app.staticTexts["Mission paused"].waitForExistence(timeout: 10))
        app.buttons["Retreat"].tap()
        XCTAssertTrue(app.staticTexts["Back to the drawing board"].waitForExistence(timeout: 10))
        app.buttons["Return to city"].tap()
        XCTAssertTrue(deploy.waitForExistence(timeout: 10))
    }

    private func selectTab(_ name: String, in app: XCUIApplication) {
        let compactTab = app.tabBars.buttons[name]
        if compactTab.exists { compactTab.tap() }
        else {
            let regularTab = app.buttons[name].firstMatch
            XCTAssertTrue(regularTab.waitForExistence(timeout: 10))
            regularTab.tap()
        }
    }

    private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
