import Foundation
import Testing
@testable import ScrapCore

@Test func challengeCodesRoundTripAndRejectOtherVersions() {
    for seed: UInt32 in [0, 1, 123_456, UInt32.max] {
        let challenge = RunChallenge(seed: seed)
        #expect(RunChallenge(code: challenge.code.lowercased()) == challenge)
    }
    for code in ["SQS2-1234ABCD", "SQS1-1234567", "SQS1-12345XYZ", "SQS1-1234ABCDextra", ""] {
        #expect(RunChallenge(code: code) == nil)
    }
}
@Test func dailyCircuitRotatesAtUTCMidnightAndIgnoresPurchasedProgress() throws {
    let content = try GameContent.bundled()
    let before = Date(timeIntervalSince1970: 86_399)
    let same = Date(timeIntervalSince1970: 1)
    let after = Date(timeIntervalSince1970: 86_400)
    #expect(RunChallenge.daily(now: before) == RunChallenge.daily(now: same))
    #expect(RunChallenge.daily(now: before) != RunChallenge.daily(now: after))
    for seed: UInt32 in [0, 1, 500, UInt32.max] {
        let profile = RunChallenge(seed: seed).profile(content: content, preferences: Preferences())
        try profile.validate(content: content)
        #expect(profile.reboots == 0 && profile.buildingLevels.isEmpty)
        #expect(profile.squad == ["bolt", "patch"])
        #expect(profile.weaponLevels[profile.equippedWeapon] == 3)
    }
}
@Test func comboChargesExpiresAndCannotStackOverdrive() {
    var combo = ComboMeter()
    #expect(!combo.activate())
    combo.register(kills: 16)
    #expect(combo.best == 16 && combo.multiplier == 3 && combo.charge == 1)
    #expect(combo.activate())
    combo.register(kills: 10)
    #expect(!combo.activate() && combo.charge == 0 && combo.activations == 1)
    combo.tick(7)
    #expect(combo.count == 0 && combo.overdrive == 0 && combo.best == 26)
    combo.register(kills: 12)
    #expect(combo.activate() && combo.activations == 2)
}
@Test func synergyRequirementsAreDistinctAndPresentInContent() throws {
    let content = try GameContent.bundled()
    let kinds = Set(content.upgrades.map(\.kind))
    for synergy in BuildSynergy.allCases {
        #expect(synergy.requirements.count == 2)
        #expect(synergy.requirements.isSubset(of: kinds))
        #expect(synergy.ready(kinds: synergy.requirements))
        #expect(!synergy.ready(kinds: [synergy.requirements.first!]))
    }
}
@Test func journalMigrationRewardsIdempotencyAndBoundedHistory() throws {
    let content = try GameContent.bundled()
    var profile = PlayerProfile()
    var legacy = try JSONSerialization.jsonObject(with: JSONEncoder().encode(profile)) as! [String: Any]
    legacy.removeValue(forKey: "journal")
    let migrated = try JSONDecoder().decode(PlayerProfile.self, from: JSONSerialization.data(withJSONObject: legacy))
    #expect(migrated.journal == nil)
    let highlights = RunHighlights(weaponID: "blaster", elapsed: 120, bestCombo: 20, overdrives: 2, synergies: [.thermalShock], challengeCode: "SQS1-00000001")
    for score in 0..<35 {
        let reward = RunReward(id: UUID(), mode: .dailyAnomaly, zone: 0, kills: 20, bosses: 1, score: score, victory: true, highlights: highlights)
        #expect(Progression.apply(reward, profile: &profile, content: content, now: Date()))
        #expect(!Progression.apply(reward, profile: &profile, content: content, now: Date()))
    }
    let decoded = try JSONDecoder().decode(PlayerProfile.self, from: JSONEncoder().encode(profile))
    #expect(decoded.journal?.recent.count == 30)
    #expect(decoded.journal?.bestScores[GameMode.dailyAnomaly.rawValue] == 34)
    #expect(decoded.journal?.medals.count == 4)
    #expect(decoded.journal?.discoveredSynergies == [.thermalShock])
    #expect(MasteryMilestone.veteran.progress(decoded) == 25)
    #expect(MasteryMilestone.comboArtist.progress(decoded) == 16)
}
@Test @MainActor func circuitEnginesShareOpeningAndReplayHighlights() throws {
    let content = try GameContent.bundled()
    let challenge = RunChallenge(seed: 42)
    let profile = challenge.profile(content: content, preferences: Preferences())
    let first = BattleEngine(content: content, profile: profile, mode: .dailyAnomaly, seed: 42, challengeCode: challenge.code)
    let second = BattleEngine(content: content, profile: profile, mode: .dailyAnomaly, seed: 42, challengeCode: challenge.code)
    for _ in 0..<100 {
        first.step(delta: 0.05); second.step(delta: 0.05)
    }
    #expect(first.kills == second.kills && first.health == second.health && first.score == second.score)
    #expect(first.enemies.map(\.position) == second.enemies.map(\.position))
    first.retreat()
    #expect(!first.activateOverdrive())
    #expect(first.reward().highlights?.challengeCode == challenge.code)
}
