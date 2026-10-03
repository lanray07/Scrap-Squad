import XCTest
import StoreKitTest

@MainActor final class CosmeticPurchaseUITests: XCTestCase {
    private let founder = "com.ScrapSquad.app.founder"
    private let styles = "com.ScrapSquad.app.styles"
    func testPurchaseEquipRestoreAndRefund() throws {
        executionTimeAllowance = 240
        let session = try SKTestSession(configurationFileNamed: "Cosmetics")
        session.resetToDefaultState(); session.disableDialogs = true; try session.clearTransactions()
        defer { try? session.clearTransactions() }
        let app = launchShop(reset: true)
        let buy = app.buttons["buy-" + founder]
        XCTAssertTrue(buy.waitForExistence(timeout: 30))
        capture(app, "IAP-01-founder-review")
        buy.tap()
        XCTAssertTrue(app.staticTexts["owned-" + founder].waitForExistence(timeout: 15))
        let equip = app.buttons["equip-bolt-founders-gold"]
        equip.tap()
        XCTAssertEqual(equip.value as? String, "Equipped")
        app.switches["golden-trails-toggle"].tap()
        app.switches["founder-badge-toggle"].tap()
        capture(app, "IAP-02-founder-owned")
        app.terminate()
        app.launchArguments = ["--ui-testing", "--storekit-testing"]
        app.launch(); openShop(app)
        XCTAssertTrue(app.buttons["equip-bolt-founders-gold"].waitForExistence(timeout: 20))
        XCTAssertEqual(app.buttons["equip-bolt-founders-gold"].value as? String, "Equipped")
        let restore = app.buttons["shop-restore"]
        app.swipeUp(); app.swipeUp()
        XCTAssertTrue(restore.waitForExistence(timeout: 10)); restore.tap()
        XCTAssertTrue(app.staticTexts["Purchases restored."].waitForExistence(timeout: 20))
        let transaction = try XCTUnwrap(session.allTransactions().first { $0.productIdentifier == founder })
        try session.refundTransaction(identifier: transaction.identifier)
        app.buttons["shop-refresh"].tap()
        app.swipeDown(); app.swipeDown()
        XCTAssertTrue(app.buttons["buy-" + founder].waitForExistence(timeout: 15))
        XCTAssertFalse(app.buttons["equip-bolt-founders-gold"].exists)
        capture(app, "IAP-03-refunded")
    }
    func testStylePackPurchaseAndSelection() throws {
        executionTimeAllowance = 240
        let session = try SKTestSession(configurationFileNamed: "Cosmetics")
        session.resetToDefaultState(); session.disableDialogs = true; try session.clearTransactions()
        defer { try? session.clearTransactions() }
        let app = launchShop(reset: true)
        app.swipeUp()
        let buy = app.buttons["buy-" + styles]
        XCTAssertTrue(buy.waitForExistence(timeout: 30))
        capture(app, "IAP-04-styles-review")
        buy.tap()
        let equip = app.buttons["equip-bolt-aurora"]
        XCTAssertTrue(equip.waitForExistence(timeout: 15)); equip.tap()
        XCTAssertEqual(equip.value as? String, "Equipped")
        capture(app, "IAP-05-styles-owned")
        equip.tap(); XCTAssertEqual(equip.value as? String, "Original finish")
    }
    private func launchShop(reset: Bool) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--storekit-testing"] + (reset ? ["--reset-cosmetics"] : [])
        app.launch(); openShop(app); return app
    }
    private func openShop(_ app: XCUIApplication) {
        let start = app.buttons["Let’s build something"]
        XCTAssertTrue(start.waitForExistence(timeout: 20)); start.tap()
        let compact = app.tabBars.buttons["Shop"]
        if compact.exists { compact.tap() }
        else { app.descendants(matching: .any).matching(identifier: "Shop").firstMatch.tap() }
    }
    private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot()); attachment.name = name; attachment.lifetime = .keepAlways
        add(attachment)
    }
}
