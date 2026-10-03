import SwiftUI
import ScrapCore

struct WorkshopView: View {
    @Environment(GameStore.self) var store
    @Environment(\.dismiss) private var dismiss
    @State private var roulette = false
    @State private var a = "blaster"
    @State private var b = "rocket"
    @State private var reveal: Weapon?
    @State private var revealing = false
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    PageHeading(title: "lab.title", subtitle: "lab.subtitle")
                    Picker(selection: $roulette) {
                        LText("lab.recipes").tag(false); LText("lab.roulette").tag(true)
                    } label: { LText("lab.recipes") }.pickerStyle(.segmented)
                    if roulette { roulettePanel } else {
                        ForEach(store.content.recipes) { recipe in
                            if let weapon = store.content.weapons.first(where: { $0.id == recipe.result }) {
                                Panel {
                                    HStack { Image(systemName: icon(weapon.element)).foregroundStyle(Theme.rarity(weapon.rarity)).font(.title); LText(weapon.nameKey).font(.headline); Spacer(); LText("rarity." + weapon.rarity.rawValue).font(.caption) }
                                    HStack {
                                        LText("weapon." + recipe.weapon); Text("+"); LText("component." + recipe.component)
                                    }.font(.caption).foregroundStyle(Theme.muted).padding(.vertical, 8)
                                    HStack {
                                        Text(recipe.scrapCost, format: .number); LText("currency.scrap"); Spacer()
                                        Button {
                                            store.perform { try Progression.fuse(recipe, profile: &$0) }
                                            if store.errorKey == nil { presentReveal(weapon) }
                                        } label: { LText("lab.fuse") }
                                            .disabled(store.profile.scrap < recipe.scrapCost || store.profile.weapons[recipe.weapon, default: 0] == 0 || store.profile.components[recipe.component, default: 0] == 0)
                                            .frame(minHeight: 44).tint(Theme.gold)
                                    }.font(.subheadline.bold())
                                }
                            }
                        }
                    }
                    LText("lab.components").font(.title3.bold()).frame(maxWidth: .infinity, alignment: .leading)
                    ForEach(store.content.components) { component in
                        HStack { LText(component.nameKey); Spacer(); Text(store.profile.components[component.id, default: 0], format: .number) }
                    }.font(.subheadline)
                    LText("lab.inventory").font(.title3.bold()).frame(maxWidth: .infinity, alignment: .leading).padding(.top, 12)
                    ForEach(owned) { weapon in
                        HStack {
                            Image(systemName: icon(weapon.element)).foregroundStyle(Theme.rarity(weapon.rarity))
                            VStack(alignment: .leading) { LText(weapon.nameKey); Text("× \(store.profile.weapons[weapon.id, default: 0])").font(.caption).foregroundStyle(Theme.muted) }
                            Spacer()
                            Button { store.equip(weapon) } label: {
                                if store.profile.equippedWeapon == weapon.id { Image(systemName: "checkmark.circle.fill") } else { LText("lab.equip") }
                            }.tint(Theme.gold).frame(minHeight: 44)
                            Button { store.perform { try Progression.upgradeWeapon(weapon, profile: &$0, content: store.content) } } label: { Image(systemName: "arrow.up.circle") }
                                .accessibilityLabel(Text(LocalizationManager.string("lab.upgrade"))).frame(minWidth: 44, minHeight: 44)
                        }.padding(.vertical, 6)
                    }
                }.padding(20).frame(maxWidth: 760)
            }.background(Theme.ink).toolbar { ToolbarItem(placement: .confirmationAction) { Button("common.done") { dismiss() }.accessibilityIdentifier("workshop-done") } }
                .overlay { if revealing { revealOverlay } }
        }.preferredColorScheme(.dark)
    }
    var owned: [Weapon] { store.content.weapons.filter { store.profile.weapons[$0.id, default: 0] > 0 } }
    var candidates: [Weapon] { Progression.rouletteCandidates(a: a, b: b, content: store.content) }
    var roulettePanel: some View {
        Panel {
            LText("lab.roulette.note").font(.subheadline).foregroundStyle(Theme.muted)
            Picker(selection: $a) { ForEach(owned) { LText($0.nameKey).tag($0.id) } } label: { LText("lab.weaponA") }
            Picker(selection: $b) { ForEach(owned) { LText($0.nameKey).tag($0.id) } } label: { LText("lab.weaponB") }
            ForEach(candidates) { weapon in
                HStack { LText(weapon.nameKey); Spacer(); Text(1.0 / Double(candidates.count), format: .percent.precision(.fractionLength(1))) }.font(.caption).padding(.vertical, 3)
            }
            ActionButton(key: "lab.spin", symbol: "sparkles") {
                guard !candidates.isEmpty else { return }
                var result: Weapon?
                store.perform { result = try Progression.roulette(a: a, b: b, profile: &$0, content: store.content, randomIndex: Int.random(in: 0..<candidates.count)) }
                if let result {
                    if !owned.contains(where: { $0.id == a }) { a = owned.first?.id ?? "blaster" }
                    if !owned.contains(where: { $0.id == b }) || a == b { b = owned.first(where: { $0.id != a })?.id ?? a }
                    presentReveal(result)
                }
            }.disabled(candidates.isEmpty || store.profile.cores == 0 || store.profile.weapons[a, default: 0] == 0 || store.profile.weapons[b, default: 0] == 0)
        }
    }
    var revealOverlay: some View {
        ZStack {
            Theme.ink.opacity(0.98).ignoresSafeArea()
            VStack(spacing: 24) {
                LText("lab.initiated").font(.caption).foregroundStyle(Theme.muted)
                if let reveal {
                    Image(systemName: icon(reveal.element)).font(.system(size: 80)).foregroundStyle(Theme.rarity(reveal.rarity))
                    LText("lab.reveal").font(.title3.bold())
                    LText(reveal.nameKey).font(.system(.largeTitle, design: .rounded, weight: .heavy))
                    LText("rarity." + reveal.rarity.rawValue).foregroundStyle(Theme.rarity(reveal.rarity))
                    LText(reveal.descriptionKey).multilineTextAlignment(.center).foregroundStyle(Theme.muted)
                    ShareLink(item: LocalizedShareCard(weapon: reveal).text) { Label { LText("lab.share") } icon: { Image(systemName: "square.and.arrow.up") } }.frame(minHeight: 44)
                    ActionButton(key: "lab.equip") { store.equip(reveal); revealing = false }.accessibilityIdentifier("fusion-equip")
                }
                Button { revealing = false } label: { LText("common.done") }.frame(minHeight: 44)
            }.padding(30)
        }.transition(store.profile.preferences.reducedMotion ? .opacity : .scale(scale: 0.92).combined(with: .opacity))
    }
    func presentReveal(_ weapon: Weapon) {
        reveal = weapon
        withAnimation(store.profile.preferences.reducedMotion ? nil : .spring(duration: 0.45)) { revealing = true }
        Feedback.play(.fusion, preferences: store.profile.preferences)
    }
}
struct LocalizedShareCard {
    let weapon: Weapon
    var text: String { "\(LocalizationManager.string("app.name"))\n\(LocalizationManager.string("lab.reveal")): \(LocalizationManager.string(weapon.nameKey))\n\(LocalizationManager.string("rarity." + weapon.rarity.rawValue))" }
}
func icon(_ element: Element) -> String {
    switch element {
    case .ballistic: "scope"
    case .fire: "flame.fill"
    case .cryo: "snowflake"
    case .electric: "bolt.fill"
    case .energy: "sun.max.fill"
    case .explosive: "burst.fill"
    case .drone: "paperplane.fill"
    case .experimental: "atom"
    }
}
struct BlueprintView: View {
    @Environment(GameStore.self) var store
    @State private var filter: Element?
    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                PageHeading(title: "lab.database", subtitle: "lab.subtitle")
                Text("\(store.profile.blueprints.count) / \(store.content.recipes.count)").font(.system(.largeTitle, design: .rounded, weight: .heavy)).foregroundStyle(Theme.gold)
                Picker(selection: $filter) {
                    LText("lab.database").tag(Optional<Element>.none)
                    ForEach(Element.allCases, id: \.self) { element in LText("element." + element.rawValue).tag(Optional(element)) }
                } label: { LText("lab.database") }
                ForEach(store.content.recipes.filter { recipe in filter == nil || store.content.weapons.first(where: { $0.id == recipe.result })?.element == filter }) { recipe in
                    let discovered = store.profile.blueprints.contains(recipe.id)
                    Panel {
                        HStack(spacing: 16) {
                            Image(systemName: discovered ? "lightbulb.fill" : "questionmark.square.dashed").font(.largeTitle).foregroundStyle(discovered ? Theme.gold : Theme.muted)
                            VStack(alignment: .leading, spacing: 8) {
                                LText(discovered ? "weapon." + recipe.result : "lab.unknown").font(.headline)
                                LText(recipe.clueKey).font(.caption).foregroundStyle(Theme.muted)
                                if discovered { LText("lab.discovered").font(.caption.bold()).foregroundStyle(Theme.mint) }
                            }
                        }
                    }
                }
                ActionButton(key: "city.workshop", symbol: "wrench.and.screwdriver.fill") { store.workshopPresented = true }
            }.padding(20).frame(maxWidth: 760)
        }.background(Theme.ink)
    }
}
