import SwiftUI
import UIKit
import ScrapCore

enum Theme {
    static let ink = Color(hex: "10252D")
    static let surface = Color(hex: "203A43")
    static let gold = Color(hex: "F5B942")
    static let mint = Color(hex: "79D9BA")
    static let muted = Color(hex: "AEC1C4")
    static func rarity(_ rarity: Rarity) -> Color {
        switch rarity {
        case .common: Color(hex: "B8C6CA")
        case .uncommon: mint
        case .rare: Color(hex: "7CC5F1")
        case .epic: Color(hex: "BA9DEB")
        case .legendary: gold
        case .mythic: Color(hex: "F28AA7")
        }
    }
}
extension Color {
    init(hex: String) {
        let value = UInt64(hex, radix: 16) ?? 0
        self.init(.sRGB, red: Double((value >> 16) & 255) / 255, green: Double((value >> 8) & 255) / 255, blue: Double(value & 255) / 255, opacity: 1)
    }
}
struct LText: View {
    @Environment(GameStore.self) var store
    let key: String
    init(_ key: String) { self.key = key }
    var body: some View { Text(LocalizationManager.string(key, locale: store.profile.preferences.locale)) }
}
struct ActionButton: View {
    let key: String
    var symbol: String = "arrow.right"
    var secondary = false
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack { LText(key); Spacer(minLength: 8); Image(systemName: symbol) }
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .padding(16).frame(minHeight: 50)
                .foregroundStyle(secondary ? Color.white : Theme.ink)
                .background(secondary ? Theme.surface : Theme.gold, in: RoundedRectangle(cornerRadius: 16))
        }.buttonStyle(.plain)
    }
}
struct PageHeading: View {
    let title: String
    let subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            LText(title).font(.system(.largeTitle, design: .rounded, weight: .heavy))
            LText(subtitle).font(.subheadline).foregroundStyle(Theme.muted)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 12)
    }
}
struct Panel<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View { VStack(alignment: .leading, spacing: 12) { content }.padding(18).frame(maxWidth: .infinity, alignment: .leading).background(Theme.surface, in: RoundedRectangle(cornerRadius: 22)) }
}
struct ResourceBar: View {
    @Environment(GameStore.self) var store
    var body: some View {
        HStack(spacing: 16) {
            resource("gearshape.fill", "currency.scrap", store.profile.scrap, Theme.gold)
            resource("circle.hexagongrid.fill", "currency.credits", store.profile.credits, Theme.mint)
            resource("sparkles", "currency.cores", store.profile.cores, .purple)
            Spacer(minLength: 0)
            Button { store.settingsPresented = true } label: { Image(systemName: "slider.horizontal.3").padding(12) }
                .accessibilityLabel(Text(LocalizationManager.string("accessibility.settings")))
        }.font(.system(.footnote, design: .rounded, weight: .bold)).padding(.horizontal, 20).padding(.vertical, 6)
    }
    func resource(_ symbol: String, _ key: String, _ amount: Int, _ color: Color) -> some View {
        HStack(spacing: 5) { Image(systemName: symbol).foregroundStyle(color); Text(amount, format: .number) }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(LocalizationManager.string(key, locale: store.profile.preferences.locale)))
            .accessibilityValue(Text(amount, format: .number))
    }
}

@MainActor enum RobotArt {
    static let order = ["bolt", "tank", "zip", "patch", "nova", "boomer", "glitch", "magnet"]
    static let atlas = UIImage(named: "RobotAtlas")
    private static var cache: [String: UIImage] = [:]
    static func image(_ id: String) -> UIImage? {
        if let cached = cache[id] { return cached }
        guard let index = order.firstIndex(of: id), let cg = atlas?.cgImage else { return nil }
        let width = cg.width / 4, height = cg.height / 2
        let rect = CGRect(x: CGFloat((index % 4) * width), y: CGFloat((index / 4) * height), width: CGFloat(width), height: CGFloat(height))
        guard let crop = cg.cropping(to: rect) else { return nil }
        let image = UIImage(cgImage: crop); cache[id] = image; return image
    }
}
struct RobotPortrait: View {
    @Environment(CommerceService.self) private var commerce
    let robot: Robot
    var level = 1
    var body: some View {
        if let image = RobotArt.image(robot.id) {
            Image(uiImage: image).resizable().scaledToFit().colorMultiply(commerce.robotFinishes[robot.id].map { Color(hex: $0) } ?? .white).accessibilityLabel(Text(LocalizationManager.string(robot.nameKey)))
        } else { procedural }
    }
    var procedural: some View {
        Canvas { context, size in
            let s = min(size.width, size.height) / 120
            let x = (size.width - 120 * s) / 2
            func rect(_ rect: CGRect, color: Color, radius: Double = 8) {
                let r = CGRect(x: x + rect.minX * s, y: rect.minY * s, width: rect.width * s, height: rect.height * s)
                context.fill(Path(roundedRect: r, cornerRadius: radius * s), with: .color(color))
            }
            let color = Color(hex: robot.color)
            let wide = robot.silhouette == "heavy"
            let narrow = robot.silhouette == "slim"
            rect(CGRect(x: 28, y: 97, width: 24, height: 13), color: Theme.ink)
            rect(CGRect(x: 68, y: 97, width: 24, height: 13), color: Theme.ink)
            rect(CGRect(x: wide ? 17 : 28, y: 61, width: wide ? 86 : 64, height: 38), color: color.opacity(0.75))
            rect(CGRect(x: 10, y: 67, width: 17, height: 27), color: color)
            rect(CGRect(x: 94, y: 67, width: 17, height: 27), color: color)
            rect(CGRect(x: 58, y: 6, width: 4, height: 17), color: Theme.muted)
            rect(CGRect(x: 52, y: 4, width: 16, height: 8), color: Theme.gold)
            rect(CGRect(x: narrow ? 32 : 20, y: 23, width: narrow ? 56 : 80, height: 48), color: color, radius: robot.silhouette == "orb" ? 24 : 14)
            rect(CGRect(x: 28, y: 34, width: 64, height: 23), color: Theme.ink, radius: 9)
            rect(CGRect(x: 37, y: 40, width: 13, height: 9), color: Theme.mint, radius: 3)
            rect(CGRect(x: 70, y: 40, width: 13, height: 9), color: Theme.mint, radius: 3)
            rect(CGRect(x: 48, y: 80, width: 24, height: 6), color: Theme.gold, radius: 3)
            if robot.silhouette == "medic" {
                rect(CGRect(x: 57, y: 71, width: 6, height: 19), color: .white, radius: 1)
                rect(CGRect(x: 50, y: 77, width: 20, height: 6), color: .white, radius: 1)
            }
        }.accessibilityLabel(Text(LocalizationManager.string(robot.nameKey)))
    }
}
