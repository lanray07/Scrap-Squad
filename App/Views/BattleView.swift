import SwiftUI
import SpriteKit
import ScrapCore

struct BattleLobby: View {
    @Environment(GameStore.self) var store
    @Environment(CommerceService.self) var commerce
    @State private var mode: GameMode = .campaign
    @State private var zone = 0
    @State private var session: BattleSession?
    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                PageHeading(title: "battle.title", subtitle: "battle.subtitle")
                let biome = store.content.biomes[min(zone, store.content.biomes.count - 1)]
                Panel {
                    HStack { Image(systemName: "mountain.2.fill").font(.system(size: 50)).foregroundStyle(Color(hex: biome.palette[2])); Spacer(); VStack(alignment: .trailing) { LText(biome.nameKey).font(.title2.bold()); LText(biome.bossKey).font(.caption).foregroundStyle(Theme.muted) } }
                    HStack { LText("battle.weakness"); Spacer(); Image(systemName: icon(biome.weakness)); LText("element." + biome.weakness.rawValue); Text("+75%") }.font(.caption).padding(.top, 16)
                }
                Picker(selection: $zone) {
                    ForEach(0...store.profile.zone, id: \.self) { index in LText(store.content.biomes[index].nameKey).tag(index) }
                } label: { LText("battle.zone") }
                Picker(selection: $mode) {
                    ForEach(GameMode.allCases) { LText("mode." + $0.rawValue).tag($0) }
                } label: { LText("battle.mode") }
                Panel {
                    LText("battle.weapon").font(.caption).foregroundStyle(Theme.muted)
                    if let weapon = store.content.weapons.first(where: { $0.id == store.profile.equippedWeapon }) {
                        HStack { Image(systemName: icon(weapon.element)).font(.title).foregroundStyle(Theme.rarity(weapon.rarity)); LText(weapon.nameKey).font(.title3.bold()); Spacer(); Button { store.workshopPresented = true } label: { Image(systemName: "wrench.and.screwdriver") }.frame(minWidth: 44, minHeight: 44) }
                    }
                    HStack {
                        ForEach(store.profile.squad, id: \.self) { id in
                            if let robot = store.content.robots.first(where: { $0.id == id }) { RobotPortrait(robot: robot).frame(width: 70, height: 75) }
                        }
                    }
                }
                ActionButton(key: "battle.deploy", symbol: "bolt.shield.fill") {
                    var snapshot = store.profile; snapshot.zone = zone
                    session = BattleSession(content: store.content, profile: snapshot, mode: mode, finishes: commerce.robotFinishes)
                }
                LText("battle.move").font(.subheadline).foregroundStyle(Theme.muted)
                LText("battle.survival.note").font(.caption).foregroundStyle(Theme.muted)
            }.padding(20).frame(maxWidth: 760)
        }.background(Theme.ink).onAppear { zone = min(zone, store.profile.zone) }
            .fullScreenCover(item: $session) { BattleView(session: $0) }
    }
}
@MainActor @Observable final class BattleSession: Identifiable {
    let id = UUID()
    let engine: BattleEngine
    let scene: BattleScene
    var revision = 0
    var paused = false
    var claimed = false
    init(content: GameContent, profile: PlayerProfile, mode: GameMode, finishes: [String: String]) {
        engine = BattleEngine(content: content, profile: profile, mode: mode)
        scene = BattleScene(engine: engine, finishes: finishes)
        scene.refresh = { [weak self] in self?.revision += 1 }
    }
}
struct BattleView: View {
    @Environment(GameStore.self) var store
    @Environment(GameCenterService.self) var gameCenter
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var phase
    @State var session: BattleSession
    @State private var dragOrigin: CGPoint?
    @State private var priority = TargetPriority.nearest
    var body: some View {
        let _ = session.revision
        let engine = session.engine
        ZStack {
            Theme.ink.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        LText(engine.biome.nameKey).font(.headline)
                        Text(LocalizedFormatting.duration(engine.elapsed)).font(.caption.monospacedDigit()).foregroundStyle(Theme.muted)
                    }
                    Spacer()
                    Text(engine.kills, format: .number).font(.title3.bold())
                    Image(systemName: "gearshape.fill").foregroundStyle(Theme.gold)
                    Button { pause() } label: { Image(systemName: "pause.fill").padding(14) }.accessibilityLabel(Text(LocalizationManager.string("battle.pause")))
                }.padding(.horizontal, 20).padding(.top, 12)
                ProgressView(value: engine.health, total: max(1, engine.maxHealth)).tint(Theme.mint).padding(.horizontal, 20).padding(.vertical, 10)
                    .accessibilityLabel(Text(LocalizationManager.string("battle.health")))
                if let health = engine.bossHealth {
                    HStack { LText(engine.biome.bossKey).font(.caption.bold()); ProgressView(value: health).tint(.orange) }.padding(.horizontal, 20).padding(.bottom, 6)
                    if let armor = engine.bossArmor {
                        HStack { LText(armor > 0 ? "battle.armor" : "battle.armor.broken").font(.caption2); if armor > 0 { ProgressView(value: armor).tint(Theme.muted) } }.padding(.horizontal, 20).padding(.bottom, 6)
                    }
                }
                SpriteView(scene: session.scene, options: [.ignoresSiblingOrder])
                    .accessibilityLabel(Text(LocalizationManager.string("accessibility.arena")))
                    .gesture(DragGesture(minimumDistance: 0).onChanged { value in
                        if dragOrigin == nil { dragOrigin = value.startLocation }
                        if let origin = dragOrigin {
                            let dx = value.location.x - origin.x, dy = origin.y - value.location.y
                            session.scene.movement = hypot(dx, dy) < 8 ? Vector() : Vector(Double(dx), Double(dy))
                        }
                    }.onEnded { _ in dragOrigin = nil; session.scene.movement = Vector() })
                HStack {
                    Picker(selection: $priority) { ForEach(TargetPriority.allCases, id: \.self) { LText("priority." + $0.rawValue).tag($0) } } label: { LText("battle.priority") }
                        .onChange(of: priority) { _, value in engine.priority = value }
                    Spacer()
                    Button {
                        engine.activateAbility(); Feedback.play(.ability, preferences: store.profile.preferences)
                    } label: {
                        HStack { Image(systemName: "bolt.fill"); if engine.abilityCooldown > 0 { Text(Int(ceil(engine.abilityCooldown)), format: .number) } else { LText("battle.ability") } }
                            .font(.headline).foregroundStyle(Theme.ink).padding(18).background(Theme.gold, in: Capsule())
                    }.disabled(engine.abilityCooldown > 0)
                }.padding(16)
            }
            if session.paused { pauseOverlay }
            else if engine.state == .choosing { choicesOverlay }
            else if engine.state == .victory || engine.state == .defeated { resultsOverlay }
        }.preferredColorScheme(.dark).foregroundStyle(.white)
            .onChange(of: phase) { _, value in if value != .active { pause() } }
            .onDisappear { session.scene.isPaused = true }
    }
    func pause() { session.paused = true; session.scene.isPaused = true; session.scene.movement = Vector() }
    var pauseOverlay: some View {
        modal {
            LText("battle.paused").font(.largeTitle.bold())
            ActionButton(key: "battle.resume", symbol: "play.fill") { session.paused = false; session.scene.isPaused = false }
            ActionButton(key: "battle.retreat", symbol: "arrow.uturn.backward", secondary: true) { session.engine.retreat(); session.paused = false; session.scene.isPaused = false; session.revision += 1 }
        }
    }
    var choicesOverlay: some View {
        modal {
            PageHeading(title: "battle.choose", subtitle: "battle.choice.subtitle")
            ForEach(session.engine.choices) { choice in
                Button {
                    session.engine.choose(choice); session.revision += 1
                    Feedback.play(.build, preferences: store.profile.preferences)
                } label: {
                    HStack(spacing: 16) {
                        Image(systemName: choice.symbol).font(.title).foregroundStyle(Theme.gold).frame(width: 40)
                        VStack(alignment: .leading, spacing: 6) { LText(choice.nameKey).font(.headline); LText(choice.descriptionKey).font(.caption).foregroundStyle(Theme.muted) }
                        Spacer()
                    }.padding(18).background(Theme.surface, in: RoundedRectangle(cornerRadius: 18))
                }.buttonStyle(.plain)
            }
        }
    }
    var resultsOverlay: some View {
        modal {
            Image(systemName: session.engine.state == .victory ? "flag.checkered" : "wrench.and.screwdriver.fill").font(.system(size: 60)).foregroundStyle(Theme.gold)
            PageHeading(title: session.engine.state == .victory ? "battle.victory" : "battle.defeat", subtitle: "battle.results")
            HStack { LText("battle.kills"); Spacer(); Text(session.engine.kills, format: .number) }
            HStack { LText("battle.score"); Spacer(); Text(session.engine.score, format: .number) }
            ActionButton(key: "battle.return", symbol: "house.fill") { claim(); dismiss() }
        }.onAppear { claim() }
    }
    func claim() {
        guard !session.claimed else { return }
        let reward = session.engine.reward()
        store.perform { _ = Progression.apply(reward, profile: &$0, content: store.content, now: Date()) }
        session.claimed = true
        gameCenter.report(profile: store.profile, content: store.content, reward: reward)
    }
    func modal<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ZStack { Theme.ink.opacity(0.97).ignoresSafeArea(); ScrollView { VStack(spacing: 20, content: content).padding(28).frame(maxWidth: 620) }.frame(maxWidth: .infinity) }
    }
}
