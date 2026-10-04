import SpriteKit
import UIKit
import ScrapCore

@MainActor final class BattleScene: SKScene {
    let engine: BattleEngine
    let finishes: [String: RobotFinish]
    let goldenTrails: Bool
    var movement = Vector()
    var refresh: (() -> Void)?
    private var previous: TimeInterval = 0
    private var hudAt = 0.0
    private var renderedEffects = Set<Int>()
    private var enemyNodes: [Int: SKNode] = [:]
    private var warnings: [Int: SKShapeNode] = [:]
    private var projectileNodes: [Int: SKNode] = [:]
    private var droneNodes: [SKNode] = []
    private let trackingCamera = SKCameraNode()
    private let arenaBoundary = SKShapeNode()
    private var arenaScale: CGFloat { max(1, min(size.width, size.height) * 1.4) }
    private var unitScale: CGFloat { max(0.4, min(1, arenaScale / 600)) }
    private var robotNodes: [SKNode] = []
    private let world = SKNode()
    private let effectsLayer = SKNode()
    private var lastKills = 0
    private var lastWave = 1
    private var lastComboTier = 1
    private var lastSynergyCount = 0
    private var overdriveAura: SKShapeNode?
    private var lastShotSoundAt = -1.0
    init(engine: BattleEngine, finishes: [String: RobotFinish], goldenTrails: Bool) {
        self.engine = engine
        self.finishes = finishes
        self.goldenTrails = goldenTrails
        super.init(size: CGSize(width: 600, height: 800))
        scaleMode = .resizeFill
        backgroundColor = UIColor(hex: engine.biome.palette[0])
    }
    required init?(coder: NSCoder) { fatalError("Programmatic scene only") }
    override func didMove(to view: SKView) {
        guard world.parent == nil else { return }
        addChild(world); addChild(effectsLayer)
        addChild(trackingCamera); camera = trackingCamera
        arenaBoundary.strokeColor = UIColor(hex: "79D9BA").withAlphaComponent(0.2)
        arenaBoundary.lineWidth = 2; arenaBoundary.fillColor = .clear; arenaBoundary.zPosition = -3; world.addChild(arenaBoundary)
        let grid = SKShapeNode()
        let path = CGMutablePath()
        for x in stride(from: -1200.0, through: 2400.0, by: 60) { path.move(to: CGPoint(x: x, y: -1200)); path.addLine(to: CGPoint(x: x, y: 2400)) }
        for y in stride(from: -1200.0, through: 2400.0, by: 60) { path.move(to: CGPoint(x: -1200, y: y)); path.addLine(to: CGPoint(x: 2400, y: y)) }
        grid.path = path; grid.strokeColor = UIColor.white.withAlphaComponent(0.04); grid.zPosition = -10; world.addChild(grid)
        for index in 0..<22 {
            let piece = SKShapeNode(rectOf: CGSize(width: CGFloat(14 + index % 4 * 5), height: 9), cornerRadius: 3)
            piece.fillColor = UIColor(hex: engine.biome.palette[1]).withAlphaComponent(0.18); piece.strokeColor = .clear
            piece.position = CGPoint(x: Double((index * 137) % 570), y: Double((index * 193) % 780)); piece.zRotation = CGFloat(index) * 0.7; piece.zPosition = -5
            world.addChild(piece)
        }
        for id in engine.profile.squad {
            guard let robot = engine.content.robots.first(where: { $0.id == id }) else { continue }
            let node = makeRobot(robot); node.zPosition = 5; world.addChild(node); robotNodes.append(node)
        }
        for _ in engine.dronePositions {
            let drone = SKShapeNode(rectOf: CGSize(width: 18, height: 12), cornerRadius: 4)
            drone.fillColor = UIColor(hex: "F5B942"); drone.strokeColor = .white; drone.lineWidth = 1.5; drone.zPosition = 6
            let rotor = SKShapeNode(rectOf: CGSize(width: 28, height: 3), cornerRadius: 1)
            rotor.fillColor = UIColor(hex: "79D9BA"); rotor.strokeColor = .clear; rotor.position.y = 9; drone.addChild(rotor)
            world.addChild(drone); droneNodes.append(drone)
        }
    }
    override func update(_ currentTime: TimeInterval) {
        guard !isPaused else { previous = currentTime; return }
        let dt = previous == 0 ? 0 : min(0.05, currentTime - previous); previous = currentTime
        engine.step(delta: dt, movement: movement)
        trackingCamera.position = point(engine.player)
        arenaBoundary.path = CGPath(rect: CGRect(x: arenaScale * 0.07, y: arenaScale * 0.07, width: arenaScale * 0.86, height: arenaScale * 0.86), transform: nil)
        updateMomentum()
        for (index, node) in robotNodes.enumerated() {
            let angle = Double(index) * .pi * 2 / Double(max(1, robotNodes.count))
            let offset = index == 0 ? Vector() : Vector(cos(angle), sin(angle)) * 0.055
            node.position = point(engine.player + offset)
            node.setScale(unitScale)
            if !engine.profile.preferences.reducedMotion { node.zRotation = CGFloat(sin(currentTime * 4 + Double(index))) * 0.035 }
        }
        let ids = Set(engine.enemies.map(\.id))
        for id in Array(enemyNodes.keys) where !ids.contains(id) { enemyNodes.removeValue(forKey: id)?.removeFromParent() }
        for enemy in engine.enemies {
            let node: SKNode
            if let existing = enemyNodes[enemy.id] { node = existing }
            else { node = makeEnemy(enemy); enemyNodes[enemy.id] = node; world.addChild(node) }
            node.position = point(enemy.position)
            node.setScale(unitScale)
            node.alpha = enemy.kind == "burrower" && Int(engine.elapsed) % 5 < 2 ? 0.25 : 1
            if enemy.kind == "flying" && !engine.profile.preferences.reducedMotion { node.position.y += CGFloat(sin(currentTime * 5)) * 4 }
            if let bar = node.childNode(withName: "health") as? SKShapeNode { bar.xScale = max(0.01, enemy.health / enemy.maxHealth) }
            if enemy.boss, let hull = node.childNode(withName: "hull") as? SKShapeNode {
                hull.strokeColor = enemy.health < enemy.maxHealth / 2 ? .systemRed : UIColor(hex: engine.biome.palette[2])
            }
        }
        updateWarnings()
        updateProjectiles()
        // Upgrade-added drones appear without rebuilding the battle scene.
        let positions = engine.dronePositions
        while droneNodes.count < positions.count {
            let drone = SKShapeNode(rectOf: CGSize(width: 18, height: 12), cornerRadius: 4)
            drone.fillColor = UIColor(hex: "F5B942"); drone.strokeColor = .white; drone.zPosition = 6
            world.addChild(drone); droneNodes.append(drone)
        }
        for (index, node) in droneNodes.enumerated() {
            node.isHidden = index >= positions.count
            if index < positions.count { node.position = point(positions[index]); node.setScale(unitScale) }
        }
        let effectIDs = Set(engine.effects.map(\.id))
        renderedEffects.formIntersection(effectIDs)
        for effect in engine.effects where renderedEffects.insert(effect.id).inserted { render(effect) }
        if engine.kills > lastKills {
            lastKills = engine.kills
            if engine.profile.preferences.screenShake && !engine.profile.preferences.reducedMotion {
                world.run(.sequence([.moveBy(x: 2, y: 0, duration: 0.04), .moveBy(x: -2, y: 0, duration: 0.04)]))
            }
        }
        if currentTime - hudAt > 0.1 { hudAt = currentTime; refresh?() }
    }
    private func updateMomentum() {
        if engine.combo.overdrive > 0 {
            if overdriveAura == nil {
                let aura = SKShapeNode(circleOfRadius: 42)
                aura.strokeColor = UIColor(hex: "79D9BA"); aura.lineWidth = 3; aura.fillColor = .clear; aura.zPosition = 3
                world.addChild(aura); overdriveAura = aura
            }
            overdriveAura?.position = point(engine.player); overdriveAura?.setScale(unitScale)
        } else { overdriveAura?.removeFromParent(); overdriveAura = nil }
        if engine.wave > lastWave {
            lastWave = engine.wave
            announce(LocalizationManager.string("momentum.wave", locale: engine.profile.preferences.locale) + " \(engine.wave)", color: "F5B942")
        }
        if engine.combo.multiplier > lastComboTier {
            announce("×\(engine.combo.multiplier) " + LocalizationManager.string("momentum.combo", locale: engine.profile.preferences.locale), color: "79D9BA")
            AudioBus.shared.play(.combo, preferences: engine.profile.preferences)
        }
        lastComboTier = engine.combo.multiplier
        if engine.synergies.count > lastSynergyCount {
            lastSynergyCount = engine.synergies.count
            announce(LocalizationManager.string("synergy.activated", locale: engine.profile.preferences.locale), color: "BA9DEB")
            Feedback.play(.fusion, preferences: engine.profile.preferences)
        }
    }
    private func announce(_ text: String, color: String) {
        effectsLayer.childNode(withName: "momentum-announcement")?.removeFromParent()
        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.name = "momentum-announcement"; label.text = text; label.fontSize = min(22, size.width / 18)
        label.fontColor = UIColor(hex: color); let center = point(engine.player)
        label.position = CGPoint(x: center.x, y: center.y + size.height * 0.30); label.zPosition = 20
        effectsLayer.addChild(label)
        let exit: SKAction = engine.profile.preferences.reducedMotion ? .wait(forDuration: 1.5) : .sequence([.wait(forDuration: 1), .fadeOut(withDuration: 0.5)])
        label.run(.sequence([exit, .removeFromParent()]))
    }
    private func point(_ vector: Vector) -> CGPoint { CGPoint(x: vector.x * arenaScale, y: vector.y * arenaScale) }
    private func updateWarnings() {
        let ids = Set(engine.warnings.map(\.id))
        for id in Array(warnings.keys) where !ids.contains(id) { warnings.removeValue(forKey: id)?.removeFromParent() }
        for warning in engine.warnings {
            let node = warnings[warning.id] ?? SKShapeNode()
            let area = warning.area
            let path = CGMutablePath()
            switch area.shape {
            case .circle:
                let center = point(area.to), radius = area.radius * arenaScale
                path.addEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
                node.lineWidth = 2; node.fillColor = UIColor.orange.withAlphaComponent(0.16)
            case .ring:
                let center = point(area.to), radius = area.radius * arenaScale
                path.addEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
                node.lineWidth = area.thickness * arenaScale * 2; node.fillColor = .clear
            case .line:
                let stroke = CGMutablePath(); stroke.move(to: point(area.from)); stroke.addLine(to: point(area.to))
                path.addPath(stroke.copy(strokingWithWidth: area.radius * arenaScale * 2, lineCap: .round, lineJoin: .round, miterLimit: 1))
                node.lineWidth = 2; node.fillColor = UIColor.orange.withAlphaComponent(0.16)
            }
            node.path = path; node.strokeColor = warning.boss ? UIColor(hex: "FF806E") : .systemOrange
            node.alpha = 0.4 + 0.6 * (1 - warning.remaining / warning.duration); node.zPosition = 2
            if node.parent == nil { world.addChild(node); warnings[warning.id] = node }
        }
    }
    private func updateProjectiles() {
        let ids = Set(engine.projectiles.map(\.id))
        for id in Array(projectileNodes.keys) where !ids.contains(id) { projectileNodes.removeValue(forKey: id)?.removeFromParent() }
        for projectile in engine.projectiles {
            let node = projectileNodes[projectile.id] ?? SKShapeNode(rectOf: CGSize(width: 14, height: 5), cornerRadius: 2)
            if let shape = node as? SKShapeNode { shape.fillColor = UIColor(hex: goldenTrails ? "FFD878" : "FFB66C"); shape.strokeColor = .white; shape.lineWidth = 1 }
            node.position = point(projectile.position); node.setScale(unitScale); node.zPosition = 7
            if let target = engine.enemies.first(where: { $0.id == projectile.targetID }) { node.zRotation = CGFloat(atan2(target.position.y - projectile.position.y, target.position.x - projectile.position.x)) }
            if node.parent == nil { world.addChild(node); projectileNodes[projectile.id] = node }
        }
    }
    private func makeRobot(_ robot: Robot) -> SKNode {
        if let index = RobotArt.order.firstIndex(of: robot.id) {
            let atlas = SKTexture(imageNamed: "RobotAtlas")
            let rect = CGRect(x: Double(index % 4) / 4, y: index < 4 ? 0.5 : 0, width: 0.25, height: 0.5)
            let sprite = SKSpriteNode(texture: SKTexture(rect: rect, in: atlas))
            let dimension: CGFloat = robot.silhouette == "heavy" ? 60 : 48
            sprite.size = CGSize(width: dimension, height: dimension)
            if let finish = finishes[robot.id] {
                sprite.color = UIColor(hex: finish.tint); sprite.colorBlendFactor = 0.65
                let trim = SKShapeNode(ellipseOf: CGSize(width: dimension * 0.8, height: dimension * 0.25))
                trim.strokeColor = UIColor(hex: finish.accent); trim.lineWidth = 2; trim.position.y = -dimension * 0.35
                trim.zPosition = -1; sprite.addChild(trim)
                let decal = SKLabelNode(fontNamed: "AvenirNext-Bold")
                decal.text = finish.id == "bolt-founders-gold" ? "★" : finish.robotID == "patch" ? "♥" : "◆"
                decal.fontSize = 10; decal.fontColor = UIColor(hex: finish.accent); decal.position.y = -5; sprite.addChild(decal)
            }
            return sprite
        }
        let root = SKNode()
        let heavy = robot.silhouette == "heavy"
        let body = SKShapeNode(rectOf: CGSize(width: heavy ? 44 : 32, height: 32), cornerRadius: robot.silhouette == "orb" ? 16 : 9)
        body.fillColor = UIColor(hex: robot.color); body.strokeColor = UIColor(hex: "0B1E26"); body.lineWidth = 3
        root.addChild(body)
        let face = SKShapeNode(rectOf: CGSize(width: 26, height: 12), cornerRadius: 4); face.fillColor = UIColor(hex: "10252D"); face.strokeColor = .clear; face.position.y = 4; root.addChild(face)
        for x in [-7,7] { let eye = SKShapeNode(rectOf: CGSize(width: 5, height: 4), cornerRadius: 1); eye.fillColor = UIColor(hex: "92FFE0"); eye.strokeColor = .clear; eye.position = CGPoint(x: x, y: 4); root.addChild(eye) }
        let antenna = SKShapeNode(rectOf: CGSize(width: 3, height: 8)); antenna.fillColor = .lightGray; antenna.strokeColor = .clear; antenna.position.y = 20; root.addChild(antenna)
        let gun = SKShapeNode(rectOf: CGSize(width: 10, height: 20), cornerRadius: 3); gun.fillColor = UIColor(hex: "F5B942"); gun.strokeColor = UIColor(hex: "10252D"); gun.position = CGPoint(x: 19, y: 4); root.addChild(gun)
        return root
    }
    private func makeEnemy(_ enemy: Enemy) -> SKNode {
        let root = SKNode()
        let radius: CGFloat = enemy.boss ? 46 : enemy.kind == "miniboss" ? 30 : enemy.kind == "tank" || enemy.kind == "elite" ? 21 : 13
        let roundBoss = enemy.boss && [.shockRing, .bombardment, .collapse].contains(engine.bossPattern)
        let body = roundBoss ? SKShapeNode(circleOfRadius: radius) : SKShapeNode(rectOf: CGSize(width: radius * 2, height: radius * 1.8), cornerRadius: enemy.kind == "swarmer" ? 4 : radius * 0.5)
        body.name = "hull"
        body.fillColor = UIColor(hex: enemy.kind == "repair" ? "8CAD8A" : enemy.kind == "shield" ? "839CC1" : enemy.boss ? engine.biome.palette[1] : "8B7572")
        body.strokeColor = UIColor(hex: "E4B1A0"); body.lineWidth = enemy.boss ? 4 : 2; root.addChild(body)
        if enemy.boss {
            let patternIndex = BossPattern.allCases.firstIndex(of: engine.bossPattern) ?? 0
            let count = 2 + patternIndex % 4
            for index in 0..<count {
                let angle = Double(index) * .pi * 2 / Double(count) + Double(patternIndex) * 0.3
                let module = SKShapeNode(rectOf: CGSize(width: 16, height: 22), cornerRadius: 4)
                module.fillColor = UIColor(hex: engine.biome.palette[2]); module.strokeColor = UIColor(hex: "10252D"); module.lineWidth = 2
                module.position = CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
                module.zRotation = CGFloat(angle); module.zPosition = -1; root.addChild(module)
            }
        }
        let eye = SKShapeNode(rectOf: CGSize(width: radius, height: 4), cornerRadius: 2); eye.fillColor = UIColor(hex: "FFC88C"); eye.strokeColor = .clear; root.addChild(eye)
        for x in [-1,1] {
            let leg = SKShapeNode(rectOf: CGSize(width: radius * 0.65, height: radius * 0.6), cornerRadius: 3); leg.fillColor = UIColor(hex: "374A4D"); leg.strokeColor = .clear; leg.position = CGPoint(x: CGFloat(x) * radius * 0.85, y: -radius * 0.6); leg.zPosition = -1; root.addChild(leg)
        }
        let bar = SKShapeNode(rectOf: CGSize(width: radius * 2, height: 3), cornerRadius: 1); bar.fillColor = .systemOrange; bar.strokeColor = .clear; bar.position.y = radius + 7; bar.name = "health"; root.addChild(bar)
        return root
    }
    private func render(_ effect: CombatEffect) {
        guard effectsLayer.children.count < 350 else { return }
        let color = UIColor(hex: goldenTrails ? "FFD878" : effect.style == .arc ? "83EAFF" : effect.style == .beam ? "BC9BFF" : engine.biome.palette[2])
        if effect.damage > 0 {
            if engine.elapsed - lastShotSoundAt >= 0.18 { lastShotSoundAt = engine.elapsed; AudioBus.shared.play(.weapon, preferences: engine.profile.preferences) }
            let path = CGMutablePath()
            let start = point(effect.from), end = point(effect.to)
            if effect.style == .orbital { path.move(to: CGPoint(x: end.x, y: end.y + arenaScale * 0.35)); path.addLine(to: end) }
            else {
                path.move(to: start)
                if effect.style == .arc {
                    let dx = end.x - start.x, dy = end.y - start.y
                    let length = max(1, hypot(dx, dy))
                    for segment in 1..<6 {
                        let t = CGFloat(segment) / 6, jag = CGFloat(segment % 2 == 0 ? 7 : -7) * unitScale
                        path.addLine(to: CGPoint(x: start.x + dx * t - dy / length * jag, y: start.y + dy * t + dx / length * jag))
                    }
                }
                path.addLine(to: end)
            }
            let trail = SKShapeNode(path: path); trail.strokeColor = color
            trail.lineWidth = (effect.style == .beam || effect.style == .orbital ? 6 : effect.critical ? 4 : 2) * unitScale
            trail.glowWidth = effect.style == .beam ? 3 * unitScale : 0; effectsLayer.addChild(trail)
            trail.run(.sequence([.fadeOut(withDuration: 0.18), .removeFromParent()]))
            if effect.style == .missile || effect.style == .orbital {
                let blast = SKShapeNode(circleOfRadius: arenaScale * (effect.style == .orbital ? 0.16 : 0.08))
                blast.position = end; blast.strokeColor = color; blast.lineWidth = 3; blast.fillColor = color.withAlphaComponent(0.12)
                effectsLayer.addChild(blast); blast.run(.sequence([.fadeOut(withDuration: 0.3), .removeFromParent()]))
                AudioBus.shared.play(.explosion, preferences: engine.profile.preferences)
            }
            if engine.profile.preferences.damageNumbers {
                let label = SKLabelNode(fontNamed: "AvenirNext-Bold"); label.text = String(effect.damage); label.fontSize = effect.critical ? 19 : 13; label.fontColor = effect.critical ? .systemYellow : .white; label.position = point(effect.to); effectsLayer.addChild(label)
                let exit: SKAction = engine.profile.preferences.reducedMotion ? .fadeOut(withDuration: 0.45) : .group([.moveBy(x: 0, y: 20, duration: 0.45), .fadeOut(withDuration: 0.45)])
                label.run(.sequence([exit, .removeFromParent()]))
            }
            let count = engine.profile.preferences.reducedMotion ? 0 : Int(engine.profile.preferences.particleIntensity * 6)
            for index in 0..<count {
                let spark = SKShapeNode(circleOfRadius: 2); spark.fillColor = color; spark.strokeColor = .clear; spark.position = point(effect.to); effectsLayer.addChild(spark)
                let angle = Double(index) * .pi * 2 / Double(max(1, count))
                spark.run(.sequence([.group([.moveBy(x: cos(angle) * 17, y: sin(angle) * 17, duration: 0.2), .fadeOut(withDuration: 0.2)]), .removeFromParent()]))
            }
        } else {
            let ring = SKShapeNode(circleOfRadius: effect.damage == -1 ? size.width * 0.14 : 30)
            ring.position = point(effect.to); ring.strokeColor = .systemOrange; ring.lineWidth = 3; ring.fillColor = UIColor.orange.withAlphaComponent(0.1); effectsLayer.addChild(ring)
            let action: SKAction = engine.profile.preferences.reducedMotion || effect.damage == -1 ? .wait(forDuration: effect.remaining) : .scale(to: 3, duration: effect.remaining)
            ring.run(.sequence([action, .removeFromParent()]))
        }
    }
}
extension UIColor {
    convenience init(hex: String) {
        let value = UInt64(hex, radix: 16) ?? 0
        self.init(red: CGFloat((value >> 16) & 255) / 255, green: CGFloat((value >> 8) & 255) / 255, blue: CGFloat(value & 255) / 255, alpha: 1)
    }
}
