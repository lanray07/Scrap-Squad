import Foundation
import Testing
@testable import ScrapCore

private func enemy(_ id: Int, at position: Vector = Vector(0.5, 0.5)) -> Enemy {
    Enemy(id: id, position: position, health: 100, maxHealth: 100, kind: "tank")
}
private func recover(_ system: SalvageSystem, count: Int, operation: inout SalvageOperation) {
    operation.target(system)
    for id in 1...count {
        operation.strike(enemy: enemy(id), amount: 30, time: 0)
        operation.advance(delta: 0.05, time: 0, player: Vector(0.5, 0.5), enemies: [])
    }
}
@Test func selectedComponentsBreakOnceAndExpireWithoutRemoteCollection() {
    var operation = SalvageOperation()
    let target = enemy(1)
    operation.strike(enemy: target, amount: 10, time: 0)
    #expect(operation.drops.isEmpty)
    #expect(operation.systemFraction(enemyID: 1, maxHealth: 100) < 1)
    operation.strike(enemy: target, amount: 20, time: 1)
    operation.strike(enemy: target, amount: 100, time: 1)
    #expect(operation.drops.count == 1 && operation.disabled[1] == [.weapon])
    operation.target(.drive); operation.strike(enemy: target, amount: 30, time: 1)
    #expect(operation.drops.map(\.system) == [.weapon, .drive])
    operation.advance(delta: 0.05, time: 2, player: Vector(0.1, 0.1), enemies: [target])
    #expect(operation.recovered == 0)
    operation.advance(delta: 0.05, time: 26, player: Vector(0.5, 0.5), enemies: [])
    #expect(operation.recovered == 0 && operation.drops.isEmpty && operation.disabled.isEmpty)
}
@Test func rebuildingConsumesPartsValidatesRobotAndAppliesTradeoffs() {
    var operation = SalvageOperation()
    #expect(!operation.install(.weapon, robotID: "bolt", squad: ["bolt"]))
    recover(.weapon, count: 3, operation: &operation)
    #expect(!operation.install(.weapon, robotID: "invalid", squad: ["bolt"]))
    #expect(operation.install(.weapon, robotID: "bolt", squad: ["bolt"]))
    #expect(operation.inventory[.weapon] == 1 && operation.damageScale == 1.3 && operation.movementScale == 0.9)
    #expect(!operation.install(.weapon, robotID: "bolt", squad: ["bolt"]))
    recover(.armor, count: 2, operation: &operation)
    #expect(operation.install(.armor, robotID: "bolt", squad: ["bolt"]))
    #expect(operation.damageScale == 1 && operation.attackScale == 0.85 && operation.incomingScale == 0.75)
    #expect(operation.inventory[.weapon] == 1 && operation.inventory[.armor] == 0)
}
@Test func extractionRequiresRescueRebuildEscortAndUncontestedHold() {
    var operation = SalvageOperation()
    for _ in 0..<400 { operation.advance(delta: 0.05, time: 1, player: operation.extraction, enemies: []) }
    #expect(!operation.extracted && operation.extractionProgress == 0)
    recover(.weapon, count: 3, operation: &operation)
    #expect(operation.install(.weapon, robotID: "bolt", squad: ["bolt"]))
    operation.advance(delta: 0.05, time: 1, player: operation.escort, enemies: [])
    #expect(operation.rescued && operation.readyForExtraction)
    for _ in 0..<400 { operation.advance(delta: 0.05, time: 1, player: operation.extraction, enemies: [enemy(20, at: operation.extraction)]) }
    #expect(operation.contested && operation.extractionProgress == 0)
    for _ in 0..<260 { operation.advance(delta: 0.05, time: 1, player: operation.extraction, enemies: []) }
    #expect(operation.extracted && operation.report == SalvageReport(recovered: 3, rebuilt: 1, rescued: true, extracted: true))
}
@Test @MainActor func salvageIsOptInAndCannotAlterVersionedChallengesOrLegacyModes() throws {
    let content = try GameContent.bundled(), profile = PlayerProfile()
    #expect(BattleEngine(content: content, profile: profile, mode: .scrapRun).salvage == nil)
    #expect(BattleEngine(content: content, profile: profile, mode: .campaign, salvageEnabled: true).salvage == nil)
    #expect(BattleEngine(content: content, profile: profile, mode: .scrapRun, challengeCode: RunChallenge(seed: 1).code, salvageEnabled: true).salvage == nil)
    let engine = BattleEngine(content: content, profile: profile, mode: .scrapRun, seed: 42, salvageEnabled: true)
    #expect(engine.openRebuild())
    let time = engine.elapsed
    engine.step(delta: 0.05, movement: Vector(1, 0))
    #expect(engine.elapsed == time && engine.player == Vector(0.5, 0.5))
    #expect(!engine.rebuild(.armor, robotID: "bolt"))
    engine.closeRebuild(); engine.step(delta: 0.05)
    #expect(engine.elapsed > time)
    engine.retreat(); #expect(!engine.openRebuild() && engine.state == .defeated)
}
@Test @MainActor func realCombatYieldsPartsAndOperationCanBeCompletedWithoutPremiumContent() throws {
    let content = try GameContent.bundled()
    let engine = BattleEngine(content: content, profile: PlayerProfile(), mode: .scrapRun, seed: 42, salvageEnabled: true)
    for _ in 0..<3000 {
        if engine.state == .choosing { engine.choose(engine.choices[0]) }
        guard engine.state == .fighting, let operation = engine.salvage else { break }
        if operation.rebuilds == 0 && operation.inventory[.weapon, default: 0] >= 2 {
            #expect(engine.openRebuild()); #expect(engine.rebuild(.weapon, robotID: engine.profile.squad[0])); engine.closeRebuild()
        }
        let destination: Vector
        if !operation.rescued { destination = operation.escort }
        else if !operation.readyForExtraction, let drop = operation.drops.min(by: { ($0.position - engine.player).length < ($1.position - engine.player).length }) { destination = drop.position }
        else if operation.readyForExtraction { destination = operation.extraction }
        else { destination = engine.player + Vector(cos(engine.elapsed * 0.5), sin(engine.elapsed * 0.5)) * 0.1 }
        engine.step(delta: 0.05, movement: (destination - engine.player).length > 0.02 ? destination - engine.player : Vector())
    }
    #expect(engine.salvage?.recovered ?? 0 >= 3)
    #expect(engine.salvage?.rebuilds == 1)
    #expect(engine.state == .victory)
    #expect(engine.reward().bonusScrap >= 100)
    var profile = PlayerProfile()
    #expect(Progression.apply(engine.reward(), profile: &profile, content: content, now: Date()))
    #expect(!Progression.apply(engine.reward(), profile: &profile, content: content, now: Date()))
    #expect(profile.journal?.recent.first?.highlights.salvage?.extracted == true)
    try profile.validate(content: content)
}
@Test func legacyRunHighlightsDecodeWithoutSalvageFields() throws {
    let value = RunHighlights(weaponID: "blaster", elapsed: 5, bestCombo: 0, overdrives: 0, synergies: [], challengeCode: nil)
    var json = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(value)) as? [String: Any])
    json.removeValue(forKey: "salvage")
    let decoded = try JSONDecoder().decode(RunHighlights.self, from: JSONSerialization.data(withJSONObject: json))
    #expect(decoded.salvage == nil)
}
