import Foundation

// Cosmetics never enter PlayerProfile or combat/economy calculations.
public struct RobotFinish: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let robotID: String
    public let nameKey: String
    public let tint: String
    public let accent: String
    public let symbol: String
    public var skin: String? = nil
}
public struct CosmeticPack: Codable, Identifiable, Sendable {
    public let id: String
    public let nameKey: String
    public let detailKey: String
    public let finishes: [RobotFinish]
    public let founderExtras: Bool
    public var includes: [String]? = nil
    public var weaponEffect: String? = nil
}
public struct CosmeticCatalog: Codable, Sendable {
    public let packs: [CosmeticPack]
    public var productIDs: [String] { packs.map(\.id) }
    public init(packs: [CosmeticPack]) { self.packs = packs }
    public func effectiveOwnership(_ owned: Set<String>) -> Set<String> {
        var result = owned.intersection(Set(productIDs))
        // Expand only configured grants; bounded traversal also tolerates malformed cycles.
        for _ in 0..<packs.count {
            let before = result
            for pack in packs where result.contains(pack.id) {
                result.formUnion((pack.includes ?? []).filter { productIDs.contains($0) })
            }
            if before == result { break }
        }
        return result
    }
    public func canPurchase(_ id: String, owned: Set<String>) -> Bool {
        guard let pack = packs.first(where: { $0.id == id }) else { return false }
        let effective = effectiveOwnership(owned)
        return !effective.contains(id) && (pack.includes ?? []).allSatisfy { !effective.contains($0) }
    }
    public func availableFinishes(owned: Set<String>) -> [RobotFinish] {
        let effective = effectiveOwnership(owned)
        return packs.filter { effective.contains($0.id) }.flatMap(\.finishes)
    }
    public func availableWeaponEffects(owned: Set<String>) -> Set<String> {
        let effective = effectiveOwnership(owned)
        return Set(packs.filter { effective.contains($0.id) }.compactMap(\.weaponEffect))
    }
    public func hasFounderExtras(owned: Set<String>) -> Bool {
        packs.contains { $0.founderExtras && effectiveOwnership(owned).contains($0.id) }
    }
}
public struct CosmeticSelection: Codable, Equatable, Sendable {
    public var robotFinishIDs: [String: String] = [:]
    public var goldenTrails = false
    public var founderBadge = false
    public var weaponEffectID: String? = nil
    public init() {}
    public func activeFinishes(catalog: CosmeticCatalog, owned: Set<String>) -> [String: RobotFinish] {
        var result: [String: RobotFinish] = [:]
        for finish in catalog.availableFinishes(owned: owned) where robotFinishIDs[finish.robotID] == finish.id {
            result[finish.robotID] = finish
        }
        return result
    }
    public mutating func reconcile(catalog: CosmeticCatalog, owned: Set<String>) {
        if let effect = weaponEffectID, !catalog.availableWeaponEffects(owned: owned).contains(effect) { weaponEffectID = nil }
        let valid = activeFinishes(catalog: catalog, owned: owned)
        robotFinishIDs = valid.mapValues(\.id)
        if !catalog.hasFounderExtras(owned: owned) { goldenTrails = false; founderBadge = false }
    }
}
