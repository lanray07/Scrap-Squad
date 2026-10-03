import SwiftUI
import ScrapCore

struct SquadView: View {
    @Environment(GameStore.self) var store
    @Environment(CommerceService.self) var commerce
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                PageHeading(title: "squad.title", subtitle: "squad.subtitle")
                if commerce.founderBadge {
                    Label { LText("cosmetic.badge") } icon: { Image(systemName: "star.circle.fill") }
                        .font(.headline).foregroundStyle(Theme.gold).accessibilityIdentifier("founder-badge")
                }
                HStack {
                    ForEach(store.profile.squad, id: \.self) { id in
                        if let robot = store.content.robots.first(where: { $0.id == id }) {
                            VStack { RobotPortrait(robot: robot).frame(width: 66, height: 70); LText(robot.nameKey).font(.caption.bold()) }
                        }
                    }
                    Spacer()
                    Text("\(store.profile.squad.count) / \(store.profile.squadCapacity)").foregroundStyle(Theme.muted)
                }
                LText("squad.commander").font(.caption).foregroundStyle(Theme.muted)
                ForEach(store.content.robots) { robot in
                    let unlocked = store.profile.unlockedRobots.contains(robot.id)
                    let level = store.profile.robotLevels[robot.id, default: 1]
                    Panel {
                        HStack(alignment: .top, spacing: 14) {
                            RobotPortrait(robot: robot).frame(width: 95, height: 110).opacity(unlocked ? 1 : 0.4)
                            VStack(alignment: .leading, spacing: 8) {
                                HStack { LText(robot.nameKey).font(.title2.bold()); Spacer(); if store.profile.squad.contains(robot.id) { Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.mint) } }
                                LText("rarity." + robot.rarity.rawValue).font(.caption.bold()).foregroundStyle(Theme.rarity(robot.rarity))
                                LText(robot.personalityKey).font(.subheadline).foregroundStyle(Theme.muted)
                                HStack { LText("city.level.label"); Text(level, format: .number) }.font(.caption)
                            }
                        }
                        LText("squad.passive").font(.caption.bold()).foregroundStyle(Theme.gold).padding(.top, 10)
                        LText(robot.passiveKey).font(.caption)
                        LText("squad.active").font(.caption.bold()).foregroundStyle(Theme.gold).padding(.top, 8)
                        LText(robot.activeKey).font(.caption)
                        if store.content.weapons.first(where: { $0.id == store.profile.equippedWeapon })?.element == robot.affinity {
                            Label { LText("squad.affinity") } icon: { Image(systemName: "link") }.font(.caption).foregroundStyle(Theme.mint).padding(.vertical, 8)
                        }
                        HStack {
                            VStack(alignment: .leading) {
                                Button { store.perform { try Progression.upgradeRobot(robot, profile: &$0, content: store.content) } } label: { LText(unlocked ? "squad.upgrade" : "squad.unlock") }.frame(minHeight: 44)
                                Text(unlocked ? Progression.cost(base: store.content.economy.robotLevelBaseCost, level: level - 1, economy: store.content.economy) : robot.unlockCost, format: .number).font(.caption)
                            }
                            Spacer()
                            if unlocked {
                                Button { store.perform { try Progression.toggleSquad(robot.id, profile: &$0) } } label: { LText(store.profile.squad.contains(robot.id) ? "squad.remove" : "squad.add") }.frame(minHeight: 44)
                            }
                        }.tint(Theme.gold)
                    }
                }
            }.padding(20).frame(maxWidth: 760)
        }.background(Theme.ink)
    }
}
