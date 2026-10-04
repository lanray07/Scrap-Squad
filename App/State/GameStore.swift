import Foundation
import SwiftUI
import ScrapCore

@MainActor @Observable final class GameStore {
    let content: GameContent
    var profile: PlayerProfile
    var offline: OfflineReward?
    var errorKey: String?
    var selectedTab = 0
    var workshopPresented = false
    var settingsPresented = false
    var onboardingPresented = false
    private let saveURL: URL
    private var savingDisabled = false
    init(content: GameContent) {
        self.content = content
        let directory = URL.documentsDirectory.appending(path: "ScrapSquad", directoryHint: .isDirectory)
        saveURL = directory.appending(path: "profile.json")
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            if ProcessInfo.processInfo.arguments.contains("--ui-testing") {
                profile = PlayerProfile(); onboardingPresented = true
                // Opt-in UI fixture: normal content and timing, extra health for long combat checks.
                if ProcessInfo.processInfo.arguments.contains("--excitement-qa") {
                    profile.robotLevels = ["bolt": 30, "patch": 30]
                }
            } else if FileManager.default.fileExists(atPath: saveURL.path) {
                profile = try JSONDecoder().decode(PlayerProfile.self, from: Data(contentsOf: saveURL))
                try profile.validate(content: content)
            } else {
                profile = PlayerProfile(); onboardingPresented = true
            }
        } catch {
            profile = PlayerProfile(); savingDisabled = true; errorKey = "error.load"
        }
        Progression.refreshMissions(&profile, now: Date())
        let reward = Progression.offline(profile: profile, content: content, now: Date())
        if reward.isAvailable { offline = reward }
    }
    func perform(_ action: (inout PlayerProfile) throws -> Void) {
        do { try action(&profile); save() }
        catch let error as GameError { errorKey = "error.\(error)" }
        catch { errorKey = "common.error" }
    }
    func save() {
        guard !savingDisabled else { errorKey = "error.load"; return }
        do {
            let data = try JSONEncoder().encode(profile)
            try data.write(to: saveURL, options: [.atomic, .completeFileProtectionUnlessOpen])
        } catch { errorKey = "settings.save.error" }
    }
    func claimOffline() {
        _ = Progression.claimOffline(&profile, content: content, now: Date())
        offline = nil; save()
    }
    func sceneChanged(_ phase: ScenePhase) {
        if phase == .active {
            Progression.refreshMissions(&profile, now: Date())
            let reward = Progression.offline(profile: profile, content: content, now: Date())
            if reward.isAvailable { offline = reward }
        } else if phase == .background {
            // Do not erase unclaimed expedition time.
            if offline == nil { profile.lastSeen = max(profile.lastSeen, Date()) }
            save()
        }
    }
    func equip(_ weapon: Weapon) {
        guard profile.weapons[weapon.id, default: 0] > 0 else { return }
        profile.equippedWeapon = weapon.id; save()
    }
}

enum LocalizationManager {
    static let supported = ["en", "es", "fr", "de", "it", "pt", "pt-BR", "ja", "ko", "zh-Hans", "zh-Hant"]
    static func string(_ key: String, locale: String = "system") -> String {
        let language = locale == "system" ? Locale.preferredLanguages.first ?? "en" : locale
        let normalized = language.replacingOccurrences(of: "_", with: "-")
        let candidates = supported.filter { normalized == $0 || normalized.hasPrefix($0 + "-") }.sorted { $0.count > $1.count }
        let resolved = candidates.first(where: { Bundle.main.localizations.contains($0) }) ?? "en"
        let path = Bundle.main.path(forResource: resolved, ofType: "lproj")
        let bundle = path.flatMap(Bundle.init(path:)) ?? .main
        let englishPath = Bundle.main.path(forResource: "en", ofType: "lproj")
        let english = englishPath.flatMap(Bundle.init(path:)) ?? .main
        let fallback = english.localizedString(forKey: key, value: key, table: nil)
        return bundle.localizedString(forKey: key, value: fallback, table: nil)
    }
}
enum LocaleManager {
    static func locale(_ preference: String) -> Locale { preference == "system" ? .current : Locale(identifier: preference) }
    static var available: [String] { LocalizationManager.supported.filter { $0 == "en" || Bundle.main.localizations.contains($0) } }
}
enum LocalizedFormatting {
    static func number(_ value: Int, locale: Locale) -> String { value.formatted(.number.locale(locale)) }
    static func duration(_ seconds: Double) -> String {
        Duration.seconds(seconds).formatted(.time(pattern: .hourMinute))
    }
}
