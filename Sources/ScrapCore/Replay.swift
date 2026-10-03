import Foundation

/// A versioned, offline challenge. No player identifiers or paid progression enter the loadout.
public struct RunChallenge: Sendable, Equatable, Identifiable {
    public let seed: UInt32
    public var id: String { code }
    public var code: String { "SQS1-" + String(format: "%08X", seed) }
    public init(seed: UInt32) { self.seed = seed }
    public init?(code: String) {
        let normalized = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard normalized.count == 13, normalized.hasPrefix("SQS1-"),
              normalized.dropFirst(5).allSatisfy({ "0123456789ABCDEF".contains($0) }),
              let seed = UInt32(normalized.dropFirst(5), radix: 16) else { return nil }
        self.seed = seed
    }
    public static func daily(now: Date) -> Self {
        let day = UInt32(clamping: Int(max(0, now.timeIntervalSince1970 / 86_400)))
        return Self(seed: day &* 2_654_435_761 &+ 0x53515301)
    }
    public func profile(content: GameContent, preferences: Preferences) -> PlayerProfile {
        var result = PlayerProfile(now: Date(timeIntervalSince1970: 0))
        result.preferences = preferences
        result.zone = Int(seed) % min(3, content.biomes.count)
        let weapons = content.weapons.filter { $0.rarity == .rare }
        let weapon = weapons.isEmpty ? content.weapons[0] : weapons[Int(seed) % weapons.count]
        result.weapons = [weapon.id: 1]; result.equippedWeapon = weapon.id
        result.weaponLevels = [weapon.id: 3]
        result.robotLevels = ["bolt": 3, "patch": 3]
        result.dailyKey = code
        return result
    }
}

public struct ComboMeter: Sendable, Equatable {
    public private(set) var count = 0
    public private(set) var best = 0
    public private(set) var charge = 0.0
    public private(set) var overdrive = 0.0
    public private(set) var activations = 0
    public private(set) var grace = 0.0
    public init() {}
    public var multiplier: Int { 1 + min(4, count / 8) }
    public mutating func tick(_ delta: Double) {
        let dt = max(0, delta)
        grace = max(0, grace - dt)
        overdrive = max(0, overdrive - dt)
        if grace == 0 { count = 0; charge = max(0, charge - dt * 0.025) }
    }
    public mutating func register(kills: Int) {
        guard kills > 0 else { return }
        count += kills; best = max(best, count); grace = 3.5
        if overdrive == 0 { charge = min(1, charge + Double(kills) * 0.09) }
    }
    @discardableResult public mutating func activate() -> Bool {
        guard charge >= 1, overdrive == 0 else { return false }
        charge = 0; overdrive = 6; activations += 1
        return true
    }
}

public enum BuildSynergy: String, Codable, CaseIterable, Identifiable, Sendable {
    case thermalShock, stormLattice, perfectStorm
    public var id: String { rawValue }
    public var nameKey: String { "synergy." + rawValue }
    public var detailKey: String { nameKey + ".detail" }
    public var requirements: Set<String> {
        switch self {
        case .thermalShock: ["burn", "freeze"]
        case .stormLattice: ["chain", "split"]
        case .perfectStorm: ["critical", "speed"]
        }
    }
    public func ready(kinds: Set<String>) -> Bool { requirements.isSubset(of: kinds) }
}

public enum RunMedal: String, Codable, CaseIterable, Identifiable, Sendable {
    case bossBreaker, comboAce, survivor, inventor
    public var id: String { rawValue }
    public var nameKey: String { "medal." + rawValue }
    public var symbol: String {
        switch self {
        case .bossBreaker: "crown.fill"
        case .comboAce: "flame.fill"
        case .survivor: "shield.fill"
        case .inventor: "atom"
        }
    }
}
public struct RunHighlights: Codable, Sendable {
    public let weaponID: String
    public let elapsed: Double
    public let bestCombo: Int
    public let overdrives: Int
    public let synergies: [BuildSynergy]
    public let challengeCode: String?
    public init(weaponID: String, elapsed: Double, bestCombo: Int, overdrives: Int, synergies: [BuildSynergy], challengeCode: String?) {
        self.weaponID = weaponID; self.elapsed = elapsed; self.bestCombo = bestCombo
        self.overdrives = overdrives; self.synergies = synergies; self.challengeCode = challengeCode
    }
}
public struct RunRecord: Codable, Sendable, Identifiable {
    public let id: UUID
    public let date: Date
    public let mode: GameMode
    public let zone: Int
    public let score: Int
    public let kills: Int
    public let bosses: Int
    public let victory: Bool
    public let highlights: RunHighlights
    public var medals: [RunMedal] {
        var result: [RunMedal] = []
        if bosses > 0 { result.append(.bossBreaker) }
        if highlights.bestCombo >= 16 { result.append(.comboAce) }
        if victory { result.append(.survivor) }
        if !highlights.synergies.isEmpty { result.append(.inventor) }
        return result
    }
    public init(reward: RunReward, highlights: RunHighlights, date: Date) {
        id = reward.id; self.date = date; mode = reward.mode; zone = reward.zone
        score = reward.score; kills = reward.kills; bosses = reward.bosses
        victory = reward.victory; self.highlights = highlights
    }
}
public struct RunJournal: Codable, Sendable {
    public private(set) var recent: [RunRecord] = []
    public private(set) var bestScores: [String: Int] = [:]
    public private(set) var bestCombo = 0
    public private(set) var discoveredSynergies: Set<BuildSynergy> = []
    public private(set) var medals: Set<RunMedal> = []
    public init() {}
    public mutating func record(_ run: RunRecord) {
        guard !recent.contains(where: { $0.id == run.id }) else { return }
        recent.insert(run, at: 0); recent = Array(recent.prefix(30))
        bestScores[run.mode.rawValue] = max(bestScores[run.mode.rawValue, default: 0], run.score)
        bestCombo = max(bestCombo, run.highlights.bestCombo)
        discoveredSynergies.formUnion(run.highlights.synergies); medals.formUnion(run.medals)
    }
}

public enum MasteryMilestone: String, CaseIterable, Identifiable, Sendable {
    case firstSteps, tinkerer, bossHunter, comboArtist, synergySeeker, veteran
    public var id: String { rawValue }
    public var nameKey: String { "mastery." + rawValue }
    public var goal: Int {
        switch self {
        case .firstSteps: 3
        case .tinkerer: 6
        case .bossHunter: 3
        case .comboArtist: 16
        case .synergySeeker: 3
        case .veteran: 25
        }
    }
    public func progress(_ profile: PlayerProfile) -> Int {
        let value: Int
        switch self {
        case .firstSteps, .veteran: value = profile.completedRuns
        case .tinkerer: value = profile.blueprints.count
        case .bossHunter: value = profile.bosses
        case .comboArtist: value = profile.journal?.bestCombo ?? 0
        case .synergySeeker: value = profile.journal?.discoveredSynergies.count ?? 0
        }
        return min(goal, max(0, value))
    }
}
