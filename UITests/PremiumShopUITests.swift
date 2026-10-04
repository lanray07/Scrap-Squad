import XCTest
import StoreKitTest

@MainActor final class PremiumShopUITests: XCTestCase {
    private let prefix = "com.ScrapSquad.app."
    private func launch(reset: Bool = true) -> XCUIApplication {
        let app = XCUIApplication(); app.launchArguments = ["--ui-testing", "--storekit-testing"] + (reset ? ["--reset-cosmetics"] : [])
        app.launch(); let start = app.buttons["Let’s build something"]; XCTAssertTrue(start.waitForExistence(timeout: 20)); start.tap()
        let tab = app.tabBars.buttons["Shop"]
        if tab.exists { tab.tap() } else { app.descendants(matching: .any).matching(identifier: "Shop").firstMatch.tap() }
        app.buttons["Signature collection"].tap(); return app
    }
    private func reveal(_ element: XCUIElement, _ app: XCUIApplication) {
        for _ in 0..<12 { if element.isHittable { return }; app.swipeUp() }
        XCTAssertTrue(element.isHittable)
    }
    private func top(_ app: XCUIApplication) { for _ in 0..<9 { app.swipeDown() } }
    private func capture(_ name: String) {
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot()); shot.name = name; shot.lifetime = .keepAlways; add(shot)
    }
    func testLivePreviewAndAllFiveProductCards() throws {
        executionTimeAllowance = 300
        let session = try SKTestSession(configurationFileNamed: "Cosmetics")
        session.resetToDefaultState(); session.disableDialogs = true; try session.clearTransactions()
        defer { try? session.clearTransactions() }
        let app = launch()
        let buy = app.buttons["buy-" + prefix + "collection"]
        XCTAssertTrue(buy.waitForExistence(timeout: 30)); reveal(buy, app)
        XCTAssertTrue(buy.label.contains("7.99")); capture("Premium-collection-review")
        app.buttons["preview-" + prefix + "collection"].tap()
        let arena = app.descendants(matching: .any).matching(identifier: "cosmetic-preview-arena").firstMatch
        XCTAssertTrue(arena.waitForExistence(timeout: 10))
        arena.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).press(forDuration: 0.1, thenDragTo: arena.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.4)))
        app.buttons["preview-dash"].tap(); capture("Premium-live-arena")
        app.buttons["Victory poses"].tap(); capture("Premium-victory-poses")
        app.buttons["preview-done"].tap()
        XCTAssertFalse(app.staticTexts["owned-" + prefix + "collection"].exists)
        for suffix in ["ronin", "bastion", "medic", "prism"] {
            let button = app.buttons["buy-" + prefix + suffix]; reveal(button, app)
            XCTAssertTrue(button.label.contains("2.99")); capture("Premium-" + suffix + "-review")
        }
        XCTAssertTrue(session.allTransactions().isEmpty)
    }
    func testBundleGrantsComponentsPersistsRestoresAndRefunds() throws {
        executionTimeAllowance = 300
        let session = try SKTestSession(configurationFileNamed: "Cosmetics")
        session.resetToDefaultState(); session.disableDialogs = true; try session.clearTransactions()
        defer { try? session.clearTransactions() }
        let app = launch(), buy = app.buttons["buy-" + prefix + "collection"]
        XCTAssertTrue(buy.waitForExistence(timeout: 30)); reveal(buy, app); buy.tap()
        XCTAssertTrue(app.staticTexts["owned-" + prefix + "collection"].waitForExistence(timeout: 20))
        for finish in ["bolt-ronin", "tank-bastion", "patch-medic"] {
            let equip = app.buttons["equip-" + finish]; reveal(equip, app); equip.tap(); XCTAssertEqual(equip.value as? String, "Equipped")
        }
        let effect = app.buttons["equip-effect-prism"]; reveal(effect, app); effect.tap(); XCTAssertEqual(effect.value as? String, "Equipped")
        XCTAssertFalse(app.buttons["buy-" + prefix + "prism"].exists); capture("Premium-bundle-equipped")
        app.terminate(); let relaunched = launch(reset: false)
        let equipped = relaunched.buttons["equip-bolt-ronin"]; reveal(equipped, relaunched); XCTAssertEqual(equipped.value as? String, "Equipped")
        let restore = relaunched.buttons["shop-restore"]; reveal(restore, relaunched); restore.tap()
        XCTAssertTrue(relaunched.staticTexts["Purchases restored."].waitForExistence(timeout: 20))
        let transaction = try XCTUnwrap(session.allTransactions().first { $0.productIdentifier == prefix + "collection" })
        try session.refundTransaction(identifier: transaction.identifier); relaunched.buttons["shop-refresh"].tap(); top(relaunched)
        XCTAssertTrue(relaunched.buttons["buy-" + prefix + "collection"].waitForExistence(timeout: 20))
        XCTAssertFalse(relaunched.buttons["equip-bolt-ronin"].exists); XCTAssertFalse(relaunched.buttons["equip-effect-prism"].exists)
        capture("Premium-bundle-refunded")
    }
    func testIndividualOwnershipBlocksOverlapAndPendingDoesNotGrant() throws {
        executionTimeAllowance = 300
        let session = try SKTestSession(configurationFileNamed: "Cosmetics")
        session.resetToDefaultState(); session.disableDialogs = true; try session.clearTransactions()
        defer { session.resetToDefaultState(); try? session.clearTransactions() }
        let app = launch(), buy = app.buttons["buy-" + prefix + "ronin"]
        XCTAssertTrue(buy.waitForExistence(timeout: 30)); reveal(buy, app); buy.tap()
        XCTAssertTrue(app.buttons["equip-bolt-ronin"].waitForExistence(timeout: 20)); top(app)
        XCTAssertTrue(app.staticTexts["bundle-overlap"].exists); XCTAssertFalse(app.buttons["buy-" + prefix + "collection"].exists)
        capture("Premium-owned-overlap-protected")
        session.askToBuyEnabled = true
        let prism = app.buttons["buy-" + prefix + "prism"]; reveal(prism, app); prism.tap()
        let message = app.staticTexts["Purchase is awaiting approval."]; reveal(message, app)
        XCTAssertTrue(message.waitForExistence(timeout: 15)); XCTAssertFalse(app.buttons["equip-effect-prism"].exists)
        let pending = try XCTUnwrap(session.allTransactions().first { $0.productIdentifier == prefix + "prism" && $0.pendingAskToBuyConfirmation })
        try session.declineAskToBuyTransaction(identifier: pending.identifier); app.buttons["shop-refresh"].tap()
        XCTAssertFalse(app.buttons["equip-effect-prism"].exists); capture("Premium-pending-declined")
    }
}
