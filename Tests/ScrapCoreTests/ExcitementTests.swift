import Foundation
import Testing
@testable import ScrapCore

private func excitementContent(damage: Double = 10, upgrades: [Double] = [0.1, 0.2]) throws -> GameContent {
    var json = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(GameContent.bundled())) as? [String: Any])
    var weapons = try #require(json["weapons"] as? [[String: Any]])
    weapons[0]["damage"] = damage; weapons[0]["interval"] = 10000
    json["weapons"] = weapons
    var economy = try #require(json["economy"] as? [String: Any])
    economy["upgradeSeconds"] = upgrades; json["economy"] = economy
    return try JSONDecoder().decode(GameContent.self, from: JSONSerialization.data(withJSONObject: json))
}
private func excitementProfile() -> PlayerProfile {
    var profile = PlayerProfile(); profile.zone = 1; profile.squad = ["bolt"]; profile.robotLevels = ["bolt": 100000]
    return profile
}
@MainActor private func evolve(_ engine: BattleEngine, into evolution: RunEvolution) throws {
    for _ in 0..<5 where engine.state != .choosing { engine.step(delta: 0.05) }
    let firstKind = evolution == .fireVortex ? "burn" : evolution == .stormCage ? "chain" : "explosion"
    engine.choose(try #require(engine.choices.first { $0.kind == firstKind }))
    #expect(engine.evolution == nil)
    for _ in 0..<5 where engine.state != .choosing { engine.step(delta: 0.05) }
    let second = try #require(engine.choices.first { evolution.requirements.contains($0.kind) && $0.kind != firstKind })
    engine.choose(second)
    #expect(engine.evolution == evolution)
}

@Test @MainActor func evolutionsUnlockThroughRealChoicesAndDealDistinctBoundedDamage() throws {
    let content = try excitementContent()
    for evolution in RunEvolution.allCases {
        let engine = BattleEngine(content: content, profile: excitementProfile(), mode: .survival, seed: 42)
        try evolve(engine, into: evolution)
        var evolvedHits = 0
        for _ in 0..<500 {
            engine.step(delta: 0.05)
            evolvedHits += engine.effects.filter { $0.damage > 0 }.count
            #expect(engine.evolutionStrikes.count <= 12 && engine.projectiles.count <= 48 && engine.enemies.count <= 80)
        }
        #expect(evolvedHits > 0 && engine.weapon.id == "blaster")
        #expect(engine.reward().highlights?.evolution == evolution)
        #expect(BattleEngine(content: content, profile: excitementProfile(), mode: .survival, seed: 42).evolution == nil)
    }
}
@Test @MainActor func siegeBarrageWarnsBeforeDamageAndFreezesAtChoice() throws {
    let content = try excitementContent(upgrades: [0.1, 0.2, 0.4])
    let engine = BattleEngine(content: content, profile: excitementProfile(), mode: .survival, seed: 42)
    try evolve(engine, into: .siegeBarrage)
    engine.step(delta: 0.05)
    #expect(!engine.evolutionStrikes.isEmpty && engine.effects.allSatisfy { $0.style != .orbital })
    for _ in 0..<5 where engine.state != .choosing { engine.step(delta: 0.05) }
    let remaining = engine.evolutionStrikes.map(\.remaining)
    for _ in 0..<100 { engine.step(delta: 0.05) }
    #expect(engine.state == .choosing && engine.evolutionStrikes.map(\.remaining) == remaining)
    engine.choose(try #require(engine.choices.first))
    for _ in 0..<20 { engine.step(delta: 0.05) }
    #expect(engine.effects.contains { $0.style == .orbital && $0.damage > 0 })
}
@Test @MainActor func dashEscapesImminentRealBossWarningAndRewardsOnce() throws {
    let content = try excitementContent(upgrades: [])
    let engine = BattleEngine(content: content, profile: excitementProfile(), mode: .bossRush, seed: 42)
    for _ in 0..<200 where !engine.warnings.contains(where: { $0.remaining <= 0.25 && $0.area.contains(engine.player) }) { engine.step(delta: 0.05) }
    #expect(engine.warnings.contains { $0.remaining <= 0.25 && $0.area.contains(engine.player) })
    let health = engine.health, start = engine.player
    #expect(engine.activateDash(direction: Vector(1, 0)))
    #expect(!engine.activateDash(direction: Vector(1, 0)))
    for _ in 0..<7 { engine.step(delta: 0.05) }
    #expect(engine.player.x > start.x + 0.25 && engine.player.x <= 0.93)
    #expect(engine.health == health && engine.perfectDodges == 1 && engine.perfectDodgeBoost > 0)
    for _ in 0..<100 { engine.step(delta: 0.05) }
    #expect(engine.dashCooldown == 0 && engine.perfectDodgeBoost == 0 && engine.perfectDodges == 1)
    engine.retreat(); #expect(!engine.activateDash())
}
@Test @MainActor func dashAndCooldownFreezeDuringUpgradeAndStayInsideArena() throws {
    let engine = BattleEngine(content: try excitementContent(upgrades: [0.1]), profile: excitementProfile(), mode: .survival, seed: 42)
    #expect(engine.activateDash(direction: Vector(1, 1)))
    for _ in 0..<3 { engine.step(delta: 0.05) }
    let position = engine.player, cooldown = engine.dashCooldown, remaining = engine.dashRemaining
    for _ in 0..<100 { engine.step(delta: 0.05) }
    #expect(engine.player == position && engine.dashCooldown == cooldown && engine.dashRemaining == remaining)
    #expect(!engine.activateDash())
    engine.choose(try #require(engine.choices.first))
    for _ in 0..<300 { engine.step(delta: 0.05, movement: Vector(1, 1)) }
    #expect(engine.player.x <= 0.93 && engine.player.y <= 0.93)
    #expect(!engine.activateDash(direction: Vector(1, 1)))
}
@Test @MainActor func threeSeededEventsRespectCapTimeoutsAndNoFreeCarrierKills() throws {
    let content = try excitementContent(damage: 0, upgrades: [])
    for (seed, kind) in [(UInt64(42), WaveEventKind.eliteAmbush), (43, .scrapStorm), (44, .treasureCarrier)] {
        let engine = BattleEngine(content: content, profile: excitementProfile(), mode: .survival, seed: seed)
        for _ in 0..<561 { engine.step(delta: 0.05) }
        let event = try #require(engine.waveEvent)
        #expect(event.kind == kind)
        #expect(event.enemyIDs.count == (kind == .eliteAmbush ? 3 : kind == .treasureCarrier ? 1 : 0))
        if kind == .scrapStorm { engine.step(delta: 0.05); #expect(engine.warnings.count >= 3) }
        for _ in 0..<260 { engine.step(delta: 0.05); #expect(engine.enemies.count <= 80 && engine.warnings.count <= 48) }
        #expect(engine.waveEvent == nil)
        #expect(engine.completedWaveEvents == (kind == .scrapStorm ? 1 : 0))
        #expect(engine.bonusScrap == (kind == .scrapStorm ? 40 : 0))
        #expect(engine.kills == 0 && !engine.enemies.contains { $0.kind == "treasure" })
    }
}
@Test @MainActor func successfulEliteEventPaysOnceAndRewardIsIdempotent() throws {
    let content = try excitementContent(damage: 100000, upgrades: [])
    // High damage plus a normal firing interval lets the actual event enemies be defeated.
    var json = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(content)) as? [String: Any])
    var weapons = try #require(json["weapons"] as? [[String: Any]]); weapons[0]["interval"] = 0.1; json["weapons"] = weapons
    let active = try JSONDecoder().decode(GameContent.self, from: JSONSerialization.data(withJSONObject: json))
    let engine = BattleEngine(content: active, profile: excitementProfile(), mode: .survival, seed: 42)
    for _ in 0..<700 { engine.step(delta: 0.05) }
    #expect(engine.completedWaveEvents == 1 && engine.bonusScrap == 60)
    var profile = excitementProfile(); let before = profile.scrap
    let reward = engine.reward()
    #expect(Progression.apply(reward, profile: &profile, content: active, now: Date()))
    #expect(profile.scrap == before + engine.kills * active.economy.killScrap + 60)
    let paid = profile.scrap
    #expect(!Progression.apply(reward, profile: &profile, content: active, now: Date()) && profile.scrap == paid)
    let saved = try JSONDecoder().decode(PlayerProfile.self, from: JSONEncoder().encode(profile))
    try saved.journal?.validate(content: active)
    #expect(saved.journal?.recent.first?.highlights.completedWaveEvents == 1)
    let carrier = BattleEngine(content: active, profile: excitementProfile(), mode: .survival, seed: 44)
    for _ in 0..<700 { carrier.step(delta: 0.05) }
    #expect(carrier.completedWaveEvents == 1 && carrier.bonusScrap == 40 && !carrier.enemies.contains { $0.kind == "treasure" })
}

@Test @MainActor func eventReplayIsDeterministicAndUpgradeFreezesItsCountdown() throws {
    let content = try excitementContent(damage: 0, upgrades: [29])
    let a = BattleEngine(content: content, profile: excitementProfile(), mode: .survival, seed: 44)
    let b = BattleEngine(content: content, profile: excitementProfile(), mode: .survival, seed: 44)
    for _ in 0..<585 { a.step(delta: 0.05); b.step(delta: 0.05) }
    let event = try #require(a.waveEvent)
    #expect(a.state == .choosing && a.elapsed == b.elapsed)
    #expect(event.kind == b.waveEvent?.kind && event.enemyIDs == b.waveEvent?.enemyIDs)
    #expect(a.enemies.map(\.position) == b.enemies.map(\.position))
    let positions = a.enemies.map(\.position), elapsed = a.elapsed
    for _ in 0..<400 { a.step(delta: 0.05) }
    #expect(a.elapsed == elapsed && a.waveEvent?.endsAt == event.endsAt && a.enemies.map(\.position) == positions)
    a.choose(try #require(a.choices.first)); a.step(delta: 0.05)
    #expect(a.elapsed > elapsed)
}

@Test func olderRunHighlightsDecodeWithoutNewCombatFields() throws {
    let old = RunHighlights(weaponID: "blaster", elapsed: 30, bestCombo: 2, overdrives: 0, synergies: [], challengeCode: nil)
    var json = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(old)) as? [String: Any])
    for key in ["evolution", "perfectDodges", "completedWaveEvents"] { json.removeValue(forKey: key) }
    let decoded = try JSONDecoder().decode(RunHighlights.self, from: JSONSerialization.data(withJSONObject: json))
    #expect(decoded.evolution == nil && decoded.perfectDodges == nil && decoded.completedWaveEvents == nil && decoded.weaponID == "blaster")
}
