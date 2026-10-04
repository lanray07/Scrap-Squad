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
    public var attackSequence = 0
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
    public var style: WeaponStyle = .bolt
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
    public let seed: UInt64
    public let challengeCode: String?
    public private(set) var combo = ComboMeter()
    public private(set) var synergies: Set<BuildSynergy> = []
    public var wave: Int { min(6, 1 + Int(elapsed / 20)) }
    private var comboScore = 0
    public private(set) var state: RunState = .fighting
    public private(set) var elapsed = 0.0
    public private(set) var player = Vector(0.5, 0.5)
    public private(set) var health: Double
    public let maxHealth: Double
    public private(set) var enemies: [Enemy] = []
    public private(set) var effects: [CombatEffect] = []
    public private(set) var projectiles: [CombatProjectile] = []
    public private(set) var warnings: [AttackWarning] = []
    public var bossPattern: BossPattern { BossPattern(biomeID: biome.id) }
    public var dronePositions: [Vector] {
        guard weapon.style == .drone else { return [] }
        return (0..<min(6, weapon.projectiles + extraProjectiles)).map { index in
            let angle = elapsed * 2.2 + Double(index) * .pi * 2 / Double(min(6, weapon.projectiles + extraProjectiles))
            return player + Vector(cos(angle), sin(angle)) * 0.10
        }
    }
    public private(set) var choices: [Upgrade] = []
    public private(set) var selected: [String: Int] = [:]
    public private(set) var kills = 0
    public private(set) var bosses = 0
    public private(set) var abilityCooldown = 0.0
    public var priority: TargetPriority = .nearest
    public private(set) var bossSpawned = false
    public var bossArmor: Double? { enemies.first(where: \.boss).map { max(0, $0.armor / (90 * biome.difficulty)) } }
    public var score: Int { kills * 100 + bosses * 1500 + Int(elapsed) * 10 + comboScore }
    public var bossHealth: Double? { enemies.first(where: \.boss).map { $0.health / $0.maxHealth } }
    public var duration: Double { content.economy.runSeconds }
    public var anomalyElement: Element { Element.allCases[Int(profile.dailyKey.utf8.reduce(0) { $0 + Int($1) }) % Element.allCases.count] }
    private var rng: SeededRandom
    private var offerRng: SeededRandom
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

    public init(content: GameContent, profile: PlayerProfile, mode: GameMode, seed: UInt64 = UInt64.random(in: 1...UInt64.max), challengeCode: String? = nil) {
        self.content = content; self.profile = profile; self.mode = mode
        biome = content.biomes[min(max(0, profile.zone), content.biomes.count - 1)]
        weapon = content.weapons.first(where: { $0.id == profile.equippedWeapon }) ?? content.weapons[0]
        rng = SeededRandom(seed: seed)
        offerRng = SeededRandom(seed: seed ^ 0x5343524150)
        self.seed = seed; self.challengeCode = challengeCode
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
        combo.tick(dt)
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
            let offset = Int(offerRng.next() * Double(max(1, eligible.count - 2)))
            choices = Array(eligible.dropFirst(offset).prefix(3))
            if !choices.isEmpty { state = .choosing; return }
        }
        let bossTime = mode == .bossRush ? 3 : content.economy.bossAtSeconds
        if !bossSpawned && elapsed >= bossTime { spawnBoss(); bossSpawned = true }
        if elapsed >= nextSpawn && enemies.count < 80 && mode != .bossRush {
            spawn()
            // Wave bursts create visible groups, with room to breathe between them.
            if wave >= 2 && Int(elapsed) % 8 < 2 { spawn() }
            nextSpawn = elapsed + max(0.35, 1.05 - Double(wave - 1) * 0.12)
        }
        if elapsed >= nextHazard {
            nextHazard = elapsed + 14
            let center = Vector(0.25 + rng.next() * 0.5, 0.25 + rng.next() * 0.5)
            warn(AttackArea(shape: .circle, from: center, to: center, radius: 0.14), damage: 10, duration: 1.5, boss: false)
        }
        advanceWarnings(dt)
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
                        if enemies[index].boss && bossPattern == .charge { enemies[index].position = enemies[index].target }
                        enemies[index].nextAttack = elapsed + (enemies[index].health < enemies[index].maxHealth / 2 ? 2.4 : 3.8)
                    }
                } else if elapsed >= enemies[index].nextAttack {
                    let enraged = enemies[index].health < enemies[index].maxHealth / 2
                    enemies[index].windup = enemies[index].boss ? (enraged ? 1.1 : 1.5) : 0.9
                    enemies[index].target = player
                    let areas = enemies[index].boss ? bossPattern.areas(origin: enemies[index].position, target: player, enraged: enraged, sequence: enemies[index].attackSequence) : [AttackArea(shape: .circle, from: player, to: player, radius: 0.07)]
                    enemies[index].attackSequence += 1
                    for area in areas { warn(area, damage: enemies[index].boss ? 30 : 12, duration: enemies[index].windup, boss: enemies[index].boss) }
                }
            }
            if distance < (enemies[index].boss ? 0.1 : 0.045) && invulnerability == 0 {
                health -= (kind == "exploder" ? 25 : kind == "elite" || kind == "miniboss" ? 18 : 9) * (kind == "exploder" ? 1 : dt)
                if kind == "exploder" { enemies[index].health = 0 }
            }
        }
        if elapsed >= nextShot && !enemies.isEmpty {
            fire(); nextShot = elapsed + weapon.interval / (attackMultiplier * (combo.overdrive > 0 ? 1.65 : 1))
        }
        advanceProjectiles(dt)
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
        let kinds = Set(content.upgrades.filter { selected[$0.id, default: 0] > 0 }.map(\.kind))
        for synergy in BuildSynergy.allCases where synergy.ready(kinds: kinds) && synergies.insert(synergy).inserted {
            switch synergy {
            case .thermalShock: damageMultiplier += 0.35
            case .stormLattice: chain += 2
            case .perfectStorm: criticalChance += 0.15; attackMultiplier += 0.2
            }
        }
        choices = []; state = .fighting
    }
    @discardableResult public func activateOverdrive() -> Bool {
        guard state == .fighting else { return false }
        return combo.activate()
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
    public func reward() -> RunReward {
        RunReward(id: id, mode: mode, zone: profile.zone, kills: kills, bosses: bosses, score: score, victory: state == .victory,
            highlights: RunHighlights(weaponID: weapon.id, elapsed: elapsed, bestCombo: combo.best, overdrives: combo.activations,
                synergies: BuildSynergy.allCases.filter { synergies.contains($0) }, challengeCode: challengeCode))
    }
    private func spawn() {
        serial += 1
        let angle = rng.next() * .pi * 2
        let kind = biome.enemies[Int(rng.next() * Double(biome.enemies.count))]
        let hp = (kind == "miniboss" ? 160 : kind == "elite" ? 85 : kind == "tank" || kind == "shield" ? 55.0 : 22) * biome.difficulty * (1 + elapsed / 240)
        let position = player + Vector(cos(angle), sin(angle)) * 0.48
        enemies.append(Enemy(id: serial, position: Vector(min(1.05, max(-0.05, position.x)), min(1.05, max(-0.05, position.y))), health: hp, maxHealth: hp, kind: kind))
    }
    private func spawnBoss() {
        serial += 1
        let hp = 450 * biome.difficulty * (1 + Double(bosses) * 0.5)
        enemies.append(Enemy(id: serial, position: Vector(0.5, 0.9), health: hp, maxHealth: hp, kind: "boss", nextAttack: elapsed + 2, armor: 90 * biome.difficulty))
    }
    private func fire() {
        let origins = dronePositions.isEmpty ? [player] : dronePositions
        let indices = enemies.indices.filter {
            enemies[$0].health > 0 && (enemies[$0].position - player).length <= weapon.range && !(enemies[$0].kind == "burrower" && Int(elapsed) % 5 < 2)
        }.sorted {
            if priority == .boss && enemies[$0].boss != enemies[$1].boss { return enemies[$0].boss }
            if priority == .weakest { return enemies[$0].health < enemies[$1].health }
            return (enemies[$0].position - player).length < (enemies[$1].position - player).length
        }
        var struck = Set<Int>()
        for (shot, index) in indices.prefix(min(8, weapon.projectiles + extraProjectiles)).enumerated() {
            if struck.contains(enemies[index].id) { continue }
            let origin = origins[shot % origins.count]
            let critical = rng.next() < min(0.7, criticalChance)
            if weapon.style == .missile {
                if projectiles.count < 48 {
                    serial += 1
                    projectiles.append(CombatProjectile(id: serial, position: origin, targetID: enemies[index].id, remaining: 2.5, critical: critical))
                }
                continue
            }
            struck.insert(enemies[index].id)
            let impact = enemies[index].position
            hit(index, from: origin, critical: critical, scale: 1, style: weapon.style)
            if weapon.style == .beam {
                let ray = AttackArea(shape: .line, from: origin, to: origin + (impact - origin).normalized * weapon.range, radius: 0.035)
                let pierce = enemies.indices.filter { !struck.contains(enemies[$0].id) && enemies[$0].health > 0 && ray.contains(enemies[$0].position) }
                    .sorted { (enemies[$0].position - origin).length < (enemies[$1].position - origin).length }
                for other in pierce.prefix(3) {
                    struck.insert(enemies[other].id)
                    hit(other, from: origin, critical: critical, scale: 0.7, style: .beam)
                }
            }
            var link = impact
            for hop in 0..<min(6, chain) {
                guard let other = enemies.indices.filter({ enemies[$0].health > 0 && !struck.contains(enemies[$0].id) && (enemies[$0].position - link).length <= 0.22 })
                    .min(by: { (enemies[$0].position - link).length < (enemies[$1].position - link).length }) else { break }
                struck.insert(enemies[other].id)
                let destination = enemies[other].position
                hit(other, from: link, critical: critical, scale: pow(0.85, Double(hop + 1)), style: .arc)
                link = destination
            }
        }
    }
    private func hit(_ index: Int, from: Vector, critical: Bool, scale: Double, style: WeaponStyle) {
        let bossBonus = enemies[index].boss && weapon.element == biome.weakness ? 1.75 : 1.0
        let shield = enemies[index].kind == "shield" && weapon.element == .ballistic ? 0.5 : 1.0
        let damage = weapon.damage * damageMultiplier * bossBonus * shield * scale * (critical ? 2 : 1) * (combo.overdrive > 0 ? 1.35 : 1)
        let impact = enemies[index].position
        damageEnemy(index, amount: damage)
        if !enemies[index].boss { enemies[index].position = impact + (impact - from).normalized * 0.012 }
        if explosionRadius > 0 {
            for other in enemies.indices where other != index && (enemies[other].position - impact).length < explosionRadius {
                damageEnemy(other, amount: damage * 0.4)
            }
        }
        serial += 1
        effects.append(CombatEffect(id: serial, from: from, to: impact, element: weapon.element, damage: Int(damage), critical: critical, remaining: style == .orbital ? 0.45 : 0.24, style: style))
    }
    private func damageEnemy(_ index: Int, amount: Double) {
        let absorbed = min(enemies[index].armor, amount)
        enemies[index].armor -= absorbed
        enemies[index].health -= amount - absorbed + absorbed * 0.45
        if burn { enemies[index].burnUntil = elapsed + 3 }
        if freeze { enemies[index].slowUntil = elapsed + 2 }
    }
    private func advanceProjectiles(_ dt: Double) {
        var active: [CombatProjectile] = []
        for var projectile in projectiles {
            projectile.remaining -= dt
            guard projectile.remaining > 0 else { continue }
            let target = enemies.first(where: { $0.id == projectile.targetID && $0.health > 0 }) ?? enemies.filter { $0.health > 0 && ($0.position - projectile.position).length < 0.40 }.min(by: { ($0.position - projectile.position).length < ($1.position - projectile.position).length })
            guard let target, let index = enemies.firstIndex(where: { $0.id == target.id }) else { continue }
            projectile.targetID = target.id
            let offset = target.position - projectile.position
            if offset.length <= 0.75 * dt + 0.025 {
                hit(index, from: projectile.position, critical: projectile.critical, scale: 1, style: .missile)
            } else {
                projectile.position = projectile.position + offset.normalized * (0.75 * dt)
                active.append(projectile)
            }
        }
        projectiles = active
    }
    private func warn(_ area: AttackArea, damage: Double, duration: Double, boss: Bool) {
        guard warnings.count < 48 else { return }
        serial += 1
        warnings.append(AttackWarning(id: serial, area: area, damage: damage, duration: duration, remaining: duration, boss: boss))
    }
    private func advanceWarnings(_ dt: Double) {
        var active: [AttackWarning] = []
        var damage = 0.0
        for var warning in warnings {
            warning.remaining -= dt
            if warning.remaining > 0 { active.append(warning) }
            else {
                if warning.area.contains(player) { damage = max(damage, warning.damage) }
                serial += 1
                effects.append(CombatEffect(id: serial, from: warning.area.from, to: warning.area.to, element: .explosive, damage: 0, critical: false, remaining: 0.3))
            }
        }
        warnings = active
        if damage > 0 && invulnerability == 0 { health -= damage; invulnerability = 0.35 }
    }
    private func collectKills() {
        let dead = enemies.filter { $0.health <= 0 }
        combo.register(kills: dead.count)
        comboScore += dead.count * 100 * max(0, combo.multiplier - 1)
        kills += dead.count
        let bossKills = dead.filter(\.boss).count
        if bossKills > 0 { warnings.removeAll { $0.boss } }
        bosses += bossKills
        enemies.removeAll { $0.health <= 0 }
        if mode == .bossRush && bossKills > 0 && bosses < 3 { spawnBoss() }
    }
}
