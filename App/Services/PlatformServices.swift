import SwiftUI
import UIKit
import StoreKit
import GameKit
import AVFoundation
import ScrapCore

struct StoreConfiguration: Codable {
    let cosmeticProductIDs: [String]
    // Product IDs must map to a visible, implemented robot finish before being offered.
    let finishes: [String: RobotFinish]
    static func bundled() -> StoreConfiguration {
        guard let url = Bundle.main.url(forResource: "StoreConfiguration", withExtension: "json"),
              let data = try? Data(contentsOf: url), let config = try? JSONDecoder().decode(Self.self, from: data) else {
            return StoreConfiguration(cosmeticProductIDs: [], finishes: [:])
        }
        return config
    }
}
struct RobotFinish: Codable { let robotID: String; let tint: String }
@MainActor @Observable final class CommerceService {
    var products: [Product] = []
    var entitlements: Set<String> = []
    var messageKey: String?
    var loading = false
    private var updates: Task<Void, Never>?
    let configuration = StoreConfiguration.bundled()
    var robotFinishes: [String: String] {
        var finishes: [String: String] = [:]
        for id in entitlements.sorted() { if let finish = configuration.finishes[id] { finishes[finish.robotID] = finish.tint } }
        return finishes
    }
    func start() async {
        if updates == nil {
            updates = Task { [weak self] in
                for await result in Transaction.updates {
                    guard !Task.isCancelled, let self else { return }
                    await self.accept(result)
                }
            }
        }
        await refresh()
    }
    func refresh() async {
        loading = true; defer { loading = false }
        do { products = try await Product.products(for: configuration.cosmeticProductIDs).filter { $0.type == .nonConsumable && configuration.finishes[$0.id] != nil } }
        catch { messageKey = "error.purchase" }
        var owned = Set<String>()
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.revocationDate == nil,
               configuration.cosmeticProductIDs.contains(transaction.productID) {
                owned.insert(transaction.productID)
            }
        }
        entitlements = owned
    }
    func purchase(_ product: Product) async {
        guard !loading else { return }
        loading = true
        defer { loading = false }
        do {
            switch try await product.purchase() {
            case .success(let result): await accept(result)
            case .pending: messageKey = "shop.pending"
            case .userCancelled: break
            @unknown default: messageKey = "error.purchase"
            }
        } catch { messageKey = "error.purchase" }
    }
    private func accept(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = result else { messageKey = "error.purchase"; return }
        guard configuration.cosmeticProductIDs.contains(transaction.productID) else { return }
        if transaction.revocationDate == nil { entitlements.insert(transaction.productID) }
        else { entitlements.remove(transaction.productID) }
        // Entitlement is applied before acknowledging the transaction.
        await transaction.finish()
        messageKey = "shop.verified"
    }
    func restore() async {
        do { try await AppStore.sync(); await refresh(); messageKey = "shop.restored" }
        catch { messageKey = "error.purchase" }
    }
}

@MainActor @Observable final class GameCenterService {
    var authenticated = false
    func authenticate() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] controller, _ in
            Task { @MainActor in
                self?.authenticated = GKLocalPlayer.local.isAuthenticated
                if let controller { self?.present(controller) }
            }
        }
    }
    func leaderboards() {
        guard authenticated else { authenticate(); return }
        present(GKGameCenterViewController(state: .leaderboards))
    }
    func report(profile: PlayerProfile, content: GameContent, reward: RunReward) {
        guard authenticated else { return }
        let achievements = Progression.achievements(profile, content: content).map { id, percent in
            let achievement = GKAchievement(identifier: "scrapsquad." + id)
            achievement.percentComplete = percent; achievement.showsCompletionBanner = true; return achievement
        }
        GKAchievement.report(achievements) { _ in }
        if let leaderboard = reward.mode.leaderboard {
            GKLeaderboard.submitScore(reward.score, context: 0, player: .local, leaderboardIDs: [leaderboard]) { _ in }
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
@MainActor final class GameCenterDismissal: NSObject, GKGameCenterControllerDelegate {
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) { gameCenterViewController.dismiss(animated: true) }
}

enum AudioCue: String { case city, battle, boss, weapon, explosion, robot, fusion, victory, ui }
@MainActor final class AudioBus {
    static let shared = AudioBus()
    private var music: AVAudioPlayer?
    private var voices: [AVAudioPlayer] = []
    func play(_ cue: AudioCue, preferences: Preferences) {
        let isMusic = [.city, .battle, .boss].contains(cue)
        let volume = preferences.masterVolume * (isMusic ? preferences.musicVolume : preferences.sfxVolume)
        guard volume > 0 else { return }
        if let url = Bundle.main.url(forResource: cue.rawValue, withExtension: "wav"), let player = try? AVAudioPlayer(contentsOf: url) {
            player.volume = Float(volume)
            if isMusic { music?.stop(); music = player; player.numberOfLoops = -1 }
            else { voices.removeAll { !$0.isPlaying }; voices.append(player) }
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
        AudioBus.shared.play(kind == .fusion ? .fusion : .ui, preferences: preferences)
    }
}
