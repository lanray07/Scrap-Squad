import Foundation

public struct Preferences: Codable, Sendable {
    public var haptics = true
    public var reducedMotion = false
    public var reducedFlashes = true
    public var screenShake = false
    public var damageNumbers = true
    public var particleIntensity = 0.5
    public var masterVolume = 0.7
    public var musicVolume = 0.5
    public var sfxVolume = 0.7
    public var locale = "system"
    public init() {}
}
public struct PlayerProfile: Codable, Sendable {
    public var schemaVersion = 1
    public var credits = 500
    public var scrap = 350
    public var cores = 3
    public var weapons: [String: Int] = ["blaster": 2, "shotgun": 1, "rocket": 1, "laser": 1]
    public var components: [String: Int] = ["fire": 2, "tesla": 2, "cryo": 2, "drone": 2, "splitter": 1, "explosive": 1, "ricochet": 1]
    public var blueprints: Set<String> = []
    public var unlockedRobots: Set<String> = ["bolt", "patch"]
    public var squad = ["bolt", "patch"]
    public var unlockedSquadCapacity = 2
    public var equippedWeapon = "blaster"
    public var robotLevels: [String: Int] = [:]
    public var buildingLevels: [String: Int] = [:]
    public var weaponLevels: [String: Int] = [:]
    public var zone = 0
    public var kills = 0
    public var bosses = 0
    public var completedRuns = 0
    public var reboots = 0
    public var lastSeen: Date
    public var claimedRunIDs: Set<UUID> = []
    public var dailyKey = ""
    public var dailyKills = 0
    public var dailyClaimed = false
    public var weeklyKey = ""
    public var weeklyBosses = 0
    public var weeklyClaimed = false
    public var preferences = Preferences()
    // Optional for backward-compatible decoding of existing version 1 saves.
    public var journal: RunJournal? = nil
    public init(now: Date = Date()) { lastSeen = now }
    public var squadCapacity: Int { min(4, max(unlockedSquadCapacity, 2 + (buildingLevels["command"] ?? 0) / 2)) }
    public var playerLevel: Int { 1 + completedRuns / 3 }
    public var cityLevel: Int { 1 + buildingLevels.values.reduce(0, +) }
    public func validate(content: GameContent) throws {
        let weaponIDs = Set(content.weapons.map(\.id)), robotIDs = Set(content.robots.map(\.id))
        let componentIDs = Set(content.components.map(\.id)), buildingIDs = Set(content.buildings.map(\.id))
        guard schemaVersion == 1, credits >= 0, scrap >= 0, cores >= 0,
              zone >= 0, zone < content.biomes.count, kills >= 0, bosses >= 0, reboots >= 0,
              (2...4).contains(unlockedSquadCapacity),
              !squad.isEmpty, squad.count <= squadCapacity, Set(squad).count == squad.count,
              Set(squad).isSubset(of: unlockedRobots), unlockedRobots.isSubset(of: robotIDs),
              weaponIDs.contains(equippedWeapon), weapons[equippedWeapon, default: 0] > 0,
              Set(weapons.keys).isSubset(of: weaponIDs), weapons.values.allSatisfy({ $0 >= 0 }),
              Set(components.keys).isSubset(of: componentIDs), components.values.allSatisfy({ $0 >= 0 }),
              blueprints.isSubset(of: Set(content.recipes.map(\.id))),
              Set(robotLevels.keys).isSubset(of: robotIDs), robotLevels.values.allSatisfy({ (1...50).contains($0) }),
              Set(weaponLevels.keys).isSubset(of: weaponIDs), weaponLevels.values.allSatisfy({ (1...30).contains($0) }),
              Set(buildingLevels.keys).isSubset(of: buildingIDs), buildingLevels.values.allSatisfy({ (0...10).contains($0) }),
              [preferences.masterVolume, preferences.musicVolume, preferences.sfxVolume, preferences.particleIntensity].allSatisfy({ $0.isFinite && (0...1).contains($0) }) else { throw GameError.invalidContent }
    }
}
public struct OfflineReward: Sendable, Equatable {
    public let seconds: TimeInterval
    public let scrap: Int
    public let credits: Int
    public var isAvailable: Bool { scrap > 0 || credits > 0 }
}
public struct RunReward: Sendable {
    public let id: UUID
    public let mode: GameMode
    public let zone: Int
    public let kills: Int
    public let bosses: Int
    public let score: Int
    public let victory: Bool
    public let highlights: RunHighlights?
    public init(id: UUID, mode: GameMode, zone: Int, kills: Int, bosses: Int, score: Int, victory: Bool, highlights: RunHighlights? = nil) {
        self.id = id; self.mode = mode; self.zone = zone; self.kills = kills
        self.bosses = bosses; self.score = score; self.victory = victory
        self.highlights = highlights
    }
}
public enum Progression {
    public static func offline(profile: PlayerProfile, content: GameContent, now: Date) -> OfflineReward {
        let elapsed = max(0, min(now.timeIntervalSince(profile.lastSeen), Double(content.economy.offlineCapHours) * 3600))
        // Dock construction starts expeditions. Rates are derived from real elapsed time.
        let dock = profile.buildingLevels["dock"] ?? 0
        let multiplier = Double(dock) * (1 + Double(profile.zone) * 0.1)
        return OfflineReward(seconds: elapsed,
            scrap: Int(elapsed / 60 * content.economy.offlineScrapPerMinute * multiplier),
            credits: Int(elapsed / 60 * content.economy.offlineCreditsPerMinute * multiplier))
    }
    @discardableResult
    public static func claimOffline(_ profile: inout PlayerProfile, content: GameContent, now: Date) -> OfflineReward {
        let reward = offline(profile: profile, content: content, now: now)
        profile.scrap += reward.scrap; profile.credits += reward.credits
        profile.lastSeen = max(profile.lastSeen, now)
        return reward
    }
    public static func fuse(_ recipe: FusionRecipe, profile: inout PlayerProfile) throws {
        guard profile.scrap >= recipe.scrapCost else { throw GameError.insufficientFunds }
        guard profile.weapons[recipe.weapon, default: 0] > 0,
              profile.components[recipe.component, default: 0] > 0 else { throw GameError.missingIngredient }
        profile.scrap -= recipe.scrapCost
        profile.weapons[recipe.weapon, default: 0] -= 1
        profile.components[recipe.component, default: 0] -= 1
        profile.weapons[recipe.result, default: 0] += 1
        profile.blueprints.insert(recipe.id)
        if profile.equippedWeapon == recipe.weapon && profile.weapons[recipe.weapon, default: 0] == 0 {
            profile.equippedWeapon = recipe.result
        }
    }
    // All eligible results are shown before consuming anything; each has equal probability.
    public static func rouletteCandidates(a: String, b: String, content: GameContent) -> [Weapon] {
        guard a != b, let first = content.weapons.first(where: { $0.id == a }),
              let second = content.weapons.first(where: { $0.id == b }) else { return [] }
        return content.weapons.filter {
            $0.id != a && $0.id != b && $0.rarity.tier >= max(first.rarity.tier, second.rarity.tier)
            && ($0.element == first.element || $0.element == second.element)
        }.sorted { $0.id < $1.id }
    }
    public static func roulette(a: String, b: String, profile: inout PlayerProfile, content: GameContent, randomIndex: Int) throws -> Weapon {
        let options = rouletteCandidates(a: a, b: b, content: content)
        guard !options.isEmpty, options.indices.contains(randomIndex) else { throw GameError.invalidSelection }
        guard profile.cores >= 1 else { throw GameError.insufficientFunds }
        guard profile.weapons[a, default: 0] > 0, profile.weapons[b, default: 0] > 0 else { throw GameError.missingIngredient }
        let result = options[randomIndex]
        profile.cores -= 1; profile.weapons[a, default: 0] -= 1; profile.weapons[b, default: 0] -= 1
        profile.weapons[result.id, default: 0] += 1
        for recipe in content.recipes where recipe.result == result.id { profile.blueprints.insert(recipe.id) }
        if profile.weapons[profile.equippedWeapon, default: 0] == 0 { profile.equippedWeapon = result.id }
        return result
    }
    public static func cost(base: Int, level: Int, economy: Economy) -> Int {
        Int((Double(base) * pow(economy.costGrowth, Double(level))).rounded(.up))
    }
    public static func upgradeBuilding(_ building: Building, profile: inout PlayerProfile, content: GameContent, now: Date = Date()) throws {
        let level = profile.buildingLevels[building.id, default: 0]
        guard level < building.maxLevel else { throw GameError.maxLevel }
        let price = cost(base: building.baseCost, level: level, economy: content.economy)
        guard profile.scrap >= price else { throw GameError.insufficientFunds }
        // Settle the old expedition rate before raising it. Never grant retroactive rewards.
        if building.id == "dock" { _ = claimOffline(&profile, content: content, now: now) }
        profile.scrap -= price; profile.buildingLevels[building.id] = level + 1
        if building.id == "command" { profile.unlockedSquadCapacity = profile.squadCapacity }
    }
    public static func upgradeRobot(_ robot: Robot, profile: inout PlayerProfile, content: GameContent) throws {
        guard profile.unlockedRobots.contains(robot.id) else {
            guard profile.credits >= robot.unlockCost else { throw GameError.insufficientFunds }
            profile.credits -= robot.unlockCost; profile.unlockedRobots.insert(robot.id); return
        }
        let level = profile.robotLevels[robot.id, default: 1]
        guard level < 50 else { throw GameError.maxLevel }
        let price = cost(base: content.economy.robotLevelBaseCost, level: level - 1, economy: content.economy)
        guard profile.credits >= price else { throw GameError.insufficientFunds }
        profile.credits -= price; profile.robotLevels[robot.id] = level + 1
    }
    public static func upgradeWeapon(_ weapon: Weapon, profile: inout PlayerProfile, content: GameContent) throws {
        guard profile.weapons[weapon.id, default: 0] > 0 else { throw GameError.locked }
        let level = profile.weaponLevels[weapon.id, default: 1]
        guard level < 30 else { throw GameError.maxLevel }
        let price = cost(base: 80, level: level - 1, economy: content.economy)
        guard profile.scrap >= price else { throw GameError.insufficientFunds }
        profile.scrap -= price; profile.weaponLevels[weapon.id] = level + 1
    }
    public static func toggleSquad(_ id: String, profile: inout PlayerProfile) throws {
        guard profile.unlockedRobots.contains(id) else { throw GameError.locked }
        if profile.squad.contains(id) {
            guard profile.squad.count > 1 else { throw GameError.invalidSelection }
            profile.squad.removeAll { $0 == id }
        } else {
            guard profile.squad.count < profile.squadCapacity else { throw GameError.invalidSelection }
            profile.squad.append(id)
        }
    }
    @discardableResult
    public static func apply(_ reward: RunReward, profile: inout PlayerProfile, content: GameContent, now: Date) -> Bool {
        guard !profile.claimedRunIDs.contains(reward.id) else { return false }
        profile.claimedRunIDs.insert(reward.id)
        // Bound save size; the application never retains more than one pending run.
        if profile.claimedRunIDs.count > 256 { profile.claimedRunIDs = [reward.id] }
        profile.kills += reward.kills; profile.bosses += reward.bosses
        profile.completedRuns += 1
        if let highlights = reward.highlights {
            var journal = profile.journal ?? RunJournal()
            journal.record(RunRecord(reward: reward, highlights: highlights, date: now))
            profile.journal = journal
        }
        profile.scrap += reward.kills * content.economy.killScrap * (reward.mode == .scrapRun ? 2 : 1)
        profile.credits += reward.kills * 3 + reward.bosses * content.economy.bossCredits
        if reward.victory {
            profile.cores += 1
            if reward.mode == .campaign && reward.zone == profile.zone { profile.zone = min(profile.zone + 1, content.biomes.count - 1) }
            let component = content.components[profile.completedRuns % content.components.count]
            profile.components[component.id, default: 0] += 2
            profile.weapons["blaster", default: 0] += 1
        }
        refreshMissions(&profile, now: now)
        profile.dailyKills += reward.kills; profile.weeklyBosses += reward.bosses
        return true
    }
    public static func refreshMissions(_ profile: inout PlayerProfile, now: Date) {
        var calendar = Calendar(identifier: .iso8601); calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let day = calendar.dateComponents([.year, .month, .day], from: now)
        let week = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        let key = "\(day.year!)-\(day.month!)-\(day.day!)"
        let weekKey = "\(week.yearForWeekOfYear!)-\(week.weekOfYear!)"
        if profile.dailyKey != key { profile.dailyKey = key; profile.dailyKills = 0; profile.dailyClaimed = false }
        if profile.weeklyKey != weekKey { profile.weeklyKey = weekKey; profile.weeklyBosses = 0; profile.weeklyClaimed = false }
    }
    public static func claimMission(weekly: Bool, profile: inout PlayerProfile, now: Date) throws {
        refreshMissions(&profile, now: now)
        if weekly {
            guard profile.weeklyBosses >= 3, !profile.weeklyClaimed else { throw GameError.locked }
            profile.weeklyClaimed = true; profile.credits += 900; profile.cores += 2
        } else {
            guard profile.dailyKills >= 60, !profile.dailyClaimed else { throw GameError.locked }
            profile.dailyClaimed = true; profile.scrap += 200
        }
    }
    public static func reboot(_ profile: inout PlayerProfile, content: GameContent) throws {
        guard profile.zone >= content.economy.rebootZone else { throw GameError.locked }
        profile.unlockedSquadCapacity = profile.squadCapacity
        profile.reboots += 1; profile.zone = 0; profile.buildingLevels = [:]; profile.robotLevels = [:]
        profile.scrap = 350; profile.credits = 500
    }
    public static func achievements(_ profile: PlayerProfile, content: GameContent) -> [String: Double] {
        ["firstfusion": min(100, Double(profile.blueprints.count) * 100),
         "madscientist": min(100, Double(profile.blueprints.count) / 25 * 100),
         "scrapengineer": min(100, Double(profile.blueprints.count) / 100 * 100),
         "swarmbreaker": min(100, Double(profile.kills) / 10000 * 100),
         "bossbreaker": min(100, Double(profile.bosses)),
         "mythicengineer": content.weapons.contains(where: { $0.rarity == .mythic && profile.weapons[$0.id, default: 0] > 0 }) ? 100 : 0]
    }
}
