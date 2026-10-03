import SpriteKit
import UIKit
import ScrapCore

@MainActor final class BattleScene: SKScene {
    let engine: BattleEngine
    let finishes: [String: String]
    var movement = Vector()
    var refresh: (() -> Void)?
    private var previous: TimeInterval = 0
    private var hudAt = 0.0
    private var renderedEffects = Set<Int>()
    private var enemyNodes: [Int: SKNode] = [:]
    private var warnings: [Int: SKShapeNode] = [:]
    private var robotNodes: [SKNode] = []
    private let world = SKNode()
    private let effectsLayer = SKNode()
    private var lastKills = 0
    init(engine: BattleEngine, finishes: [String: String]) {
        self.engine = engine
        self.finishes = finishes
        super.init(size: CGSize(width: 600, height: 800))
        scaleMode = .resizeFill
        backgroundColor = UIColor(hex: engine.biome.palette[0])
    }
    required init?(coder: NSCoder) { fatalError("Programmatic scene only") }
    override func didMove(to view: SKView) {
        guard world.parent == nil else { return }
        addChild(world); addChild(effectsLayer)
        let grid = SKShapeNode()
        let path = CGMutablePath()
        for x in stride(from: 0.0, through: Double(size.width), by: 60) { path.move(to: CGPoint(x: x, y: 0)); path.addLine(to: CGPoint(x: x, y: size.height)) }
        for y in stride(from: 0.0, through: Double(size.height), by: 60) { path.move(to: CGPoint(x: 0, y: y)); path.addLine(to: CGPoint(x: size.width, y: y)) }
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
    }
    override func update(_ currentTime: TimeInterval) {
        let dt = previous == 0 ? 0 : min(0.05, currentTime - previous); previous = currentTime
        engine.step(delta: dt, movement: movement)
        for (index, node) in robotNodes.enumerated() {
            let angle = Double(index) * .pi * 2 / Double(max(1, robotNodes.count))
            let offset = index == 0 ? Vector() : Vector(cos(angle), sin(angle)) * 0.055
            node.position = point(engine.player + offset)
            if !engine.profile.preferences.reducedMotion { node.zRotation = CGFloat(sin(currentTime * 4 + Double(index))) * 0.035 }
        }
        let ids = Set(engine.enemies.map(\.id))
        for id in Array(enemyNodes.keys) where !ids.contains(id) { enemyNodes.removeValue(forKey: id)?.removeFromParent(); warnings.removeValue(forKey: id)?.removeFromParent() }
        for enemy in engine.enemies {
            let node: SKNode
            if let existing = enemyNodes[enemy.id] { node = existing }
            else { node = makeEnemy(enemy); enemyNodes[enemy.id] = node; world.addChild(node) }
            node.position = point(enemy.position)
            node.alpha = enemy.kind == "burrower" && Int(engine.elapsed) % 5 < 2 ? 0.25 : 1
            if enemy.kind == "flying" && !engine.profile.preferences.reducedMotion { node.position.y += CGFloat(sin(currentTime * 5)) * 4 }
            if let bar = node.childNode(withName: "health") as? SKShapeNode { bar.xScale = max(0.01, enemy.health / enemy.maxHealth) }
            if enemy.windup > 0 {
                let warning: SKShapeNode
                if let existing = warnings[enemy.id] { warning = existing }
                else {
                    warning = SKShapeNode(circleOfRadius: (enemy.boss ? 0.18 : 0.07) * size.width)
                    warning.strokeColor = UIColor(hex: "FFB66C"); warning.lineWidth = 3
                    warning.fillColor = UIColor(hex: "F28C50").withAlphaComponent(0.13); warning.zPosition = 2
                    world.addChild(warning); warnings[enemy.id] = warning
                }
                warning.position = point(enemy.target)
            } else { warnings.removeValue(forKey: enemy.id)?.removeFromParent() }
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
    private func point(_ vector: Vector) -> CGPoint { CGPoint(x: vector.x * size.width, y: vector.y * size.height) }
    private func makeRobot(_ robot: Robot) -> SKNode {
        if let index = RobotArt.order.firstIndex(of: robot.id) {
            let atlas = SKTexture(imageNamed: "RobotAtlas")
            let rect = CGRect(x: Double(index % 4) / 4, y: index < 4 ? 0.5 : 0, width: 0.25, height: 0.5)
            let sprite = SKSpriteNode(texture: SKTexture(rect: rect, in: atlas))
            let dimension: CGFloat = robot.silhouette == "heavy" ? 60 : 48
            sprite.size = CGSize(width: dimension, height: dimension)
            if let tint = finishes[robot.id] { sprite.color = UIColor(hex: tint); sprite.colorBlendFactor = 0.45 }
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
        let body = SKShapeNode(rectOf: CGSize(width: radius * 2, height: radius * 1.8), cornerRadius: enemy.kind == "swarmer" ? 4 : radius * 0.5)
        body.fillColor = UIColor(hex: enemy.kind == "repair" ? "8CAD8A" : enemy.kind == "shield" ? "839CC1" : enemy.boss ? "B78062" : "8B7572")
        body.strokeColor = UIColor(hex: "E4B1A0"); body.lineWidth = enemy.boss ? 4 : 2; root.addChild(body)
        let eye = SKShapeNode(rectOf: CGSize(width: radius, height: 4), cornerRadius: 2); eye.fillColor = UIColor(hex: "FFC88C"); eye.strokeColor = .clear; root.addChild(eye)
        for x in [-1,1] {
            let leg = SKShapeNode(rectOf: CGSize(width: radius * 0.65, height: radius * 0.6), cornerRadius: 3); leg.fillColor = UIColor(hex: "374A4D"); leg.strokeColor = .clear; leg.position = CGPoint(x: CGFloat(x) * radius * 0.85, y: -radius * 0.6); leg.zPosition = -1; root.addChild(leg)
        }
        let bar = SKShapeNode(rectOf: CGSize(width: radius * 2, height: 3), cornerRadius: 1); bar.fillColor = .systemOrange; bar.strokeColor = .clear; bar.position.y = radius + 7; bar.name = "health"; root.addChild(bar)
        return root
    }
    private func render(_ effect: CombatEffect) {
        let color = UIColor(hex: engine.biome.palette[2])
        if effect.damage > 0 {
            let path = CGMutablePath(); path.move(to: point(effect.from)); path.addLine(to: point(effect.to))
            let trail = SKShapeNode(path: path); trail.strokeColor = color; trail.lineWidth = effect.critical ? 4 : 2; effectsLayer.addChild(trail)
            trail.run(.sequence([.fadeOut(withDuration: 0.18), .removeFromParent()]))
            if engine.profile.preferences.damageNumbers {
                let label = SKLabelNode(fontNamed: "AvenirNext-Bold"); label.text = String(effect.damage); label.fontSize = effect.critical ? 19 : 13; label.fontColor = effect.critical ? .systemYellow : .white; label.position = point(effect.to); effectsLayer.addChild(label)
                label.run(.sequence([.group([.moveBy(x: 0, y: 20, duration: 0.45), .fadeOut(withDuration: 0.45)]), .removeFromParent()]))
            }
            let count = Int(engine.profile.preferences.particleIntensity * 6)
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
