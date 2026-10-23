import SwiftUI
import ScrapCore

struct SalvageStatus: View {
    let operation: SalvageOperation
    let player: Vector
    let interactive: Bool
    let target: (SalvageSystem) -> Void
    let rebuild: () -> Void
    private var destination: Vector {
        if !operation.rescued { return operation.escort }
        if operation.readyForExtraction { return operation.extraction }
        return operation.drops.min { ($0.position - player).length < ($1.position - player).length }?.position ?? operation.escort
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "location.fill").foregroundStyle(Theme.mint)
                LText(operation.objectiveKey).font(.caption.bold())
                Spacer()
                Button(action: rebuild) { Label { LText("salvage.rebuild") } icon: { Image(systemName: "wrench.adjustable.fill") } }
                    .font(.caption.bold()).buttonStyle(.borderedProminent).tint(Theme.gold).foregroundStyle(Theme.ink)
                    .disabled(!interactive).accessibilityIdentifier("salvage-rebuild")
            }
            HStack(spacing: 8) {
                ForEach(SalvageSystem.allCases) { system in
                    Button { target(system) } label: {
                        HStack(spacing: 4) {
                            Image(systemName: system.symbol)
                            LText(system.nameKey)
                            Text(operation.inventory[system, default: 0], format: .number).monospacedDigit()
                        }.font(.caption2.bold()).padding(.horizontal, 8).padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(Color(hex: system.color).opacity(operation.focus == system ? 0.3 : 0.08), in: RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: system.color), lineWidth: operation.focus == system ? 2 : 0))
                    }.buttonStyle(.plain).disabled(!interactive)
                        .accessibilityIdentifier("salvage-target-" + system.rawValue)
                        .accessibilityAddTraits(operation.focus == system ? .isSelected : [])
                        .accessibilityHint(Text(LocalizationManager.string("salvage.target.hint")))
                }
            }
            HStack(spacing: 8) {
                let offset = destination - player
                Image(systemName: "location.north.fill").rotationEffect(.radians(atan2(offset.x, offset.y)))
                LText(!operation.rescued ? "salvage.scout.rescue" : operation.readyForExtraction ? "salvage.beacon" : "salvage.recovered")
                Spacer()
                Text("\(min(3, operation.recovered))/3").monospacedDigit()
                Image(systemName: "shippingbox.fill")
                Text(operation.rebuilds, format: .number).monospacedDigit()
                Image(systemName: "wrench.fill")
            }.font(.caption2).foregroundStyle(Theme.mint)
            if operation.readyForExtraction {
                ProgressView(value: operation.extractionProgress, total: 12).tint(Theme.mint)
                    .accessibilityLabel(Text(LocalizationManager.string("salvage.extraction")))
            }
        }.padding(.horizontal, 12).padding(.vertical, 6).background(Theme.surface.opacity(0.85))
            .accessibilityIdentifier("salvage-status")
            .accessibilityValue(ProcessInfo.processInfo.arguments.contains("--ui-testing")
                ? "\(player.x),\(player.y),\(destination.x),\(destination.y),\(operation.inventory[.weapon, default: 0]),\(operation.rebuilds)" : "")
    }
}

struct SalvageRebuildView: View {
    let operation: SalvageOperation
    let robots: [Robot]
    let finishes: [String: RobotFinish]
    let install: (SalvageSystem, String) -> Void
    let resume: () -> Void
    @State private var selectedRobot = ""
    private var robotID: String { robots.contains(where: { $0.id == selectedRobot }) ? selectedRobot : (robots.first?.id ?? "") }
    var body: some View {
        ZStack {
            Theme.ink.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 18) {
                    PageHeading(title: "salvage.rebuild", subtitle: "salvage.rebuild.note")
                    HStack {
                        ForEach(robots) { robot in
                            Button { selectedRobot = robot.id } label: {
                                VStack {
                                    RobotPortrait(robot: robot).frame(width: 65, height: 70)
                                    LText(robot.nameKey).font(.caption.bold())
                                }.padding(8).background(robotID == robot.id ? Theme.gold.opacity(0.22) : .clear, in: RoundedRectangle(cornerRadius: 16))
                            }.buttonStyle(.plain).accessibilityIdentifier("salvage-robot-" + robot.id)
                        }
                    }
                    if let robot = robots.first(where: { $0.id == robotID }) {
                        if let skin = finishes[robotID]?.skin {
                            Image(uiImage: SignatureRobotArt.image(skin)).resizable().scaledToFit().frame(width: 130, height: 150)
                        } else { RobotPortrait(robot: robot).frame(width: 130, height: 150) }
                    }
                    ForEach(SalvageSystem.allCases) { system in
                        moduleCard(system)
                    }
                    LText("salvage.replace.note").font(.caption).foregroundStyle(Theme.muted)
                    ActionButton(key: "salvage.resume", symbol: "play.fill", action: resume).accessibilityIdentifier("salvage-resume")
                }.padding(24).frame(maxWidth: 660).frame(maxWidth: .infinity)
            }
        }.accessibilityIdentifier("salvage-rebuild-screen")
    }
    private func moduleCard(_ system: SalvageSystem) -> some View {
        let installed = operation.modules[robotID] == system
        let available = operation.inventory[system, default: 0]
        return Button { install(system, robotID) } label: {
            HStack(spacing: 14) {
                Image(systemName: system.symbol).font(.largeTitle).foregroundStyle(Color(hex: system.color)).frame(width: 42)
                VStack(alignment: .leading, spacing: 6) {
                    LText(system.nameKey).font(.headline)
                    LText(system.detailKey).font(.subheadline).foregroundStyle(Theme.muted)
                    HStack { LText(installed ? "salvage.installed" : "salvage.cost"); Text("\(available)/2").monospacedDigit() }.font(.caption.bold())
                }
                Spacer()
                Image(systemName: installed ? "checkmark.seal.fill" : "plus.circle.fill").foregroundStyle(Color(hex: system.color))
            }.padding(18).frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(hex: system.color).opacity(0.12), in: RoundedRectangle(cornerRadius: 22))
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color(hex: system.color).opacity(0.6), lineWidth: 1))
        }.buttonStyle(.plain).disabled(installed || available < 2 || robotID.isEmpty)
            .opacity(!installed && available < 2 ? 0.5 : 1)
            .accessibilityIdentifier("salvage-install-" + system.rawValue)
    }
}

struct SalvageResults: View {
    let report: SalvageReport
    var body: some View {
        VStack(spacing: 8) {
            Label { LText(report.extracted ? "salvage.objective.complete" : "salvage.incomplete") } icon: { Image(systemName: "shippingbox.fill") }
                .font(.headline).foregroundStyle(Theme.mint)
            HStack { LText("salvage.recovered"); Spacer(); Text(report.recovered, format: .number) }
            HStack { LText("salvage.rebuilt"); Spacer(); Text(report.rebuilt, format: .number) }
            if report.extracted { LText("salvage.bonus").foregroundStyle(Theme.gold) }
        }.padding(18).background(Theme.surface, in: RoundedRectangle(cornerRadius: 20))
    }
}
