import Foundation

public enum Rarity: String, Codable, CaseIterable, Sendable {
    case common, uncommon, rare, epic, legendary, mythic
    public var tier: Int { Self.allCases.firstIndex(of: self)! + 1 }
}
public enum Element: String, Codable, CaseIterable, Sendable {
    case ballistic, fire, cryo, electric, energy, explosive, drone, experimental
}
public struct WeaponModifier: Codable, Sendable, Equatable {
    public let kind: String
    public let value: Double
}
public struct Weapon: Codable, Identifiable, Sendable {
    public let id: String
    public let nameKey: String
    public let descriptionKey: String
    public let element: Element
    public let rarity: Rarity
    public let damage: Double
    public let interval: Double
    public let projectiles: Int
    public let modifiers: [WeaponModifier]
}
public struct Component: Codable, Identifiable, Sendable {
    public let id: String
    public let nameKey: String
    public let element: Element
}
public struct FusionRecipe: Codable, Identifiable, Sendable {
    public let id: String
    public let weapon: String
    public let component: String
    public let result: String
    public let scrapCost: Int
    public let clueKey: String
}
public struct Blueprint: Identifiable, Sendable {
    public let recipe: FusionRecipe
    public let discovered: Bool
    public var id: String { recipe.id }
}
public struct WeaponEvolution: Codable, Sendable {
    public let weaponID: String
    public var level: Int
    public var damageMultiplier: Double { 1 + Double(level - 1) * 0.12 }
}
public struct Robot: Codable, Identifiable, Sendable {
    public let id: String
    public let nameKey: String
    public let personalityKey: String
    public let passiveKey: String
    public let activeKey: String
    public let rarity: Rarity
    public let health: Double
    public let damageBonus: Double
    public let speedBonus: Double
    public let affinity: Element
    public let unlockCost: Int
    public let silhouette: String
    public let color: String
}
public struct Building: Codable, Identifiable, Sendable {
    public let id: String
    public let nameKey: String
    public let descriptionKey: String
    public let baseCost: Int
    public let symbol: String
    public let maxLevel: Int
}
public struct Biome: Codable, Identifiable, Sendable {
    public let id: String
    public let nameKey: String
    public let bossKey: String
    public let weakness: Element
    public let palette: [String]
    public let difficulty: Double
    public let hazard: String
    public let enemies: [String]
}
public struct Upgrade: Codable, Identifiable, Sendable {
    public let id: String
    public let nameKey: String
    public let descriptionKey: String
    public let element: Element
    public let kind: String
    public let value: Double
    public let symbol: String
}
public struct Economy: Codable, Sendable {
    public let offlineCapHours: Int
    public let offlineScrapPerMinute: Double
    public let offlineCreditsPerMinute: Double
    public let robotLevelBaseCost: Int
    public let costGrowth: Double
    public let killScrap: Int
    public let bossCredits: Int
    public let runSeconds: Double
    public let bossAtSeconds: Double
    public let upgradeSeconds: [Double]
    public let rebootZone: Int
}
public struct GameContent: Codable, Sendable {
    public let weapons: [Weapon]
    public let components: [Component]
    public let recipes: [FusionRecipe]
    public let robots: [Robot]
    public let buildings: [Building]
    public let biomes: [Biome]
    public let upgrades: [Upgrade]
    public let economy: Economy

    public static func bundled() throws -> GameContent {
        guard let url = Bundle.module.url(forResource: "content", withExtension: "json") else {
            throw GameError.invalidContent
        }
        let result = try JSONDecoder().decode(Self.self, from: Data(contentsOf: url))
        try result.validate()
        return result
    }
    public func validate() throws {
        let weaponIDs = Set(weapons.map(\.id)), componentIDs = Set(components.map(\.id))
        guard weaponIDs.count == weapons.count, componentIDs.count == components.count,
              Set(recipes.map(\.id)).count == recipes.count,
              Set(robots.map(\.id)).count == robots.count,
              !biomes.isEmpty, !buildings.isEmpty, upgrades.count >= 3,
              weaponIDs.contains("blaster"), robots.contains(where: { $0.id == "bolt" }),
              economy.offlineCapHours > 0, economy.costGrowth >= 1,
              economy.bossAtSeconds < economy.runSeconds else { throw GameError.invalidContent }
        for weapon in weapons {
            guard weapon.damage > 0, weapon.interval > 0, weapon.projectiles > 0 else { throw GameError.invalidContent }
        }
        var pairs = Set<String>()
        for recipe in recipes {
            guard weaponIDs.contains(recipe.weapon), weaponIDs.contains(recipe.result),
                  componentIDs.contains(recipe.component), recipe.scrapCost >= 0,
                  pairs.insert(recipe.weapon + ":" + recipe.component).inserted else { throw GameError.invalidContent }
        }
    }
}
public enum GameError: Error, Equatable, Sendable {
    case invalidContent, insufficientFunds, missingIngredient, locked, invalidSelection, maxLevel
}
public enum GameMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case campaign, survival, bossRush, scrapRun, fusionLab, dailyAnomaly, arena
    public var id: String { rawValue }
    public var leaderboard: String? {
        switch self {
        case .survival: "scrapsquad.survival"
        case .bossRush: "scrapsquad.bossrush"
        case .dailyAnomaly: "scrapsquad.daily"
        default: nil
        }
    }
}
