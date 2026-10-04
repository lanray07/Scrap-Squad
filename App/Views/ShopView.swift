import SwiftUI
import StoreKit
import ScrapCore

struct ShopView: View {
    @Environment(CommerceService.self) private var commerce
    @State private var signature = !ProcessInfo.processInfo.arguments.contains("--storekit-testing")
    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                PageHeading(title: "shop.title", subtitle: "shop.subtitle")
                if commerce.loading { ProgressView().accessibilityLabel(Text(LocalizationManager.string("shop.loading"))) }
                Picker(LocalizationManager.string("premium.catalog"), selection: $signature) {
                    LText("premium.classic").tag(false)
                    LText("premium.signature").tag(true)
                }.pickerStyle(.segmented).accessibilityIdentifier("shop-catalog")
                ForEach(commerce.configuration.packs.filter { ($0.id != "com.ScrapSquad.app.founder" && $0.id != "com.ScrapSquad.app.styles") == signature }.sorted { ($0.includes != nil ? 0 : 1) < ($1.includes != nil ? 0 : 1) }) { pack in CosmeticPackCard(pack: pack) }
                ActionButton(key: "shop.refresh", symbol: "arrow.clockwise", secondary: true) { Task { await commerce.refresh() } }
                    .disabled(commerce.loading).accessibilityIdentifier("shop-refresh")
                ActionButton(key: "shop.restore", symbol: "arrow.counterclockwise", secondary: true) { Task { await commerce.restore() } }
                    .disabled(commerce.loading).accessibilityIdentifier("shop-restore")
                if let key = commerce.messageKey { LText(key).font(.subheadline).foregroundStyle(Theme.gold).accessibilityIdentifier("shop-message") }
                LText("shop.note").font(.caption).foregroundStyle(Theme.muted)
                Link("Privacy Policy", destination: URL(string: "https://lanray07.github.io/Scrap-Squad/privacy.html")!)
            }.padding(20).frame(maxWidth: 760)
        }.background(Theme.ink)
    }
}
private struct CosmeticPackCard: View {
    @Environment(GameStore.self) private var store
    @Environment(CommerceService.self) private var commerce
    let pack: CosmeticPack
    @State private var preview: CosmeticPack?
    private var owned: Bool { commerce.effectiveOwnership.contains(pack.id) }
    private var product: Product? { commerce.products.first { $0.id == pack.id } }
    var body: some View {
        Panel {
            HStack {
                LText(pack.nameKey).font(.title2.bold())
                Spacer()
                if owned { Label { LText("cosmetic.owned") } icon: { Image(systemName: "checkmark.seal.fill") }.foregroundStyle(Theme.mint).accessibilityIdentifier("owned-" + pack.id) }
            }
            LText(pack.detailKey).font(.subheadline).foregroundStyle(Theme.muted)
            ForEach(pack.finishes) { finish in
                if let robot = store.content.robots.first(where: { $0.id == finish.robotID }) {
                    HStack(spacing: 16) {
                        RobotPortrait(robot: robot, previewFinish: finish).frame(width: 76, height: 84)
                        VStack(alignment: .leading, spacing: 6) {
                            LText(finish.nameKey).font(.headline)
                            LText(robot.nameKey).font(.caption).foregroundStyle(Theme.muted)
                            if !store.profile.unlockedRobots.contains(robot.id) { LText("cosmetic.robot.locked").font(.caption2).foregroundStyle(Theme.muted) }
                        }
                        Spacer()
                        if owned {
                            let selected = commerce.robotFinishes[finish.robotID]?.id == finish.id
                            Button {
                                commerce.setFinish(selected ? nil : finish, for: finish.robotID)
                            } label: { LText(selected ? "cosmetic.remove" : "cosmetic.equip") }
                                .frame(minWidth: 44, minHeight: 44).tint(Theme.gold)
                                .accessibilityIdentifier("equip-" + finish.id)
                                .accessibilityValue(Text(LocalizationManager.string(selected ? "cosmetic.equipped" : "cosmetic.original")))
                        }
                    }
                }
            }
            if let includes = pack.includes {
                HStack {
                    ForEach(commerce.configuration.availableFinishes(owned: [pack.id])) { finish in
                        if let skin = finish.skin {
                            Image(uiImage: SignatureRobotArt.image(skin)).resizable().scaledToFit().frame(height: 90)
                                .accessibilityLabel(Text(LocalizationManager.string(finish.nameKey)))
                        }
                    }
                }.frame(maxWidth: .infinity)
                ForEach(includes, id: \.self) { id in
                    if let component = commerce.configuration.packs.first(where: { $0.id == id }) {
                        HStack { LText(component.nameKey); Spacer(); if commerce.effectiveOwnership.contains(id) { LText("cosmetic.owned").foregroundStyle(Theme.mint) } }
                    }
                }
            }
            Button { preview = pack } label: { Label { LText("premium.preview") } icon: { Image(systemName: "play.rectangle.fill") } }
                .frame(minHeight: 44).tint(Theme.mint).accessibilityIdentifier("preview-" + pack.id)
            if let effect = pack.weaponEffect, owned {
                let selected = commerce.weaponEffect == effect
                Button { commerce.setWeaponEffect(selected ? nil : effect) } label: { LText(selected ? "cosmetic.remove" : "cosmetic.equip") }
                    .frame(minHeight: 44).tint(Theme.gold).accessibilityIdentifier("equip-effect-" + effect)
                    .accessibilityValue(Text(LocalizationManager.string(selected ? "cosmetic.equipped" : "cosmetic.original")))
            }
            if pack.founderExtras {
                Label { LText("cosmetic.trails") } icon: { Image(systemName: "sparkles") }.foregroundStyle(Theme.gold)
                Label { LText("cosmetic.badge") } icon: { Image(systemName: "star.circle.fill") }.foregroundStyle(Theme.gold)
                if owned {
                    Toggle(isOn: Binding(get: { commerce.goldenTrails }, set: { commerce.setGoldenTrails($0) })) { LText("cosmetic.trails.enable") }
                        .tint(Theme.gold).accessibilityIdentifier("golden-trails-toggle")
                    Toggle(isOn: Binding(get: { commerce.founderBadge }, set: { commerce.setFounderBadge($0) })) { LText("cosmetic.badge.enable") }
                        .tint(Theme.gold).accessibilityIdentifier("founder-badge-toggle")
                }
            }
            if !owned {
                if !commerce.configuration.canPurchase(pack.id, owned: commerce.entitlements) {
                    LText("premium.bundle.overlap").font(.caption).foregroundStyle(Theme.mint).accessibilityIdentifier("bundle-overlap")
                } else if let product {
                    Button { Task { await commerce.purchase(product) } } label: {
                        HStack { LText("cosmetic.buy"); Spacer(); Text(product.displayPrice) }
                            .font(.headline).padding(16).foregroundStyle(Theme.ink)
                            .background(Theme.gold, in: RoundedRectangle(cornerRadius: 14))
                    }.buttonStyle(.plain).disabled(commerce.loading).accessibilityIdentifier("buy-" + pack.id)
                } else { LText("shop.unavailable").font(.caption).foregroundStyle(Theme.muted) }
            }
            LText("cosmetic.once").font(.caption2).foregroundStyle(Theme.muted)
        }.sheet(item: $preview) { CosmeticPreviewSheet(pack: $0, content: store.content, catalog: commerce.configuration, preferences: store.profile.preferences) }
    }
}
