import Foundation

public struct Vector: Sendable, Equatable {
    public var x: Double
    public var y: Double
    public init(_ x: Double = 0, _ y: Double = 0) { self.x = x; self.y = y }
    public var length: Double { sqrt(x * x + y * y) }
    public var normalized: Vector { length > 0 ? self * (1 / length) : Vector() }
    public static func + (a: Vector, b: Vector) -> Vector { Vector(a.x + b.x, a.y + b.y) }
    public static func - (a: Vector, b: Vector) -> Vector { Vector(a.x - b.x, a.y - b.y) }
    public static func * (a: Vector, b: Double) -> Vector { Vector(a.x * b, a.y * b) }
}
public struct SeededRandom: Sendable {
    private var state: UInt64
    public init(seed: UInt64) { state = seed == 0 ? 1 : seed }
    public mutating func next() -> Double {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return Double(state >> 11) / Double(UInt64(1) << 53)
    }
}
public struct Enemy: Identifiable, Sendable {
    public let id: Int
    public var position: Vector
    public var health: Double
    public let maxHealth: Double
    public let kind: String
    public var slowUntil: Double = 0
    public var burnUntil: Double = 0
    public var nextAttack: Double = 0
    public var windup: Double = 0
    public var target = Vector()
    public var armor = 0.0
    public var boss: Bool { kind == "boss" }
}
public struct CombatEffect: Identifiable, Sendable {
    public let id: Int
    public let from: Vector
    public let to: Vector
    public let element: Element
    public let damage: Int
    public let critical: Bool
    public var remaining: Double
}
public enum RunState: Sendable, Equatable { case fighting, choosing, victory, defeated }
public enum TargetPriority: String, CaseIterable, Sendable { case nearest, weakest, boss }

@MainActor public final class BattleEngine {
    public let id = UUID()
    public let content: GameContent
    public let profile: PlayerProfile
    public let mode: GameMode
    public let biome: Biome
    public let weapon: Weapon
    public private(set) var state: RunState = .fighting
    public private(set) var elapsed = 0.0
    public private(set) var player = Vector(0.5, 0.5)
    public private(set) var health: Double
    public let maxHealth: Double
    public private(set) var enemies: [Enemy] = []
    public private(set) var effects: [CombatEffect] = []
    public private(set) var choices: [Upgrade] = []
    public private(set) var selected: [String: Int] = [:]
    public private(set) var kills = 0
    public private(set) var bosses = 0
    public private(set) var abilityCooldown = 0.0
    public var priority: TargetPriority = .nearest
    public private(set) var bossSpawned = false
    public var bossArmor: Double? { enemies.first(where: \.boss).map { max(0, $0.armor / (90 * biome.difficulty)) } }
    public var score: Int { kills * 100 + bosses * 1500 + Int(elapsed) * 10 }
    public var bossHealth: Double? { enemies.first(where: \.boss).map { $0.health / $0.maxHealth } }
    public var duration: Double { content.economy.runSeconds }
    public var anomalyElement: Element { Element.allCases[Int(profile.dailyKey.utf8.reduce(0) { $0 + Int($1) }) % Element.allCases.count] }
    private var rng: SeededRandom
    private var serial = 0
    private var nextSpawn = 0.0
    private var nextShot = 0.0
    private var nextChoice = 0
    private var damageMultiplier = 1.0
    private var attackMultiplier = 1.0
    private var chain = 0
    private var extraProjectiles = 0
    private var burn = false
    private var freeze = false
    private var criticalChance = 0.08
    private var regeneration = 0.0
    private var explosionRadius = 0.0
    private var invulnerability = 0.0
    private var nextHazard = 12.0

