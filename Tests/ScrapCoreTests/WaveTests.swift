import Foundation
import Testing
@testable import ScrapCore

private func waveReviewFixture(damage: Double = 0, interval: Double = 0.65) throws -> GameContent {
    var json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(GameContent.bundled())) as! [String: Any]
    var weapons = json["weapons"] as! [[String: Any]]
    weapons[0]["damage"] = damage; weapons[0]["interval"] = interval; json["weapons"] = weapons
    var economy = json["economy"] as! [String: Any]; economy["upgradeSeconds"] = [Double](); json["economy"] = economy
    return try JSONDecoder().decode(GameContent.self, from: JSONSerialization.data(withJSONObject: json))
}
private func waveReviewProfile() -> PlayerProfile {
    var p = PlayerProfile(); p.squad = ["bolt"]; p.robotLevels = ["bolt": 100000]; p.zone = 1; return p
}
@Test @MainActor func waveReviewEndlessContinuesPastSix() throws {
    let content = try waveReviewFixture()
    for mode in [GameMode.survival, .arena] {
        let engine = BattleEngine(content: content, profile: waveReviewProfile(), mode: mode, seed: 42)
        for _ in 0..<3000 { engine.step(delta: 0.05) }
        print("Wave review: \(mode) time=\(engine.elapsed) wave=\(engine.wave) state=\(engine.state)")
        #expect(engine.state == .fighting)
        #expect(engine.wave == 8)
    }
}
@Test @MainActor func waveReviewBossRushRequiresAllThreeBosses() throws {
    let content = try waveReviewFixture(damage: 100000, interval: 10000)
    let engine = BattleEngine(content: content, profile: waveReviewProfile(), mode: .bossRush, seed: 42)
    for _ in 0..<2410 { engine.step(delta: 0.05) }
    print("Wave review: Boss Rush time=\(engine.elapsed) bosses=\(engine.bosses) state=\(engine.state)")
    #expect(engine.bosses == 1)
    #expect(engine.state == .fighting)
    #expect(engine.bossHealth != nil)
}
@Test @MainActor func waveReviewBossSpawnRespectsEnemyLimit() throws {
    let content = try waveReviewFixture()
    let engine = BattleEngine(content: content, profile: waveReviewProfile(), mode: .survival, seed: 42)
    var peak = 0
    for _ in 0..<1400 { engine.step(delta: 0.05); peak = max(peak, engine.enemies.count) }
    print("Wave review: peak enemies=\(peak), boss spawned=\(engine.bossSpawned)")
    #expect(engine.bossSpawned)
    #expect(engine.enemies.filter(\.boss).count == 1)
    #expect(peak == 80)
}
@Test @MainActor func waveReviewUpgradeSelectionFreezesWaveAndSpawning() throws {
    let content = try GameContent.bundled()
    let engine = BattleEngine(content: content, profile: waveReviewProfile(), mode: .survival, seed: 42)
    for _ in 0..<401 { engine.step(delta: 0.05) }
    #expect(engine.state == .choosing)
    let time = engine.elapsed, wave = engine.wave, count = engine.enemies.count
    for _ in 0..<1000 { engine.step(delta: 0.05) }
    #expect(engine.elapsed == time && engine.wave == wave && engine.enemies.count == count)
    engine.choose(try #require(engine.choices.first)); engine.step(delta: 0.05)
    #expect(engine.elapsed > time && engine.state == .fighting)
}
@Test @MainActor func waveReviewNormalTwentySecondProgressionAndDeterministicSpawns() throws {
    let content = try waveReviewFixture()
    let a = BattleEngine(content: content, profile: waveReviewProfile(), mode: .campaign, seed: 42)
    let b = BattleEngine(content: content, profile: waveReviewProfile(), mode: .campaign, seed: 42)
    var seen = Set<Int>(), checkpoints: [(Double, Int, Int)] = []
    #expect(a.wave == 1)
    for tick in 1...2001 {
        a.step(delta: 0.05); b.step(delta: 0.05)
        seen.formUnion(a.enemies.map(\.id))
        if tick % 400 == 1 { checkpoints.append((a.elapsed, a.wave, seen.count)) }
        #expect(a.wave == b.wave && a.enemies.map(\.id) == b.enemies.map(\.id))
    }
    #expect(checkpoints.map { $0.1 } == [1, 2, 3, 4, 5, 6])
    #expect(checkpoints.last!.2 > checkpoints.first!.2)
    print("Wave review: normal checkpoints (time, wave, spawned)=\(checkpoints)")
}

@Test @MainActor func waveReviewBossRushCompletesAfterThirdBossAndStopsSpawning() throws {
    let content = try waveReviewFixture(damage: 100000)
    let engine = BattleEngine(content: content, profile: waveReviewProfile(), mode: .bossRush, seed: 42)
    for _ in 0..<200 { engine.step(delta: 0.05) }
    #expect(engine.state == .victory && engine.bosses == 3)
    #expect(engine.enemies.isEmpty && engine.reward().victory)
    let time = engine.elapsed
    for _ in 0..<100 { engine.step(delta: 0.05) }
    #expect(engine.elapsed == time && engine.bosses == 3 && engine.enemies.isEmpty)
}

@Test @MainActor func waveReviewTimedModesRetainTwoMinuteDeadlineAndSixWaveCap() throws {
    let content = try waveReviewFixture()
    for mode in [GameMode.campaign, .scrapRun, .fusionLab, .dailyAnomaly] {
        let engine = BattleEngine(content: content, profile: waveReviewProfile(), mode: mode, seed: 42)
        for _ in 0..<2410 { engine.step(delta: 0.05) }
        #expect(engine.elapsed >= 120 && engine.elapsed < 120.1)
        #expect(engine.wave == 6 && engine.state == .defeated && engine.bosses == 0)
    }
}
