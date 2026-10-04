import Foundation
import Testing
@testable import ScrapCore

private func cosmeticCatalog() throws -> CosmeticCatalog {
    let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    return try JSONDecoder().decode(CosmeticCatalog.self, from: Data(contentsOf: root.appendingPathComponent("App/Resources/StoreConfiguration.json")))
}
@Test func cosmeticCatalogMatchesRealRobots() throws {
    let catalog = try cosmeticCatalog(), content = try GameContent.bundled()
    #expect(catalog.packs.count == 7)
    #expect(Set(catalog.productIDs).count == 7)
    let finishes = catalog.packs.flatMap(\.finishes)
    #expect(finishes.count == 7)
    #expect(Set(finishes.map(\.id)).count == 7)
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

@Test func premiumBundleOwnershipAndRevocation() throws {
    let catalog = try cosmeticCatalog()
    let bundle = "com.ScrapSquad.app.collection", ronin = "com.ScrapSquad.app.ronin", prism = "com.ScrapSquad.app.prism"
    #expect(catalog.canPurchase(bundle, owned: []))
    #expect(!catalog.canPurchase(bundle, owned: [ronin]))
    #expect(catalog.canPurchase(prism, owned: [ronin]))
    #expect(!catalog.canPurchase(ronin, owned: [bundle]))
    #expect(catalog.availableFinishes(owned: [bundle]).count == 3)
    #expect(!catalog.hasFounderExtras(owned: [bundle]))
    var selection = CosmeticSelection()
    selection.robotFinishIDs = ["bolt": "bolt-ronin"]; selection.weaponEffectID = "prism"
    selection.reconcile(catalog: catalog, owned: [bundle])
    #expect(selection.robotFinishIDs["bolt"] == "bolt-ronin")
    #expect(selection.weaponEffectID == "prism")
    selection.reconcile(catalog: catalog, owned: [ronin])
    #expect(selection.robotFinishIDs["bolt"] == "bolt-ronin")
    #expect(selection.weaponEffectID == nil)
    selection.reconcile(catalog: catalog, owned: [])
    #expect(selection.robotFinishIDs.isEmpty)
}
@Test func oldCosmeticSaveAndPremiumManifest() throws {
    let saved = try JSONDecoder().decode(CosmeticSelection.self, from: Data("{\"robotFinishIDs\":{},\"goldenTrails\":true,\"founderBadge\":true}".utf8))
    #expect(saved.weaponEffectID == nil)
    let catalog = try cosmeticCatalog()
    for pack in catalog.packs {
        #expect((pack.includes ?? []).allSatisfy { catalog.productIDs.contains($0) && $0 != pack.id })
        #expect(pack.finishes.allSatisfy { $0.skin == nil || ["ronin", "bastion", "medic"].contains($0.skin!) })
    }
}
