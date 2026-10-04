import Foundation
import Testing
@testable import ScrapCore

@Test @MainActor func everyWeaponAndBiomeKeepsCombatStateFiniteAndBounded() throws {
    let content = try GameContent.bundled()
    var cases = 0, peakEnemies = 0, peakProjectiles = 0, peakWarnings = 0
    let started = ContinuousClock.now
    for zone in content.biomes.indices {
        for weapon in content.weapons {
            var profile = PlayerProfile()
            profile.zone = zone; profile.equippedWeapon = weapon.id
            profile.squad = ["bolt", "patch"]
            profile.robotLevels = ["bolt": 30, "patch": 30]
            profile.weaponLevels = [weapon.id: 3]
            let engine = BattleEngine(content: content, profile: profile, mode: .survival, seed: UInt64(100 + zone))
            for tick in 0..<3600 {
                if engine.state == .choosing { engine.choose(try #require(engine.choices.first)) }
                if engine.state == .defeated || engine.state == .victory { break }
                // A repeatable rectangular patrol reaches boundary clamps and different attack lanes.
                let directions = [Vector(1, 0), Vector(0, 1), Vector(-1, 0), Vector(0, -1)]
                engine.step(delta: 0.05, movement: directions[(tick / 180) % 4])
                if tick % 60 == 0 {
                    peakEnemies = max(peakEnemies, engine.enemies.count)
                    peakProjectiles = max(peakProjectiles, engine.projectiles.count)
                    peakWarnings = max(peakWarnings, engine.warnings.count)
                    #expect(engine.health.isFinite && engine.health >= 0 && engine.health <= engine.maxHealth)
                    #expect(engine.player.x.isFinite && engine.player.y.isFinite)
                    #expect(engine.enemies.count <= 80 && engine.projectiles.count <= 48)
                    #expect(engine.warnings.count <= 16)
                    #expect(engine.enemies.allSatisfy { $0.health.isFinite && $0.position.x.isFinite && $0.position.y.isFinite })
                    #expect(engine.projectiles.allSatisfy { $0.remaining > 0 && $0.position.x.isFinite && $0.position.y.isFinite })
                }
            }
            #expect(engine.elapsed > 20)
            cases += 1
        }
    }
    #expect(cases == content.biomes.count * content.weapons.count)
    print("Release stress: \(cases) weapon/biome cases; sampled peaks enemies=\(peakEnemies), projectiles=\(peakProjectiles), warnings=\(peakWarnings); host elapsed=\(started.duration(to: .now)). Not a device FPS or thermal measurement.")
}
