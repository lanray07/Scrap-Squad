import Foundation
import Testing
@testable import ScrapCore

@Test func attackGeometryMatchesCirclesCapsulesAndRingSafeCenter() {
    let circle = AttackArea(shape: .circle, from: Vector(), to: Vector(0.5, 0.5), radius: 0.1)
    #expect(circle.contains(Vector(0.55, 0.5)))
    #expect(!circle.contains(Vector(0.7, 0.5)))
    let line = AttackArea(shape: .line, from: Vector(0.2, 0.5), to: Vector(0.8, 0.5), radius: 0.05)
    #expect(line.contains(Vector(0.5, 0.54)))
    #expect(line.contains(Vector(0.18, 0.5)))
    #expect(!line.contains(Vector(0.5, 0.60)))
    let ring = AttackArea(shape: .ring, from: Vector(), to: Vector(0.5, 0.5), radius: 0.25, thickness: 0.04)
    #expect(!ring.contains(Vector(0.5, 0.5)))
    #expect(ring.contains(Vector(0.75, 0.5)))
    #expect(!ring.contains(Vector(0.9, 0.5)))
}
@Test func allNineBossesHaveDistinctFiniteDodgeablePatterns() throws {
    let content = try GameContent.bundled()
    let patterns = content.biomes.map { BossPattern(biomeID: $0.id) }
    #expect(Set(patterns).count == 9)
    for pattern in patterns {
        for phase in [false, true] {
            let areas = pattern.areas(origin: Vector(0.5, 0.8), target: Vector(0.5, 0.5), enraged: phase, sequence: 2)
            #expect(!areas.isEmpty && areas.count <= 4)
            #expect(areas.allSatisfy { $0.radius.isFinite && $0.radius > 0 })
            let safe = (1..<10).contains { x in (1..<10).contains { y in !areas.contains { $0.contains(Vector(Double(x) / 10, Double(y) / 10)) } } }
            #expect(safe)
        }
    }
}
@Test @MainActor func shotsCannotEraseTheSwarmAtSpawnDistance() throws {
    let content = try GameContent.bundled()
    let engine = BattleEngine(content: content, profile: PlayerProfile(), mode: .campaign, seed: 42)
    engine.step(delta: 0.05)
    #expect(engine.enemies.count == 1 && engine.kills == 0)
    #expect(engine.effects.filter { $0.damage > 0 }.isEmpty)
    #expect((engine.enemies[0].position - engine.player).length > engine.weapon.range)
    for _ in 0..<100 { engine.step(delta: 0.05) }
    #expect(engine.effects.contains { $0.damage > 0 } || engine.kills > 0)
}
@Test @MainActor func guidedMissilesTravelBeforeDamageAndRemainBounded() throws {
    let content = try GameContent.bundled()
    var profile = PlayerProfile(); profile.equippedWeapon = "rocket"
    let engine = BattleEngine(content: content, profile: profile, mode: .campaign, seed: 42)
    for _ in 0..<30 where engine.projectiles.isEmpty { engine.step(delta: 0.05) }
    #expect(!engine.projectiles.isEmpty)
    #expect(engine.kills == 0 && engine.effects.allSatisfy { $0.damage <= 0 })
    let position = try #require(engine.projectiles.first?.position)
    engine.step(delta: 0.05)
    #expect(engine.projectiles.first?.position != position)
    var impacts = 0
    for _ in 0..<300 {
        engine.step(delta: 0.05)
        impacts += engine.effects.filter { $0.style == .missile && $0.damage > 0 }.count
        #expect(engine.projectiles.count <= 48)
    }
    #expect(impacts > 0 && engine.kills > 0)
}
@Test @MainActor func dronesOrbitAndElectricLinksStayLocal() throws {
    let content = try GameContent.bundled()
    var profile = PlayerProfile(); profile.equippedWeapon = "fireDrone"
    let drones = BattleEngine(content: content, profile: profile, mode: .campaign, seed: 42)
    let before = drones.dronePositions
    drones.step(delta: 0.05)
    #expect(drones.dronePositions.count == 2 && drones.dronePositions != before)
    #expect(drones.dronePositions.allSatisfy { abs(($0 - drones.player).length - 0.1) < 0.000001 })
    profile.equippedWeapon = "chain"; profile.robotLevels = ["bolt": 30]
    let electric = BattleEngine(content: content, profile: profile, mode: .campaign, seed: 11)
    var links = 0
    for _ in 0..<1200 {
        if electric.state == .choosing { electric.choose(electric.choices[0]) }
        electric.step(delta: 0.05)
        for effect in electric.effects where effect.style == .arc && effect.from != electric.player {
            links += 1
            #expect((effect.to - effect.from).length <= 0.220001)
        }
    }
    #expect(links > 0)
}
@Test @MainActor func bossWarningsAllowEscapeAndFreezeAtUpgrade() throws {
    let content = try GameContent.bundled()
    var profile = PlayerProfile(); profile.squad = ["bolt"]; profile.robotLevels = ["bolt": 30]
    let engine = BattleEngine(content: content, profile: profile, mode: .bossRush, seed: 42)
    for _ in 0..<120 where engine.warnings.isEmpty { engine.step(delta: 0.05) }
    let warning = try #require(engine.warnings.first)
    #expect(warning.boss && warning.remaining > 1)
    let originalHealth = engine.health
    for _ in 0..<36 { engine.step(delta: 0.05, movement: Vector(1, 0)) }
    #expect(engine.health == originalHealth)
    let stationary = BattleEngine(content: content, profile: profile, mode: .bossRush, seed: 42)
    for _ in 0..<140 { stationary.step(delta: 0.05) }
    #expect(stationary.health < stationary.maxHealth)
    for _ in 0..<500 where engine.state == .fighting { engine.step(delta: 0.05) }
    #expect(engine.state == .choosing)
    let times = engine.warnings.map(\.remaining), elapsed = engine.elapsed
    engine.step(delta: 0.05)
    #expect(engine.warnings.map(\.remaining) == times && engine.elapsed == elapsed)
}
