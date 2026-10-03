import Foundation

// Cosmetics never enter PlayerProfile or combat/economy calculations.
public struct RobotFinish: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let robotID: String
    public let nameKey: String
    public let tint: String
    public let accent: String
    public let symbol: String
}
public struct CosmeticPack: Codable, Identifiable, Sendable {
    public let id: String
    public let nameKey: String
    public let detailKey: String
    public let finishes: [RobotFinish]
    public let founderExtras: Bool
}
public struct CosmeticCatalog: Codable, Sendable {
    public let packs: [CosmeticPack]
    public var productIDs: [String] { packs.map(\.id) }
    public init(packs: [CosmeticPack]) { self.packs = packs }
    public func availableFinishes(owned: Set<String>) -> [RobotFinish] {
        packs.filter { owned.contains($0.id) }.flatMap(\.finishes)
    }
    public func hasFounderExtras(owned: Set<String>) -> Bool {
        packs.contains { $0.founderExtras && owned.contains($0.id) }
    }
}
public struct CosmeticSelection: Codable, Equatable, Sendable {
    public var robotFinishIDs: [String: String] = [:]
    public var goldenTrails = false
    public var founderBadge = false
    public init() {}
    public func activeFinishes(catalog: CosmeticCatalog, owned: Set<String>) -> [String: RobotFinish] {
        var result: [String: RobotFinish] = [:]
        for finish in catalog.availableFinishes(owned: owned) where robotFinishIDs[finish.robotID] == finish.id {
            result[finish.robotID] = finish
        }
        return result
    }
    public mutating func reconcile(catalog: CosmeticCatalog, owned: Set<String>) {
        let valid = activeFinishes(catalog: catalog, owned: owned)
        robotFinishIDs = valid.mapValues(\.id)
        if !catalog.hasFounderExtras(owned: owned) { goldenTrails = false; founderBadge = false }
    }
}
