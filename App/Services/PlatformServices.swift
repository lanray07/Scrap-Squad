import SwiftUI
import UIKit
import StoreKit
import GameKit
import AVFoundation
import ScrapCore

extension CosmeticCatalog {
    static func bundled() -> CosmeticCatalog {
        guard let url = Bundle.main.url(forResource: "StoreConfiguration", withExtension: "json"),
              let data = try? Data(contentsOf: url), let catalog = try? JSONDecoder().decode(Self.self, from: data) else {
            return CosmeticCatalog(packs: [])
        }
        return catalog
    }
}
@MainActor @Observable final class CommerceService {
    var products: [Product] = []
    private(set) var entitlements: Set<String> = []
    var messageKey: String?
    private(set) var loading = false
    private(set) var selection = CosmeticSelection()
    private var updates: Task<Void, Never>?
    private let selectionKey = "cosmetic-selection-v1"
    let configuration = CosmeticCatalog.bundled()
    init() {
        if ProcessInfo.processInfo.arguments.contains("--reset-cosmetics") { UserDefaults.standard.removeObject(forKey: selectionKey) }
        if let data = UserDefaults.standard.data(forKey: selectionKey),
           let saved = try? JSONDecoder().decode(CosmeticSelection.self, from: data) { selection = saved }
    }
    var robotFinishes: [String: RobotFinish] { selection.activeFinishes(catalog: configuration, owned: entitlements) }
    var effectiveOwnership: Set<String> { configuration.effectiveOwnership(entitlements) }
    var weaponEffect: String? { selection.weaponEffectID.flatMap { configuration.availableWeaponEffects(owned: entitlements).contains($0) ? $0 : nil } }
    func setWeaponEffect(_ effect: String?) {
        guard effect == nil || configuration.availableWeaponEffects(owned: entitlements).contains(effect!) else { return }
        selection.weaponEffectID = effect; saveSelection()
    }
    var hasFounderExtras: Bool { configuration.hasFounderExtras(owned: entitlements) }
    var goldenTrails: Bool { hasFounderExtras && selection.goldenTrails }
    var founderBadge: Bool { hasFounderExtras && selection.founderBadge }
    func setFinish(_ finish: RobotFinish?, for robotID: String) {
        if let finish {
            guard finish.robotID == robotID, configuration.availableFinishes(owned: entitlements).contains(finish) else { return }
            selection.robotFinishIDs[robotID] = finish.id
        } else { selection.robotFinishIDs.removeValue(forKey: robotID) }
        saveSelection()
    }
    func setGoldenTrails(_ enabled: Bool) { selection.goldenTrails = hasFounderExtras && enabled; saveSelection() }
    func setFounderBadge(_ enabled: Bool) { selection.founderBadge = hasFounderExtras && enabled; saveSelection() }
    private func saveSelection() {
        if let data = try? JSONEncoder().encode(selection) { UserDefaults.standard.set(data, forKey: selectionKey) }
    }
    func start() async {
        if updates == nil {
            updates = Task { [weak self] in
                for await result in StoreKit.Transaction.updates {
                    guard !Task.isCancelled, let self else { return }
                    await self.accept(result)
                }
            }
        }
        await refresh()
    }
    func refresh() async {
        guard !loading else { return }
        loading = true; messageKey = nil; defer { loading = false }
        await loadProductsAndEntitlements()
    }
    private func loadProductsAndEntitlements() async {
        do {
            let loaded = try await Product.products(for: configuration.productIDs).filter { $0.type == .nonConsumable }
            products = configuration.productIDs.compactMap { id in loaded.first { $0.id == id } }
            if products.count < configuration.packs.count { messageKey = "shop.unavailable" }
        } catch { products = []; messageKey = "error.purchase" }
        var owned = Set<String>()
        for await result in StoreKit.Transaction.currentEntitlements {
            if case .verified(let transaction) = result, transaction.revocationDate == nil,
               transaction.productType == .nonConsumable, configuration.productIDs.contains(transaction.productID) {
                owned.insert(transaction.productID)
            }
        }
        entitlements = owned
        selection.reconcile(catalog: configuration, owned: owned); saveSelection()
    }
    func purchase(_ product: Product) async {
        guard !loading, product.type == .nonConsumable, configuration.productIDs.contains(product.id), configuration.canPurchase(product.id, owned: entitlements) else { return }
        loading = true; messageKey = nil; defer { loading = false }
        await loadProductsAndEntitlements()
        guard configuration.canPurchase(product.id, owned: entitlements) else { messageKey = "premium.bundle.overlap"; return }
        do {
            switch try await product.purchase() {
            case .success(let result): await accept(result)
            case .pending: messageKey = "shop.pending"
            case .userCancelled: messageKey = "shop.cancelled"
            @unknown default: messageKey = "error.purchase"
            }
        } catch { messageKey = "error.purchase" }
    }
    private func accept(_ result: VerificationResult<StoreKit.Transaction>) async {
        guard case .verified(let transaction) = result else { messageKey = "error.purchase"; return }
        guard transaction.productType == .nonConsumable, configuration.productIDs.contains(transaction.productID) else { return }
        if transaction.revocationDate == nil { entitlements.insert(transaction.productID) }
        else { entitlements.remove(transaction.productID) }
        selection.reconcile(catalog: configuration, owned: entitlements); saveSelection()
        await transaction.finish()
        messageKey = transaction.revocationDate == nil ? "shop.verified" : "shop.revoked"
    }
    func restore() async {
        guard !loading else { return }
        loading = true; messageKey = nil; defer { loading = false }
        do {
            try await AppStore.sync(); await loadProductsAndEntitlements()
            messageKey = entitlements.isEmpty ? "shop.restore.empty" : "shop.restored"
        } catch { messageKey = "error.purchase" }
    }
}