    public init(content: GameContent, profile: PlayerProfile, mode: GameMode, seed: UInt64 = UInt64.random(in: 1...UInt64.max)) {
        self.content = content; self.profile = profile; self.mode = mode
        biome = content.biomes[min(max(0, profile.zone), content.biomes.count - 1)]
        weapon = content.weapons.first(where: { $0.id == profile.equippedWeapon }) ?? content.weapons[0]
        rng = SeededRandom(seed: seed)
        let squad = content.robots.filter { profile.squad.contains($0.id) }
        maxHealth = squad.reduce(0) { $0 + $1.health * (1 + Double(profile.robotLevels[$1.id, default: 1] - 1) * 0.08) }
        health = maxHealth
        damageMultiplier = (1 + squad.reduce(0) { $0 + $1.damageBonus } + Double(profile.reboots) * 0.1)
            * (1 + Double(profile.buildingLevels["research", default: 0]) * 0.05)
            * (1 + Double(profile.weaponLevels[weapon.id, default: 1] - 1) * 0.12)
        attackMultiplier = 1 + squad.reduce(0) { $0 + $1.speedBonus }
        if squad.contains(where: { $0.affinity == weapon.element }) { damageMultiplier *= 1.15 }
        if profile.squad.contains("patch") { regeneration = 0.6 }
        if profile.squad.contains("boomer") { explosionRadius = 0.1 }
        if mode == .fusionLab { extraProjectiles = 2 }
        if mode == .dailyAnomaly && weapon.element == anomalyElement { damageMultiplier *= 1.5 }
        for modifier in weapon.modifiers { apply(kind: modifier.kind, value: modifier.value) }
    }
    public func step(delta: Double, movement: Vector = Vector()) {
        guard state == .fighting else { return }
        let dt = min(max(delta, 0), 0.05)
        elapsed += dt
        abilityCooldown = max(0, abilityCooldown - dt)
        invulnerability = max(0, invulnerability - dt)
        health = min(maxHealth, health + regeneration * dt)
        player = player + movement.normalized * (0.24 * dt)
        player.x = min(0.93, max(0.07, player.x)); player.y = min(0.93, max(0.07, player.y))
        effects = effects.compactMap { var effect = $0; effect.remaining -= dt; return effect.remaining > 0 ? effect : nil }
        if nextChoice < content.economy.upgradeSeconds.count && elapsed >= content.economy.upgradeSeconds[nextChoice] {
            nextChoice += 1
            // Favor relevant elements and upgrades that have not reached their stack cap.
            let eligible = content.upgrades.filter { selected[$0.id, default: 0] < 3 }.sorted {
                let a = ($0.element == weapon.element ? 10 : 0) - selected[$0.id, default: 0]
                let b = ($1.element == weapon.element ? 10 : 0) - selected[$1.id, default: 0]
                return a == b ? $0.id < $1.id : a > b
            }
            let offset = Int(rng.next() * Double(max(1, eligible.count - 2)))
            choices = Array(eligible.dropFirst(offset).prefix(3))
            if !choices.isEmpty { state = .choosing; return }
        }
        let bossTime = mode == .bossRush ? 3 : content.economy.bossAtSeconds
        if !bossSpawned && elapsed >= bossTime { spawnBoss(); bossSpawned = true }
        if elapsed >= nextSpawn && enemies.count < 80 && mode != .bossRush {
            spawn(); nextSpawn = elapsed + max(0.22, 1.2 - elapsed / 180)
        }
        if elapsed >= nextHazard {
            nextHazard = elapsed + 14
            serial += 1
            // Visible environmental warning. Hazard damage starts on the next cycle.
            let center = Vector(0.25 + rng.next() * 0.5, 0.25 + rng.next() * 0.5)
            effects.append(CombatEffect(id: serial, from: center, to: center, element: biome.weakness, damage: -1, critical: false, remaining: 1.5))
        }
        for effect in effects where effect.damage == -1 && effect.remaining < 0.1 {
            if (player - effect.to).length < 0.14 && invulnerability == 0 { health -= 10 * dt / 0.1 }
        }
        for index in enemies.indices {
            if enemies[index].burnUntil > elapsed { enemies[index].health -= weapon.damage * 0.18 * dt }
            let distance = (player - enemies[index].position).length
            let kind = enemies[index].kind
            let slow = enemies[index].slowUntil > elapsed ? 0.35 : 1.0
            let speed = (kind == "swarmer" || kind == "flying" ? 0.1 : kind == "burrower" ? 0.13 : kind == "tank" || kind == "boss" ? 0.04 : 0.065) * slow
            if kind != "ranged" || distance > 0.28 {
                enemies[index].position = enemies[index].position + (player - enemies[index].position).normalized * (speed * dt)
            }
            if kind == "repair" {
                for other in enemies.indices where other != index && (enemies[other].position - enemies[index].position).length < 0.12 {
                    enemies[other].health = min(enemies[other].maxHealth, enemies[other].health + dt * 3)
                }
            }
            if enemies[index].boss || kind == "ranged" {
                if enemies[index].windup > 0 {
                    enemies[index].windup -= dt
                    if enemies[index].windup <= 0 {
                        let radius = enemies[index].boss ? 0.18 : 0.07
                        if (player - enemies[index].target).length < radius && invulnerability == 0 { health -= enemies[index].boss ? 35 : 12 }
                        serial += 1
                        effects.append(CombatEffect(id: serial, from: enemies[index].position, to: enemies[index].target, element: .explosive, damage: 0, critical: false, remaining: 0.3))
                        enemies[index].nextAttack = elapsed + (enemies[index].health < enemies[index].maxHealth / 2 ? 2 : 4)
                    }
                } else if elapsed >= enemies[index].nextAttack {
                    enemies[index].windup = enemies[index].boss ? 1.4 : 0.8
                    enemies[index].target = player
                }
            }
            if distance < (enemies[index].boss ? 0.1 : 0.045) && invulnerability == 0 {
                health -= (kind == "exploder" ? 25 : kind == "elite" || kind == "miniboss" ? 18 : 9) * (kind == "exploder" ? 1 : dt)
                if kind == "exploder" { enemies[index].health = 0 }
            }
        }
        if elapsed >= nextShot && !enemies.isEmpty {
            fire(); nextShot = elapsed + weapon.interval / attackMultiplier
        }
        collectKills()
        if health <= 0 { health = 0; state = .defeated }
        else if mode == .bossRush && bosses >= 3 { state = .victory }
        else if mode != .survival && mode != .arena && elapsed >= duration {
            state = bosses > 0 ? .victory : .defeated
        }
    }
    public func choose(_ upgrade: Upgrade) {
        guard state == .choosing, choices.contains(where: { $0.id == upgrade.id }) else { return }
        selected[upgrade.id, default: 0] += 1; apply(kind: upgrade.kind, value: upgrade.value)
        choices = []; state = .fighting
    }
    private func apply(kind: String, value: Double) {
        switch kind {
        case "damage": damageMultiplier += value
        case "speed": attackMultiplier += value
        case "chain": chain += Int(value)
        case "split": extraProjectiles += Int(value)
        case "burn": burn = true
        case "freeze": freeze = true
        case "critical": criticalChance += value
        case "repair": regeneration += value
        case "explosion": explosionRadius += value
        default: break
        }
    }
    public func activateAbility() {
        guard abilityCooldown == 0 && state == .fighting else { return }
        abilityCooldown = 18; invulnerability = 1.2
        let commander = profile.squad.first ?? "bolt"
        if commander == "patch" { health = min(maxHealth, health + maxHealth * 0.35) }
        else if commander == "tank" { invulnerability = 5 }
        else {
            for index in enemies.indices where (enemies[index].position - player).length < 0.35 {
                enemies[index].health -= weapon.damage * (commander == "boomer" ? 6 : 4)
                if commander == "glitch" { enemies[index].slowUntil = elapsed + 5 }
            }
            if commander == "zip" { nextShot = 0 }
            if commander == "magnet" { health = min(maxHealth, health + 10) }
        }
        serial += 1
        effects.append(CombatEffect(id: serial, from: player, to: player, element: weapon.element, damage: 0, critical: true, remaining: 0.7))
        collectKills()
    }
    public func retreat() { if state == .fighting || state == .choosing { state = .defeated } }
    public func reward() -> RunReward { RunReward(id: id, mode: mode, zone: profile.zone, kills: kills, bosses: bosses, score: score, victory: state == .victory) }
    private func spawn() {
        serial += 1
        let angle = rng.next() * .pi * 2
        let kind = biome.enemies[Int(rng.next() * Double(biome.enemies.count))]
        let hp = (kind == "miniboss" ? 160 : kind == "elite" ? 85 : kind == "tank" || kind == "shield" ? 55.0 : 22) * biome.difficulty * (1 + elapsed / 240)
        enemies.append(Enemy(id: serial, position: player + Vector(cos(angle), sin(angle)) * 0.55, health: hp, maxHealth: hp, kind: kind))
    }
    private func spawnBoss() {
        serial += 1
        let hp = 450 * biome.difficulty * (1 + Double(bosses) * 0.5)
        enemies.append(Enemy(id: serial, position: Vector(0.5, 0.9), health: hp, maxHealth: hp, kind: "boss", nextAttack: elapsed + 2, armor: 90 * biome.difficulty))
    }
    private func fire() {
        let indices = enemies.indices.sorted {
            if priority == .boss && enemies[$0].boss != enemies[$1].boss { return enemies[$0].boss }
            if priority == .weakest { return enemies[$0].health < enemies[$1].health }
            return (enemies[$0].position - player).length < (enemies[$1].position - player).length
        }
        for index in indices.prefix(weapon.projectiles + extraProjectiles + chain) {
            if enemies[index].kind == "burrower" && Int(elapsed) % 5 < 2 { continue }
            let critical = rng.next() < min(0.7, criticalChance)
            let bossBonus = enemies[index].boss && weapon.element == biome.weakness ? 1.75 : 1.0
            let shield = enemies[index].kind == "shield" && weapon.element == .ballistic ? 0.5 : 1.0
            let damage = weapon.damage * damageMultiplier * bossBonus * shield * (critical ? 2 : 1)
            if enemies[index].armor > 0 {
                enemies[index].armor = max(0, enemies[index].armor - damage)
                enemies[index].health -= damage * 0.45
            } else { enemies[index].health -= damage }
            if burn { enemies[index].burnUntil = elapsed + 3 }
            if freeze { enemies[index].slowUntil = elapsed + 2 }
            let impact = enemies[index].position
            if !enemies[index].boss { enemies[index].position = impact + (impact - player).normalized * 0.018 }
            if explosionRadius > 0 {
                for other in enemies.indices where other != index && (enemies[other].position - impact).length < explosionRadius {
                    enemies[other].health -= damage * 0.4
                }
            }
            serial += 1
            effects.append(CombatEffect(id: serial, from: player, to: impact, element: weapon.element, damage: Int(damage), critical: critical, remaining: 0.24))
        }
    }
    private func collectKills() {
        let dead = enemies.filter { $0.health <= 0 }
        kills += dead.count
        let bossKills = dead.filter(\.boss).count
        bosses += bossKills
        enemies.removeAll { $0.health <= 0 }
        if mode == .bossRush && bossKills > 0 && bosses < 3 { spawnBoss() }
    }
}
