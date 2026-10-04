import SwiftUI
import ScrapCore

struct CombatExcitementStatus: View {
    let event: WaveEvent?
    let evolution: RunEvolution?
    let elapsed: Double
    let perfectDodgeBoost: Double
    init(engine: BattleEngine) {
        // Copy changing values: the engine itself is not observable by this child view.
        event = engine.waveEvent; evolution = engine.evolution
        elapsed = engine.elapsed; perfectDodgeBoost = engine.perfectDodgeBoost
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let event {
                HStack {
                    Image(systemName: event.kind == .treasureCarrier ? "shippingbox.fill" : event.kind == .scrapStorm ? "cloud.bolt.fill" : "exclamationmark.shield.fill")
                    LText(event.kind.nameKey).bold()
                    Spacer()
                    Text(Int(ceil(max(0, event.endsAt - elapsed))), format: .number).monospacedDigit()
                }.accessibilityElement(children: .combine).accessibilityIdentifier("wave-event")
                LText(event.kind.detailKey).font(.caption)
            }
            if let evolution {
                Label { LText(evolution.nameKey) } icon: { Image(systemName: "sparkles") }
                    .font(.caption.bold()).foregroundStyle(Color(hex: evolution.color)).accessibilityIdentifier("weapon-evolution")
            }
            if perfectDodgeBoost > 0 {
                Label { LText("battle.perfectDodge") } icon: { Image(systemName: "bolt.shield.fill") }
                    .font(.caption.bold()).foregroundStyle(Theme.mint).accessibilityIdentifier("perfect-dodge")
            }
        }.font(.caption).foregroundStyle(Theme.gold).padding(.horizontal, 20)
    }
}
