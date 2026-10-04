import SwiftUI
import SpriteKit
import ScrapCore

@MainActor @Observable private final class CosmeticPreviewSession {
    let scene: BattleScene
    let engine: BattleEngine
    let finishes: [RobotFinish]
    init(pack: CosmeticPack, content: GameContent, catalog: CosmeticCatalog, preferences: Preferences) {
        let owned = catalog.effectiveOwnership([pack.id])
        finishes = catalog.availableFinishes(owned: owned)
        var profile = PlayerProfile()
        profile.preferences = preferences; profile.preferences.masterVolume = 0
        let ids = finishes.map(\.robotID)
        profile.squad = ids.isEmpty ? ["bolt", "patch"] : ids
        profile.unlockedSquadCapacity = 4; profile.unlockedRobots.formUnion(ids)
        profile.robotLevels = Dictionary(uniqueKeysWithValues: profile.squad.map { ($0, 50) })
        profile.weaponLevels = ["blaster": 3]
        // A separate, disposable engine. No profile save, reward claim or ownership changes.
        engine = BattleEngine(content: content, profile: profile, mode: .survival, seed: 42)
        scene = BattleScene(engine: engine, finishes: Dictionary(uniqueKeysWithValues: finishes.map { ($0.robotID, $0) }), goldenTrails: catalog.hasFounderExtras(owned: owned), weaponEffect: catalog.availableWeaponEffects(owned: owned).first)
        scene.refresh = { [weak self] in
            guard let self else { return }
            if self.engine.state == .choosing, let choice = self.engine.choices.first { self.engine.choose(choice) }
        }
    }
}
struct CosmeticPreviewSheet: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var session: CosmeticPreviewSession
    @State private var victory = false
    let pack: CosmeticPack
    init(pack: CosmeticPack, content: GameContent, catalog: CosmeticCatalog, preferences: Preferences) {
        self.pack = pack
        _session = State(initialValue: CosmeticPreviewSession(pack: pack, content: content, catalog: catalog, preferences: preferences))
    }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    LText("premium.preview.note").font(.caption).foregroundStyle(Theme.muted)
                    Picker(LocalizationManager.string("premium.preview.mode"), selection: $victory) {
                        LText("premium.arena").tag(false); LText("premium.victory").tag(true)
                    }.pickerStyle(.segmented)
                    if victory {
                        TimelineView(.animation(minimumInterval: 0.22, paused: reduceMotion)) { timeline in
                            let frame = reduceMotion ? 0 : Int(timeline.date.timeIntervalSinceReferenceDate * 4) % 4
                            HStack {
                                ForEach(session.finishes) { finish in
                                    if let skin = finish.skin {
                                        Image(uiImage: SignatureRobotArt.image(skin, frame: frame, victory: true)).resizable().scaledToFit()
                                            .offset(y: reduceMotion ? 0 : frame % 2 == 0 ? -5 : 0)
                                            .accessibilityLabel(Text(LocalizationManager.string(finish.nameKey)))
                                    }
                                }
                            }.frame(height: 280)
                        }
                        if session.finishes.isEmpty { LText("premium.prism.detail") }
                    } else {
                        SpriteView(scene: session.scene).frame(height: 390).clipShape(RoundedRectangle(cornerRadius: 20))
                            .accessibilityIdentifier("cosmetic-preview-arena")
                            .accessibilityLabel(Text(LocalizationManager.string("premium.arena")))
                            .gesture(DragGesture(minimumDistance: 0).onChanged { value in
                                session.scene.movement = Vector(Double(value.translation.width) / 80, -Double(value.translation.height) / 80)
                            }.onEnded { _ in session.scene.movement = Vector() })
                        LText("premium.preview.drag").font(.caption)
                        Button { _ = session.engine.activateDash(direction: session.scene.movement) } label: { LText("battle.dash") }.frame(minHeight: 44).accessibilityIdentifier("preview-dash")
                    }
                    LText(pack.detailKey).foregroundStyle(Theme.muted)
                }.padding(20).frame(maxWidth: 760)
            }.background(Theme.ink)
                .navigationTitle(LocalizationManager.string(pack.nameKey))
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button { dismiss() } label: { LText("premium.done") }.accessibilityIdentifier("preview-done") } }
                .onChange(of: victory) { _, value in session.scene.simulationPaused = value || scenePhase != .active }
                .onChange(of: scenePhase) { _, value in session.scene.simulationPaused = value != .active || victory }
                .onDisappear { session.scene.simulationPaused = true; session.scene.isPaused = true }
        }
    }
}
struct SignatureVictoryPose: View {
    @Environment(\.accessibilityReduceMotion) private var systemReducedMotion
    let finishes: [RobotFinish]
    let reducedMotion: Bool
    var body: some View {
        if !finishes.isEmpty {
            TimelineView(.animation(minimumInterval: 0.22, paused: reducedMotion || systemReducedMotion)) { timeline in
                let frame = reducedMotion || systemReducedMotion ? 0 : Int(timeline.date.timeIntervalSinceReferenceDate * 4) % 4
                HStack {
                    ForEach(finishes.sorted { $0.id < $1.id }) { finish in
                        if let skin = finish.skin {
                            Image(uiImage: SignatureRobotArt.image(skin, frame: frame, victory: true)).resizable().scaledToFit()
                                .offset(y: reducedMotion || systemReducedMotion ? 0 : frame % 2 == 0 ? -4 : 0)
                                .accessibilityLabel(Text(LocalizationManager.string(finish.nameKey)))
                        }
                    }
                }.frame(height: 110)
            }
        }
    }
}