@MainActor @Observable final class GameCenterService {
    // Enable only after configuring the entitlement, leaderboard IDs and privacy disclosures.
    let enabled = false
    var authenticated = false
    func authenticate() {
        guard enabled else { return }
        GKLocalPlayer.local.authenticateHandler = { [weak self] controller, _ in
            Task { @MainActor in
                self?.authenticated = GKLocalPlayer.local.isAuthenticated
                if let controller { self?.present(controller) }
            }
        }
    }
    func leaderboards() {
        guard enabled else { return }
        guard authenticated else { authenticate(); return }
        present(GKGameCenterViewController(state: .leaderboards))
    }
    func report(profile: PlayerProfile, content: GameContent, reward: RunReward) {
        guard enabled, authenticated else { return }
        let achievements = Progression.achievements(profile, content: content).map { id, percent in
            let achievement = GKAchievement(identifier: "scrapsquad." + id)
            achievement.percentComplete = percent; achievement.showsCompletionBanner = true; return achievement
        }
        GKAchievement.report(achievements) { _ in }
        if let leaderboard = reward.mode.leaderboard {
            GKLeaderboard.submitScore(reward.score, context: 0, player: GKLocalPlayer.local, leaderboardIDs: [leaderboard]) { _ in }
        }
    }
    private let delegate = GameCenterDismissal()
    private func present(_ controller: UIViewController) {
        if let gameCenter = controller as? GKGameCenterViewController { gameCenter.gameCenterDelegate = delegate }
        guard let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first(where: { $0.activationState == .foregroundActive }),
              var top = scene.windows.first(where: \.isKeyWindow)?.rootViewController else { return }
        while let presented = top.presentedViewController { top = presented }
        top.present(controller, animated: true)
    }
}
final class GameCenterDismissal: NSObject, GKGameCenterControllerDelegate {
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        Task { @MainActor in gameCenterViewController.dismiss(animated: true) }
    }
}

enum AudioCue: String { case city, battle, boss, weapon, explosion, robot, fusion, victory, ui, ability, combo, overdrive }
@MainActor final class AudioBus {
    static let shared = AudioBus()
    private var music: AVAudioPlayer?
    private var voices: [AVAudioPlayer] = []
    private init() { try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers]) }
    func play(_ cue: AudioCue, preferences: Preferences) {
        let isMusic = [.city, .battle, .boss].contains(cue)
        let volume = preferences.masterVolume * (isMusic ? preferences.musicVolume : preferences.sfxVolume)
        guard volume > 0 else { return }
        if let url = Bundle.main.url(forResource: cue.rawValue, withExtension: "wav"), let player = try? AVAudioPlayer(contentsOf: url) {
            player.volume = Float(volume)
            if isMusic { music?.stop(); music = player; player.numberOfLoops = -1 }
            else { voices.removeAll { !$0.isPlaying }; if voices.count >= 8 { voices.removeFirst().stop() }; voices.append(player) }
            player.play()
        } else if !isMusic { playTone(frequency: cue == .fusion ? 660 : 440, volume: volume) }
    }
    func stop() { music?.stop(); voices.forEach { $0.stop() }; voices = [] }
    private func playTone(frequency: Double, volume: Double) {
        let rate = 22050, count = 3307
        var data = Data()
        func ascii(_ value: String) { data.append(contentsOf: value.utf8) }
        func word<T: FixedWidthInteger>(_ value: T) { var little = value.littleEndian; withUnsafeBytes(of: &little) { data.append(contentsOf: $0) } }
        ascii("RIFF"); word(UInt32(36 + count * 2)); ascii("WAVEfmt "); word(UInt32(16)); word(UInt16(1)); word(UInt16(1))
        word(UInt32(rate)); word(UInt32(rate * 2)); word(UInt16(2)); word(UInt16(16)); ascii("data"); word(UInt32(count * 2))
        for index in 0..<count {
            let envelope = sin(Double(index) / Double(count) * .pi)
            word(Int16(sin(Double(index) / Double(rate) * frequency * .pi * 2) * envelope * 5000))
        }
        if let player = try? AVAudioPlayer(data: data) { player.volume = Float(volume); voices.removeAll { !$0.isPlaying }; voices.append(player); player.play() }
    }
}
enum FeedbackKind { case build, fusion, ability }
@MainActor enum Feedback {
    static func play(_ kind: FeedbackKind, preferences: Preferences) {
        if preferences.haptics {
            if kind == .fusion { UINotificationFeedbackGenerator().notificationOccurred(.success) }
            else { UIImpactFeedbackGenerator(style: kind == .ability ? .heavy : .light).impactOccurred() }
        }
        AudioBus.shared.play(kind == .fusion ? .fusion : kind == .ability ? .ability : .ui, preferences: preferences)
    }
}
