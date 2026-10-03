import Foundation
import Testing
@testable import ScrapCore

private func cosmeticCatalog() throws -> CosmeticCatalog {
    let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    return try JSONDecoder().decode(CosmeticCatalog.self, from: Data(contentsOf: root.appendingPathComponent("App/Resources/StoreConfiguration.json")))
}
@Test func cosmeticCatalogMatchesRealRobots() throws {
    let catalog = try cosmeticCatalog(), content = try GameContent.bundled()
    #expect(catalog.packs.count == 2)
    #expect(Set(catalog.productIDs).count == 2)
    let finishes = catalog.packs.flatMap(\.finishes)
    #expect(finishes.count == 4)
    #expect(Set(finishes.map(\.id)).count == 4)
    for finish in finishes { #expect(content.robots.contains { $0.id == finish.robotID }) }
    #expect(catalog.availableFinishes(owned: []).isEmpty)
    #expect(!catalog.hasFounderExtras(owned: ["unknown"]))
}
@Test func cosmeticOwnershipAndRefunds() throws {
    let catalog = try cosmeticCatalog()
    let founder = catalog.packs[0], styles = catalog.packs[1]
    var selection = CosmeticSelection()
    selection.robotFinishIDs = ["bolt": founder.finishes[0].id, "tank": styles.finishes[1].id, "patch": "unknown-finish"]
    selection.goldenTrails = true; selection.founderBadge = true
    #expect(selection.activeFinishes(catalog: catalog, owned: []).isEmpty)
    selection.reconcile(catalog: catalog, owned: [founder.id, styles.id])
    #expect(selection.robotFinishIDs.count == 2)
    #expect(selection.goldenTrails)
    let roundTrip = try JSONDecoder().decode(CosmeticSelection.self, from: JSONEncoder().encode(selection))
    #expect(roundTrip == selection)
    selection.reconcile(catalog: catalog, owned: [styles.id])
    #expect(selection.robotFinishIDs == ["tank": styles.finishes[1].id])
    #expect(!selection.goldenTrails && !selection.founderBadge)
    selection.reconcile(catalog: catalog, owned: [])
    #expect(selection.robotFinishIDs.isEmpty)
}
