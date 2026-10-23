import SpriteKit
import ScrapCore

/// Additive rig overlays leave all base portraits, signature skins and weapon effects intact.
@MainActor final class SalvageRenderer {
    private let root = SKNode()
    private let scout: SKNode
    private let beacon = SKShapeNode(circleOfRadius: 1)
    private let beaconLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let scoutLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private var pickups: [Int: SKNode] = [:]
    private var rigTypes: [Int: SalvageSystem] = [:]
    init(world: SKNode, scout: SKNode) {
        self.scout = scout
        world.addChild(root); root.zPosition = 2
        scout.zPosition = 5; root.addChild(scout)
        scoutLabel.fontSize = 12; scoutLabel.fontColor = UIColor(hex: "73E5D1"); scoutLabel.position.y = 40
        scout.addChild(scoutLabel)
        beacon.lineWidth = 3; beacon.strokeColor = UIColor(hex: "73E5D1"); beacon.fillColor = UIColor(hex: "73E5D1").withAlphaComponent(0.08)
        root.addChild(beacon)
        beaconLabel.fontSize = 13; beaconLabel.fontColor = .white; beaconLabel.position.y = 8; beacon.addChild(beaconLabel)
    }
    func update(engine: BattleEngine, robots: [SKNode], enemies: [Int: SKNode], scale: CGFloat, unitScale: CGFloat) {
        guard let operation = engine.salvage else { return }
        func point(_ value: Vector) -> CGPoint { CGPoint(x: value.x * scale, y: value.y * scale) }
        scout.position = point(operation.escort); scout.setScale(unitScale * 0.8)
        scoutLabel.text = LocalizationManager.string(operation.rescued ? "salvage.scout.follow" : "salvage.scout.rescue", locale: engine.profile.preferences.locale)
        scout.alpha = operation.rescued ? 1 : 0.65
        beacon.position = point(operation.extraction)
        let radius = scale * 0.13
        beacon.path = CGPath(ellipseIn: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2), transform: nil)
        beacon.alpha = operation.readyForExtraction ? 1 : 0.35
        beacon.strokeColor = UIColor(hex: operation.contested ? "FFB65C" : "73E5D1")
        beaconLabel.text = LocalizationManager.string("salvage.beacon", locale: engine.profile.preferences.locale) + " \(Int(operation.extractionProgress))/12"
        let ids = Set(operation.drops.map(\.id))
        for id in Array(pickups.keys) where !ids.contains(id) { pickups.removeValue(forKey: id)?.removeFromParent() }
        for drop in operation.drops {
            let node: SKNode
            if let existing = pickups[drop.id] { node = existing }
            else {
                let box = SKShapeNode(rectOf: CGSize(width: 22, height: 22), cornerRadius: 6)
                box.fillColor = UIColor(hex: drop.system.color); box.strokeColor = .white; box.lineWidth = 2
                let glyph = SKLabelNode(fontNamed: "AvenirNext-Bold")
                glyph.text = String(drop.system.rawValue.prefix(1)).uppercased(); glyph.fontSize = 14; glyph.fontColor = UIColor(hex: "10252D"); glyph.verticalAlignmentMode = .center
                box.addChild(glyph); root.addChild(box); pickups[drop.id] = box; node = box
            }
            node.position = point(drop.position); node.setScale(unitScale)
            node.alpha = drop.expiresAt - engine.elapsed < 4 ? 0.55 : 1
        }
        for enemy in engine.enemies {
            guard let node = enemies[enemy.id] else { continue }
            let mark: SKShapeNode
            if let existing = node.childNode(withName: "salvage-system") as? SKShapeNode { mark = existing }
            else {
                mark = SKShapeNode(rectOf: CGSize(width: 28, height: 5), cornerRadius: 2)
                mark.name = "salvage-system"; mark.position.y = -27; node.addChild(mark)
            }
            mark.fillColor = UIColor(hex: operation.focus.color); mark.strokeColor = .white
            mark.xScale = max(0.02, operation.systemFraction(enemyID: enemy.id, maxHealth: enemy.maxHealth))
            mark.alpha = operation.disabled[enemy.id, default: []].contains(operation.focus) ? 0.15 : 1
        }
        for (index, robot) in robots.enumerated() where index < engine.profile.squad.count {
            let type = operation.modules[engine.profile.squad[index]]
            guard rigTypes[index] != type else { continue }
            robot.childNode(withName: "salvage-rig")?.removeFromParent(); rigTypes[index] = type
            guard let type else { continue }
            let rig = SKNode(); rig.name = "salvage-rig"; rig.zPosition = 8
            if type == .armor {
                let shield = SKShapeNode(circleOfRadius: 29); shield.lineWidth = 4; shield.strokeColor = UIColor(hex: type.color); shield.fillColor = .clear; rig.addChild(shield)
            } else {
                for side in [-1.0, 1.0] {
                    let piece = SKShapeNode(rectOf: CGSize(width: type == .weapon ? 9 : 22, height: type == .weapon ? 25 : 7), cornerRadius: 3)
                    piece.fillColor = UIColor(hex: type.color); piece.strokeColor = .white
                    piece.position = CGPoint(x: side * (type == .weapon ? 24 : 15), y: type == .weapon ? 5 : -23)
                    rig.addChild(piece)
                }
            }
            robot.addChild(rig)
        }
    }
}
