import Foundation

public enum WeaponStyle: String, Sendable, CaseIterable {
    case bolt, spread, drone, missile, beam, arc, orbital
}
public extension Weapon {
    var style: WeaponStyle {
        switch id {
        case "shotgun", "frost", "blizzard": .spread
        case "fireDrone": .drone
        case "rocket", "swarm": .missile
        case "laser", "prism", "singularity": .beam
        case "arc", "chain", "plasma", "aurora": .arc
        case "orbital": .orbital
        default: .bolt
        }
    }
    var range: Double { style == .beam || style == .orbital ? 0.52 : style == .missile ? 0.48 : 0.40 }
}

public struct CombatProjectile: Identifiable, Sendable {
    public let id: Int
    public var position: Vector
    public var targetID: Int
    public var remaining: Double
    public let critical: Bool
}

public struct AttackArea: Sendable, Equatable {
    public enum Shape: Sendable { case circle, line, ring }
    public let shape: Shape
    public let from: Vector
    public let to: Vector
    public let radius: Double
    public var thickness: Double = 0.04
    public func contains(_ point: Vector) -> Bool {
        switch shape {
        case .circle: return (point - to).length <= radius
        case .ring: return abs((point - to).length - radius) <= thickness
        case .line:
            let segment = to - from
            let square = segment.x * segment.x + segment.y * segment.y
            let offset = point - from
            let projection = square > 0 ? min(1, max(0, (offset.x * segment.x + offset.y * segment.y) / square)) : 0
            return (point - (from + segment * projection)).length <= radius
        }
    }
}
public struct AttackWarning: Identifiable, Sendable {
    public let id: Int
    public let area: AttackArea
    public let damage: Double
    public let duration: Double
    public var remaining: Double
    public let boss: Bool
}

public enum BossPattern: String, CaseIterable, Sendable {
    case slam, charge, frostCross, toxicMines, fan, shockRing, sweep, bombardment, collapse
    public init(biomeID: String) {
        self = switch biomeID {
        case "neon": .charge
        case "frozen": .frostCross
        case "toxic": .toxicMines
        case "city": .fan
        case "electric": .shockRing
        case "graveyard": .sweep
        case "orbital": .bombardment
        case "rift": .collapse
        default: .slam
        }
    }
    public func areas(origin: Vector, target: Vector, enraged: Bool, sequence: Int) -> [AttackArea] {
        func circle(_ center: Vector, _ radius: Double) -> AttackArea { AttackArea(shape: .circle, from: center, to: center, radius: radius) }
        func line(_ from: Vector, _ to: Vector, _ width: Double) -> AttackArea { AttackArea(shape: .line, from: from, to: to, radius: width) }
        let direction = (target - origin).normalized
        switch self {
        case .slam: return [circle(target, enraged ? 0.16 : 0.14)]
        case .charge: return [line(origin, target, enraged ? 0.07 : 0.055)]
        case .frostCross:
            return [line(target + Vector(-0.28, 0), target + Vector(0.28, 0), 0.04), line(target + Vector(0, -0.28), target + Vector(0, 0.28), 0.04)]
        case .toxicMines:
            return (0..<3).map { index in
                let angle = Double(index) * .pi * 2 / 3 + Double(sequence) * 0.7
                return circle(target + Vector(cos(angle), sin(angle)) * 0.12, 0.09)
            }
        case .fan:
            return [-0.45, 0, 0.45].map { angle in
                let rotated = Vector(direction.x * cos(angle) - direction.y * sin(angle), direction.x * sin(angle) + direction.y * cos(angle))
                return line(origin, origin + rotated * 0.65, 0.035)
            }
        case .shockRing: return [AttackArea(shape: .ring, from: origin, to: origin, radius: enraged ? 0.30 : 0.24, thickness: 0.045)]
        case .sweep:
            return sequence % 2 == 0 ? [line(Vector(0.05, target.y), Vector(0.95, target.y), 0.055)] : [line(Vector(target.x, 0.05), Vector(target.x, 0.95), 0.055)]
        case .bombardment:
            return [Vector(-0.13, -0.13), Vector(0.13, -0.13), Vector(-0.13, 0.13), Vector(0.13, 0.13)].map { circle(target + $0, 0.085) }
        case .collapse:
            return [AttackArea(shape: .ring, from: target, to: target, radius: 0.21, thickness: 0.035), circle(target, enraged ? 0.10 : 0.07)]
        }
    }
}
