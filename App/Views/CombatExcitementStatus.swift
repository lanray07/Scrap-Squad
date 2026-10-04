import SwiftUI
import ScrapCore

struct CombatExcitementStatus: View {
    let engine: BattleEngine
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let event = engine.waveEvent {
                HStack {
                    Image(systemName: event.kind == .treasureCarrier ? "shippingbox.fill" : event.kind == .scrapStorm ? "cloud.bolt.fill" : "exclamationmark.shield.fill")
                    LText(event.kind.nameKey).bold()
                    Spacer()
                    Text(Int(ceil(max(0, event.endsAt - engine.elapsed))), format: .number).monospacedDigit()
                }.accessibilityIdentifier("wave-event")
                LText(event.kind.detailKey).font(.caption)
            }
            if let evolution = engine.evolution {
                Label { LText(evolution.nameKey) } icon: { Image(systemName: "sparkles") }
                    .font(.caption.bold()).foregroundStyle(Color(hex: evolution.color)).accessibilityIdentifier("weapon-evolution")
            }
            if engine.perfectDodgeBoost > 0 {
                Label { LText("battle.perfectDodge") } icon: { Image(systemName: "bolt.shield.fill") }
                    .font(.caption.bold()).foregroundStyle(Theme.mint).accessibilityIdentifier("perfect-dodge")
            }
        }.font(.caption).foregroundStyle(Theme.gold).padding(.horizontal, 20)
    }
}
