import SwiftUI
import ScrapCore

struct ChallengePanel: View {
    @Environment(GameStore.self) private var store
    @State private var code = ""
    let deploy: (RunChallenge) -> Void
    private var daily: RunChallenge { .daily(now: Date()) }
    var body: some View {
        let daily = self.daily
        Panel {
            Label { LText("challenge.title") } icon: { Image(systemName: "globe.europe.africa.fill").foregroundStyle(Theme.mint) }
                .font(.title3.bold())
            LText("challenge.detail").font(.caption).foregroundStyle(Theme.muted)
            Text(daily.code).font(.headline.monospaced()).foregroundStyle(Theme.gold)
            ActionButton(key: "challenge.daily", symbol: "play.fill") { deploy(daily) }
                .accessibilityIdentifier("daily-play")
            ShareLink(item: daily.code + "\nhttps://lanray07.github.io/Scrap-Squad/") {
                Label { LText("challenge.share") } icon: { Image(systemName: "square.and.arrow.up") }
            }.tint(Theme.mint).frame(minHeight: 44)
            Divider()
            TextField(LocalizationManager.string("challenge.placeholder", locale: store.profile.preferences.locale), text: $code)
                .textInputAutocapitalization(.characters).autocorrectionDisabled().font(.body.monospaced())
                .padding(12).background(Theme.ink, in: RoundedRectangle(cornerRadius: 12))
                .accessibilityIdentifier("challenge-input")
            if !code.isEmpty && RunChallenge(code: code) == nil {
                LText("challenge.invalid").font(.caption).foregroundStyle(Theme.gold)
            }
            Button {
                if let challenge = RunChallenge(code: code) { deploy(challenge) }
            } label: { Label { LText("challenge.play") } icon: { Image(systemName: "person.2.fill") } }
                .disabled(RunChallenge(code: code) == nil).tint(Theme.gold).frame(minHeight: 44)
                .accessibilityIdentifier("challenge-play")
            LText("challenge.local").font(.caption2).foregroundStyle(Theme.muted)
        }
    }
}

struct CombatMomentum: View {
    let engine: BattleEngine
    let activate: () -> Void
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                HStack { LText("momentum.wave"); Text(engine.wave, format: .number); Spacer(); Text("×\(engine.combo.multiplier)").foregroundStyle(Theme.gold) }
                if engine.combo.count > 0 {
                    HStack { LText("momentum.combo"); Text(engine.combo.count, format: .number) }.foregroundStyle(Theme.mint)
                } else { LText("momentum.hint").foregroundStyle(Theme.muted) }
            }.font(.caption.bold())
            Button(action: activate) {
                VStack(spacing: 4) {
                    LText(engine.combo.overdrive > 0 ? "momentum.active" : "momentum.overdrive").font(.caption.bold())
                    ProgressView(value: engine.combo.overdrive > 0 ? engine.combo.overdrive / 6 : engine.combo.charge)
                        .tint(engine.combo.overdrive > 0 ? Theme.mint : Theme.gold)
                }.padding(10).frame(width: 120).background(Theme.surface, in: RoundedRectangle(cornerRadius: 12))
            }.disabled(engine.combo.charge < 1 || engine.state != .fighting || engine.combo.overdrive > 0)
                .accessibilityIdentifier("overdrive-button")
                .accessibilityValue(Text(engine.combo.overdrive > 0 ? Int(ceil(engine.combo.overdrive)) : Int(engine.combo.charge * 100), format: .number))
        }.padding(.horizontal, 20).padding(.bottom, 8)
    }
}

struct RunCard: View {
    let record: RunRecord
    let content: GameContent
    let locale: String
    private func text(_ key: String) -> String { LocalizationManager.string(key, locale: locale) }
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack { Image(systemName: "bolt.shield.fill").foregroundStyle(Theme.gold); Text("SCRAP SQUAD").font(.headline); Spacer(); Text("MERGE & SURVIVE").font(.system(size: 8, weight: .bold)).foregroundStyle(Theme.muted) }
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(text(record.victory ? "battle.victory" : "battle.defeat")).font(.system(.title2, design: .rounded, weight: .heavy))
                    Text(text("mode." + record.mode.rawValue)).font(.caption).foregroundStyle(Theme.mint)
                    Text(text(content.biomes[min(record.zone, content.biomes.count - 1)].nameKey)).font(.caption).foregroundStyle(Theme.muted)
                }
                Spacer()
                if let image = RobotArt.image("bolt") { Image(uiImage: image).resizable().scaledToFit().frame(width: 86, height: 86) }
            }
            Text(record.score, format: .number).font(.system(size: 54, weight: .heavy, design: .rounded)).minimumScaleFactor(0.5).lineLimit(1).foregroundStyle(Theme.gold)
            Text(text("battle.score")).font(.caption.bold()).foregroundStyle(Theme.muted)
            HStack {
                stat("battle.kills", record.kills)
                Spacer()
                stat("momentum.best", record.highlights.bestCombo)
                Spacer()
                stat("battle.bosses", record.bosses)
            }
            if let weapon = content.weapons.first(where: { $0.id == record.highlights.weaponID }) {
                Label(text(weapon.nameKey), systemImage: icon(weapon.element)).font(.subheadline.bold()).foregroundStyle(Theme.mint)
            }
            ForEach(record.highlights.synergies) { Text(text($0.nameKey)).font(.caption.bold()).foregroundStyle(Theme.gold) }
            if let evolution = record.highlights.evolution { Text(text(evolution.nameKey)).font(.headline.bold()).foregroundStyle(Theme.mint) }
            if let dodges = record.highlights.perfectDodges, dodges > 0 { stat("battle.perfectDodges", dodges) }
            if !record.medals.isEmpty {
                HStack(spacing: 14) { ForEach(record.medals) { Image(systemName: $0.symbol).foregroundStyle(Theme.gold).accessibilityLabel(text($0.nameKey)) } }
            }
            if let code = record.highlights.challengeCode {
                Divider().overlay(Theme.muted.opacity(0.3))
                Text(text("challenge.card")).font(.caption).foregroundStyle(Theme.muted)
                Text(code).font(.headline.monospaced()).foregroundStyle(Theme.mint)
            }
            Text("lanray07.github.io/Scrap-Squad").font(.system(size: 10, weight: .medium)).foregroundStyle(Theme.muted)
        }.padding(24).frame(width: 340).background(LinearGradient(colors: [Theme.surface, Theme.ink], startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(Theme.gold.opacity(0.45), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 24)).foregroundStyle(.white).environment(\.locale, LocaleManager.locale(locale))
    }
    private func stat(_ key: String, _ value: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) { Text(value, format: .number).font(.title3.bold()); Text(text(key)).font(.system(size: 9)).foregroundStyle(Theme.muted) }
    }
}

