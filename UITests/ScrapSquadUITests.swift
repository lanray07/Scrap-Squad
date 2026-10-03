import XCTest

@MainActor final class ScrapSquadUITests: XCTestCase {
    func testStoreScreenshotTour() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()
        let start = app.buttons["Let’s build something"]
        XCTAssertTrue(start.waitForExistence(timeout: 20))
        capture(app, "Store-01-onboarding")
        start.tap()
        XCTAssertTrue(app.staticTexts["Welcome to Scrap City"].waitForExistence(timeout: 10))
        capture(app, "Store-02-city")
        app.tabBars.buttons["Squad"].tap()
        XCTAssertTrue(app.staticTexts["BOLT"].firstMatch.waitForExistence(timeout: 10))
        capture(app, "Store-03-squad")
        app.tabBars.buttons["Blueprints"].tap()
        XCTAssertTrue(app.staticTexts["0 / 12"].waitForExistence(timeout: 10))
        capture(app, "Store-04-blueprints")
        app.tabBars.buttons["City"].tap()
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
        app.tabBars.buttons["Battle"].tap()
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
        app.tabBars.buttons["Battle"].tap()
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

    private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
