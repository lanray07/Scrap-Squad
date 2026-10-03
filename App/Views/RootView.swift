import SwiftUI
import ScrapCore

struct RootView: View {
    @State var store: GameStore
    @State private var commerce = CommerceService()
    @State private var gameCenter = GameCenterService()
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    var body: some View {
        @Bindable var store = store
        VStack(spacing: 0) {
            ResourceBar()
            TabView(selection: $store.selectedTab) {
                CityView().tabItem { Label { LText("nav.city") } icon: { Image(systemName: "building.2.fill") } }.tag(0)
                SquadView().tabItem { Label { LText("nav.squad") } icon: { Image(systemName: "person.3.fill") } }.tag(1)
                BattleLobby().tabItem { Label { LText("nav.battle") } icon: { Image(systemName: "bolt.shield.fill") } }.tag(2)
                BlueprintView().tabItem { Label { LText("nav.blueprints") } icon: { Image(systemName: "square.stack.3d.up.fill") } }.tag(3)
                ShopView().tabItem { Label { LText("nav.shop") } icon: { Image(systemName: "bag.fill") } }.tag(4)
            }.tint(Theme.gold)
        }
        .background(Theme.ink).foregroundStyle(.white).preferredColorScheme(.dark)
        .environment(store).environment(commerce).environment(gameCenter)
        .environment(\.locale, LocaleManager.locale(store.profile.preferences.locale))
        .sheet(isPresented: $store.workshopPresented) { WorkshopView() }
        .sheet(isPresented: $store.settingsPresented) { SettingsView() }
        .sheet(isPresented: $store.onboardingPresented) {
            VStack(spacing: 24) {
                RobotPortrait(robot: store.content.robots[0]).frame(width: 180, height: 180)
                PageHeading(title: "tutorial.title", subtitle: "tutorial.body")
                ActionButton(key: "tutorial.start") { store.onboardingPresented = false; store.save() }
            }.padding(28).presentationDetents([.large]).interactiveDismissDisabled()
        }
        .sheet(isPresented: Binding(get: { store.offline != nil && !store.onboardingPresented }, set: { _ in })) {
            if let reward = store.offline {
                VStack(spacing: 24) {
                    Image(systemName: "shippingbox.fill").font(.system(size: 72)).foregroundStyle(Theme.gold)
                    PageHeading(title: "offline.title", subtitle: "offline.description")
                    HStack { LText("offline.away"); Spacer(); Text(LocalizedFormatting.duration(reward.seconds)) }
                    HStack { LText("currency.scrap"); Spacer(); Text(reward.scrap, format: .number) }
                    HStack { LText("currency.credits"); Spacer(); Text(reward.credits, format: .number) }
                    ActionButton(key: "offline.claim", symbol: "checkmark") { store.claimOffline() }
                }.padding(28).presentationDetents([.medium, .large]).interactiveDismissDisabled()
            }
        }
        .alert(Text(LocalizationManager.string("common.error")), isPresented: Binding(get: { store.errorKey != nil }, set: { if !$0 { store.errorKey = nil } })) {
            Button("common.ok", role: .cancel) { store.errorKey = nil }
        } message: { LText(store.errorKey ?? "common.error") }
        .onChange(of: scenePhase) { _, phase in store.sceneChanged(phase) }
        .onAppear { if systemReduceMotion { store.profile.preferences.reducedMotion = true } }
        .onChange(of: systemReduceMotion) { _, enabled in if enabled { store.profile.preferences.reducedMotion = true } }
        .task { await commerce.start(); gameCenter.authenticate() }
    }
}