struct ShareRunButton: View {
    @Environment(GameStore.self) private var store
    let record: RunRecord
    @State private var image: Image?
    @State private var preview: RunRecord?
    var body: some View {
        VStack(spacing: 8) {
            Button { preview = record } label: { Label { LText("run.preview") } icon: { Image(systemName: "rectangle.portrait.on.rectangle.portrait") } }
                .tint(Theme.gold).frame(minHeight: 44).accessibilityIdentifier("preview-run")
            if let image {
                ShareLink(item: image, message: Text((record.highlights.challengeCode ?? "") + "\nhttps://lanray07.github.io/Scrap-Squad/"),
                    preview: SharePreview(Text("Scrap Squad"), image: image)) {
                    Label { LText("run.share") } icon: { Image(systemName: "square.and.arrow.up") }
                        .font(.headline).padding(14).frame(maxWidth: .infinity)
                }.tint(Theme.mint).accessibilityIdentifier("share-run")
            } else {
                ShareLink(item: "Scrap Squad · \(record.score)\n\(record.highlights.challengeCode ?? "")\nhttps://lanray07.github.io/Scrap-Squad/") { LText("run.share") }
                    .frame(minHeight: 44).accessibilityIdentifier("share-run")
            }
        }.sheet(item: $preview) { record in
            RunCardPreview(record: record)
        }.task(id: record.id) {
            let renderer = ImageRenderer(content: RunCard(record: record, content: store.content, locale: store.profile.preferences.locale))
            renderer.scale = 3
            if let rendered = renderer.uiImage { image = Image(uiImage: rendered) }
        }.onDisappear { image = nil }
    }
}

struct RunCardPreview: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let record: RunRecord
    var body: some View {
        NavigationStack {
            ScrollView {
                RunCard(record: record, content: store.content, locale: store.profile.preferences.locale)
                    .padding(.vertical, 20).frame(maxWidth: .infinity).accessibilityIdentifier("run-card")
            }.background(Theme.ink)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button { dismiss() } label: { LText("common.done") } } }
        }.preferredColorScheme(.dark)
    }
}

struct RunJournalView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    private var journal: RunJournal { store.profile.journal ?? RunJournal() }
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 18) {
                    PageHeading(title: "journal.title", subtitle: "journal.detail")
                    Panel {
                        LText("mastery.title").font(.title3.bold())
                        ForEach(MasteryMilestone.allCases) { milestone in
                            let amount = milestone.progress(store.profile)
                            HStack { Image(systemName: amount == milestone.goal ? "checkmark.seal.fill" : "seal").foregroundStyle(amount == milestone.goal ? Theme.gold : Theme.muted); LText(milestone.nameKey); Spacer(); Text("\(amount)/\(milestone.goal)").monospacedDigit() }.font(.caption)
                            ProgressView(value: Double(amount), total: Double(milestone.goal)).tint(Theme.gold)
                        }
                    }
                    Panel {
                        LText("synergy.title").font(.title3.bold())
                        ForEach(BuildSynergy.allCases) { synergy in
                            HStack { Image(systemName: journal.discoveredSynergies.contains(synergy) ? "sparkles" : "lock").foregroundStyle(Theme.mint); LText(synergy.nameKey).font(.headline) }
                            LText(synergy.detailKey).font(.caption).foregroundStyle(Theme.muted)
                        }
                    }
                    if journal.recent.isEmpty { LText("journal.empty").foregroundStyle(Theme.muted) }
                    ForEach(journal.recent) { record in
                        Panel {
                            HStack { LText("mode." + record.mode.rawValue).font(.headline); Spacer(); Text(record.score, format: .number).foregroundStyle(Theme.gold) }
                            HStack { LText("momentum.best"); Text(record.highlights.bestCombo, format: .number); Spacer(); Text(record.date, style: .date) }.font(.caption).foregroundStyle(Theme.muted)
                            ForEach(record.medals) { medal in Label { LText(medal.nameKey) } icon: { Image(systemName: medal.symbol).foregroundStyle(Theme.gold) }.font(.caption) }
                            ShareRunButton(record: record)
                        }
                    }
                }.padding(20).frame(maxWidth: 760)
            }.background(Theme.ink).foregroundStyle(.white)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button { dismiss() } label: { LText("common.done") } } }
        }.preferredColorScheme(.dark)
    }
}
