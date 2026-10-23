import Foundation

public enum SalvageSystem: String, Codable, CaseIterable, Identifiable, Sendable {
    case weapon, armor, drive
    public var id: String { rawValue }
    public var nameKey: String { "salvage.system." + rawValue }
    public var symbol: String {
        switch self { case .weapon: "bolt.fill"; case .armor: "shield.fill"; case .drive: "arrow.triangle.branch" }
    }
    public var color: String {
        switch self { case .weapon: "FFB65C"; case .armor: "BBA2FF"; case .drive: "73E5D1" }
    }
    public var detailKey: String { "salvage.module." + rawValue }
}

public struct SalvageDrop: Identifiable, Sendable {
    public let id: Int
    public let system: SalvageSystem
    public let position: Vector
    public let expiresAt: Double
}

public struct SalvageReport: Codable, Equatable, Sendable {
    public let recovered: Int
    public let rebuilt: Int
    public let rescued: Bool
    public let extracted: Bool
}

/// Run-local parts and rebuilds. Premium finishes and the persistent squad are never changed.
public struct SalvageOperation: Sendable {
    public private(set) var focus: SalvageSystem = .weapon
    public private(set) var drops: [SalvageDrop] = []
    public private(set) var inventory: [SalvageSystem: Int] = [:]
    public private(set) var modules: [String: SalvageSystem] = [:]
    public private(set) var disabled: [Int: Set<SalvageSystem>] = [:]
    public private(set) var recovered = 0
    public private(set) var rebuilds = 0
    public private(set) var rescued = false
    public private(set) var escort = Vector(0.32, 0.62)
    public let extraction = Vector(0.74, 0.30)
    public private(set) var extractionProgress = 0.0
    public private(set) var extracted = false
    public private(set) var contested = false
    private var integrity: [Int: [SalvageSystem: Double]] = [:]
    private var serial = 0
    public init() {}
    public var report: SalvageReport { SalvageReport(recovered: recovered, rebuilt: rebuilds, rescued: rescued, extracted: extracted) }
    public var readyForExtraction: Bool { rescued && recovered >= 3 && rebuilds > 0 }
    public var objectiveKey: String {
        if extracted { return "salvage.objective.complete" }
        if !rescued { return "salvage.objective.rescue" }
        if recovered < 3 { return "salvage.objective.collect" }
        if rebuilds == 0 { return "salvage.objective.rebuild" }
        return contested ? "salvage.objective.contested" : "salvage.objective.extract"
    }
    public var damageScale: Double {
        max(0.7, 1 + Double(modules.values.filter { $0 == .weapon }.count) * 0.3 - Double(modules.values.filter { $0 == .drive }.count) * 0.1)
    }
    public var movementScale: Double {
        max(0.7, 1 + Double(modules.values.filter { $0 == .drive }.count) * 0.2 - Double(modules.values.filter { $0 == .weapon }.count) * 0.1)
    }
    public var attackScale: Double { max(0.55, 1 - Double(modules.values.filter { $0 == .armor }.count) * 0.15) }
    public var incomingScale: Double { max(0.4, 1 - Double(modules.values.filter { $0 == .armor }.count) * 0.25) }
    public mutating func target(_ system: SalvageSystem) { focus = system }
    public func systemFraction(enemyID: Int, maxHealth: Double) -> Double {
        if disabled[enemyID, default: []].contains(focus) { return 0 }
        return max(0, min(1, (integrity[enemyID]?[focus] ?? maxHealth * 0.28) / max(1, maxHealth * 0.28)))
    }
    public mutating func strike(enemy: Enemy, amount: Double, time: Double) {
        guard amount.isFinite, amount > 0, enemy.health > 0,
              !disabled[enemy.id, default: []].contains(focus) else { return }
        let remaining = (integrity[enemy.id]?[focus] ?? max(1, enemy.maxHealth * 0.28)) - amount
        integrity[enemy.id, default: [:]][focus] = remaining
        if remaining <= 0 {
            disabled[enemy.id, default: []].insert(focus)
            serial += 1
            // Stable, bounded collectibles: no extra RNG or unbounded scene allocation.
            if drops.count >= 24 { drops.removeFirst() }
            drops.append(SalvageDrop(id: serial, system: focus, position: enemy.position, expiresAt: time + 24))
        }
    }
    public mutating func advance(delta: Double, time: Double, player: Vector, enemies: [Enemy]) {
        let dt = min(0.05, max(0, delta))
        let living = Set(enemies.filter { $0.health > 0 }.map(\.id))
        integrity = integrity.filter { living.contains($0.key) }
        disabled = disabled.filter { living.contains($0.key) }
        for drop in drops where drop.expiresAt > time && (drop.position - player).length <= 0.085 {
            inventory[drop.system, default: 0] = min(99, inventory[drop.system, default: 0] + 1)
            recovered += 1
        }
        drops.removeAll { $0.expiresAt <= time || ($0.position - player).length <= 0.085 }
        if !rescued && (escort - player).length <= 0.10 { rescued = true }
        if rescued {
            let offset = player - escort
            if offset.length > 0.065 { escort = escort + offset.normalized * min(offset.length - 0.065, dt * 0.20) }
        }
        contested = enemies.contains { $0.health > 0 && ($0.position - extraction).length < 0.16 }
        if readyForExtraction && (player - extraction).length < 0.13 && (escort - extraction).length < 0.16 && !contested {
            extractionProgress = min(12, extractionProgress + dt)
        } else { extractionProgress = max(0, extractionProgress - dt * 2) }
        extracted = extractionProgress >= 12
    }
    @discardableResult public mutating func install(_ system: SalvageSystem, robotID: String, squad: [String]) -> Bool {
        guard squad.contains(robotID), modules[robotID] != system, inventory[system, default: 0] >= 2 else { return false }
        inventory[system, default: 0] -= 2
        modules[robotID] = system
        rebuilds += 1
        return true
    }
}