struct CityView: View {
    @Environment(GameStore.self) var store
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                PageHeading(title: "city.title", subtitle: "city.subtitle")
                CityIllustration().frame(height: 240).background(Theme.surface, in: RoundedRectangle(cornerRadius: 28))
                HStack { LText("city.level"); Text(store.profile.cityLevel, format: .number); Spacer(); LText("currency.scrap").foregroundStyle(Theme.muted) }
                ActionButton(key: "city.workshop", symbol: "wrench.and.screwdriver.fill") { store.workshopPresented = true }
                ForEach(store.content.buildings) { building in
                    let level = store.profile.buildingLevels[building.id, default: 0]
                    Panel {
                        HStack(spacing: 16) {
                            Image(systemName: building.symbol).font(.title2).foregroundStyle(level == 0 ? Theme.muted : Theme.gold).frame(width: 40)
                            VStack(alignment: .leading, spacing: 6) {
                                LText(building.nameKey).font(.headline)
                                LText(building.descriptionKey).font(.caption).foregroundStyle(Theme.muted)
                                HStack { LText("city.level.label"); Text(level, format: .number) }.font(.caption)
                            }
                            Spacer()
                        }
                        if level < building.maxLevel {
                            Button {
                                store.perform { try Progression.upgradeBuilding(building, profile: &$0, content: store.content) }
                                Feedback.play(.build, preferences: store.profile.preferences)
                            } label: {
                                HStack { LText("city.upgrade"); Spacer(); Image(systemName: "gearshape.fill"); Text(Progression.cost(base: building.baseCost, level: level, economy: store.content.economy), format: .number) }
                            }.tint(Theme.gold).padding(.top, 12).frame(minHeight: 44)
                        } else { LText("common.max").foregroundStyle(Theme.mint) }
                    }
                }
                Panel {
                    LText("city.missions").font(.title3.bold())
                    mission(weekly: false)
                    Divider().padding(.vertical, 12)
                    mission(weekly: true)
                    LText("mission.note").font(.caption).foregroundStyle(Theme.muted).padding(.top, 12)
                }
            }.padding(20).frame(maxWidth: 760)
        }.background(Theme.ink)
    }
    func mission(weekly: Bool) -> some View {
        let amount = weekly ? store.profile.weeklyBosses : store.profile.dailyKills
        let goal = weekly ? 3 : 60
        let claimed = weekly ? store.profile.weeklyClaimed : store.profile.dailyClaimed
        return VStack(alignment: .leading, spacing: 8) {
            LText(weekly ? "mission.weekly" : "mission.daily").font(.subheadline.bold()).padding(.top, 12)
            ProgressView(value: Double(min(amount, goal)), total: Double(goal)).tint(Theme.mint)
            HStack {
                Text("\(min(amount, goal)) / \(goal)").monospacedDigit()
                Spacer()
                Button { store.perform { try Progression.claimMission(weekly: weekly, profile: &$0, now: Date()) } } label: { LText(claimed ? "mission.claimed" : "mission.claim") }
                    .disabled(amount < goal || claimed).tint(Theme.gold).frame(minHeight: 44)
            }.font(.caption)
        }
    }
}
struct CityIllustration: View {
    @Environment(GameStore.self) var store
    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(colors: [Color(hex: "325361"), Theme.ink], startPoint: .top, endPoint: .bottom)
                Circle().fill(Theme.gold.opacity(0.8)).frame(width: 70).offset(x: 100, y: -55)
                ForEach(Array(store.content.buildings.prefix(6).enumerated()), id: \.element.id) { index, building in
                    let level = store.profile.buildingLevels[building.id, default: 0]
                    VStack(spacing: 0) {
                        Image(systemName: building.symbol).font(.title3).foregroundStyle(level > 0 ? Theme.gold : Theme.muted).padding(15)
                            .frame(width: 64, height: CGFloat(55 + level * 5)).background(level > 0 ? Theme.surface : Color(hex: "304047"), in: UnevenRoundedRectangle(topLeadingRadius: 12, topTrailingRadius: 12))
                        Rectangle().fill(Theme.muted.opacity(0.3)).frame(width: 72, height: 8)
                    }.position(x: geo.size.width * (Double(index % 3) + 0.5) / 3, y: index < 3 ? 120 : 193)
                }
                RobotPortrait(robot: store.content.robots[0]).frame(width: 75, height: 75).position(x: geo.size.width * 0.5, y: 200)
            }.clipShape(RoundedRectangle(cornerRadius: 28))
        }.accessibilityElement(children: .ignore).accessibilityLabel(Text(LocalizationManager.string("city.title"))).accessibilityValue(Text(store.profile.cityLevel, format: .number))
    }
}
