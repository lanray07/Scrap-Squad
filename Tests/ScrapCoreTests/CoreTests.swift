import Foundation
import Testing
@testable import ScrapCore

@Test func contentIntegrity() throws {
    let content = try GameContent.bundled()
    #expect(content.recipes.count == 12)
    #expect(content.robots.count == 8)
    #expect(content.biomes.count == 9)
    try content.validate()
}
@Test func fusionIsAtomicAndUnlocksBlueprint() throws {
    let content = try GameContent.bundled()
    var profile = PlayerProfile()
    let recipe = content.recipes[0]
    let original = profile.scrap
    try Progression.fuse(recipe, profile: &profile)
    #expect(profile.scrap == original - recipe.scrapCost)
    #expect(profile.weapons[recipe.result] == 1)
    #expect(profile.blueprints.contains(recipe.id))
    profile.components[recipe.component] = 0
    let before = profile.scrap
    #expect(throws: GameError.missingIngredient) { try Progression.fuse(recipe, profile: &profile) }
    #expect(profile.scrap == before)
}
@Test func offlineCapAndClockRollback() throws {
    let content = try GameContent.bundled()
    let origin = Date(timeIntervalSince1970: 100000)
    var profile = PlayerProfile(now: origin)
    #expect(!Progression.offline(profile: profile, content: content, now: origin.addingTimeInterval(99999)).isAvailable)
    profile.buildingLevels["dock"] = 1
    let capped = Progression.claimOffline(&profile, content: content, now: origin.addingTimeInterval(24 * 3600))
    #expect(capped.seconds == 8 * 3600)
    #expect(capped.scrap == 960)
    #expect(!Progression.claimOffline(&profile, content: content, now: origin.addingTimeInterval(24 * 3600)).isAvailable)
    #expect(!Progression.claimOffline(&profile, content: content, now: origin).isAvailable)
    #expect(profile.lastSeen == origin.addingTimeInterval(24 * 3600))
}
@Test func rouletteConsumesOnlyValidIngredients() throws {
    let content = try GameContent.bundled()
    var profile = PlayerProfile()
    #expect(Progression.rouletteCandidates(a: "blaster", b: "blaster", content: content).isEmpty)
    let candidates = Progression.rouletteCandidates(a: "blaster", b: "rocket", content: content)
    #expect(!candidates.isEmpty)
    let result = try Progression.roulette(a: "blaster", b: "rocket", profile: &profile, content: content, randomIndex: 0)
    #expect(profile.cores == 2)
    #expect(profile.weapons["rocket"] == 0)
    #expect(profile.weapons[result.id] == 1)
    let snapshot = profile.cores
    #expect(throws: GameError.missingIngredient) { try Progression.roulette(a: "blaster", b: "rocket", profile: &profile, content: content, randomIndex: 0) }
    #expect(profile.cores == snapshot)
}
@Test func runRewardsCannotBeClaimedTwice() throws {
    let content = try GameContent.bundled()
    var profile = PlayerProfile()
    let reward = RunReward(id: UUID(), mode: .campaign, zone: 0, kills: 10, bosses: 1, score: 1000, victory: true)
    #expect(Progression.apply(reward, profile: &profile, content: content, now: Date()))
    let credits = profile.credits
    #expect(!Progression.apply(reward, profile: &profile, content: content, now: Date()))
    #expect(profile.credits == credits)
    #expect(profile.zone == 1)
    #expect(profile.kills == 10)
}
@Test func squadNeverEmptyOrOverCapacity() throws {
    var profile = PlayerProfile()
    try Progression.toggleSquad("patch", profile: &profile)
    #expect(throws: GameError.invalidSelection) { try Progression.toggleSquad("bolt", profile: &profile) }
    profile.unlockedRobots.formUnion(["tank", "zip"])
    try Progression.toggleSquad("tank", profile: &profile)
    #expect(throws: GameError.invalidSelection) { try Progression.toggleSquad("zip", profile: &profile) }
}
@Test func rebootPreservesCollection() throws {
    let content = try GameContent.bundled()
    var profile = PlayerProfile()
    profile.zone = 5; profile.blueprints = ["flame"]; profile.buildingLevels["dock"] = 2
    profile.weaponLevels["blaster"] = 3
    profile.unlockedRobots.formUnion(["tank", "zip"])
    profile.squad = ["bolt", "patch", "tank", "zip"]
    profile.buildingLevels["command"] = 4
    try Progression.reboot(&profile, content: content)
    #expect(profile.zone == 0 && profile.reboots == 1)
    #expect(profile.blueprints.contains("flame"))
    #expect(profile.weaponLevels["blaster"] == 3)
    #expect(profile.buildingLevels.isEmpty)
    #expect(profile.squadCapacity == 4 && profile.squad.count == 4)
    try profile.validate(content: content)
}
@Test func missionsHaveNoStreakDependency() throws {
    var profile = PlayerProfile()
    let now = Date(timeIntervalSince1970: 1700000000)
    Progression.refreshMissions(&profile, now: now)
    profile.dailyKills = 60
    try Progression.claimMission(weekly: false, profile: &profile, now: now)
    #expect(throws: GameError.locked) { try Progression.claimMission(weekly: false, profile: &profile, now: now) }
    Progression.refreshMissions(&profile, now: now.addingTimeInterval(10 * 86400))
    #expect(profile.dailyKills == 0 && !profile.dailyClaimed)
}
@Test @MainActor func deterministicCombatAndUpgradePause() throws {
    let content = try GameContent.bundled()
    let profile = PlayerProfile()
    let a = BattleEngine(content: content, profile: profile, mode: .campaign, seed: 42)
    let b = BattleEngine(content: content, profile: profile, mode: .campaign, seed: 42)
    for _ in 0..<500 {
        a.step(delta: 0.05); b.step(delta: 0.05)
    }
    #expect(a.kills == b.kills && a.health == b.health)
    #expect(a.state == .choosing)
    let elapsed = a.elapsed
    a.step(delta: 1)
    #expect(a.elapsed == elapsed)
    #expect(a.choices.count == 3)
    a.choose(a.choices[0])
    #expect(a.state == .fighting)
    a.retreat()
    #expect(a.state == .defeated)
}
@Test func saveRoundTrip() throws {
    var profile = PlayerProfile(now: Date(timeIntervalSince1970: 1000))
    profile.blueprints = ["arc", "chain"]
    let data = try JSONEncoder().encode(profile)
    let loaded = try JSONDecoder().decode(PlayerProfile.self, from: data)
    #expect(loaded.blueprints == profile.blueprints)
    #expect(loaded.lastSeen == profile.lastSeen)
}
@Test func dockDoesNotGrantRetroactiveIncome() throws {
    let content = try GameContent.bundled()
    let past = Date(timeIntervalSince1970: 100000)
    let now = past.addingTimeInterval(86400)
    var profile = PlayerProfile(now: past)
    let dock = content.buildings.first { $0.id == "dock" }!
    try Progression.upgradeBuilding(dock, profile: &profile, content: content, now: now)
    #expect(!Progression.offline(profile: profile, content: content, now: now).isAvailable)
    #expect(Progression.offline(profile: profile, content: content, now: now.addingTimeInterval(60)).scrap == 2)
}
@Test @MainActor func completeCampaignRewardsVictory() throws {
    let content = try GameContent.bundled()
    var profile = PlayerProfile()
    profile.equippedWeapon = "singularity"
    profile.squad = ["bolt", "tank", "patch", "nova"]
    profile.robotLevels = ["bolt": 50, "tank": 50, "patch": 50, "nova": 50]
    let engine = BattleEngine(content: content, profile: profile, mode: .campaign, seed: 101)
    for _ in 0..<2500 {
        if engine.state == .choosing { engine.choose(engine.choices[0]) }
        engine.step(delta: 0.05, movement: Vector(cos(engine.elapsed), sin(engine.elapsed)))
    }
    #expect(engine.state == .victory)
    #expect(engine.bosses == 1)
    #expect(engine.reward().victory)
}
@Test @MainActor func abilityCooldownPreventsRepeatedHealing() throws {
    let content = try GameContent.bundled()
    var profile = PlayerProfile(); profile.squad = ["patch", "bolt"]
    let engine = BattleEngine(content: content, profile: profile, mode: .survival, seed: 10)
    engine.activateAbility()
    let health = engine.health
    #expect(engine.abilityCooldown == 18)
    engine.activateAbility()
    #expect(engine.health == health && engine.abilityCooldown == 18)
}
@Test func corruptedProfileRejected() throws {
    let content = try GameContent.bundled()
    var profile = PlayerProfile()
    try profile.validate(content: content)
    profile.squad = []
    #expect(throws: GameError.invalidContent) { try profile.validate(content: content) }
    profile = PlayerProfile(); profile.scrap = -1
    #expect(throws: GameError.invalidContent) { try profile.validate(content: content) }
    profile = PlayerProfile(); profile.equippedWeapon = "unknown"
    #expect(throws: GameError.invalidContent) { try profile.validate(content: content) }
}
