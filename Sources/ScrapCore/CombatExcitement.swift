import Foundation

public enum RunEvolution: String, Codable, CaseIterable, Identifiable, Sendable {
    case fireVortex, stormCage, siegeBarrage
    public var id: String { rawValue }
    public var nameKey: String { "evolution." + rawValue }
    public var detailKey: String { nameKey + ".detail" }
    public var requirements: Set<String> {
        switch self {
        case .fireVortex: ["burn", "speed"]
        case .stormCage: ["chain", "split"]
        case .siegeBarrage: ["explosion", "critical"]
        }
    }
    public var color: String {
        switch self {
        case .fireVortex: "FF9D55"
        case .stormCage: "83EAFF"
        case .siegeBarrage: "BC9BFF"
        }
    }
    public func ready(kinds: Set<String>) -> Bool { requirements.isSubset(of: kinds) }
    public func areas(center: Vector, time: Double) -> [AttackArea] {
        switch self {
        case .fireVortex:
            return (0..<3).map { index in
                let angle = time * 2.4 + Double(index) * .pi * 2 / 3
                let position = center + Vector(cos(angle), sin(angle)) * 0.17
                return AttackArea(shape: .circle, from: position, to: position, radius: 0.085)
            }
        case .stormCage:
            return [AttackArea(shape: .ring, from: center, to: center, radius: 0.24, thickness: 0.07)]
        case .siegeBarrage: return []
        }
    }
}

public enum WaveEventKind: String, CaseIterable, Sendable {
    case eliteAmbush, scrapStorm, treasureCarrier
    public var nameKey: String { "event." + rawValue }
    public var detailKey: String { nameKey + ".detail" }
    public var duration: Double { self == .scrapStorm ? 8 : 12 }
    public var scrapReward: Int { self == .eliteAmbush ? 60 : 40 }
}

public struct WaveEvent: Sendable {
    public let sequence: Int
    public let kind: WaveEventKind
    public let endsAt: Double
    public var enemyIDs: Set<Int> = []
}

public struct EvolutionStrike: Identifiable, Sendable {
    public let id: Int
    public let area: AttackArea
    public var remaining: Double
}
