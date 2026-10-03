import SwiftUI
import ScrapCore

struct SettingsView: View {
    @Environment(GameStore.self) var store
    @Environment(GameCenterService.self) var gameCenter
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var rebootConfirm = false
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    toggle("settings.haptics", \.haptics)
                    toggle("settings.motion", \.reducedMotion)
                    toggle("settings.flashes", \.reducedFlashes)
                    toggle("settings.shake", \.screenShake)
                    toggle("settings.numbers", \.damageNumbers)
                    slider("settings.particles", \.particleIntensity)
                }
                Section {
                    slider("settings.master", \.masterVolume)
                    slider("settings.music", \.musicVolume)
                    slider("settings.sfx", \.sfxVolume)
                }
                Section {
                    Picker(selection: binding(\.locale)) {
                        LText("settings.system").tag("system")
                        ForEach(LocaleManager.available, id: \.self) { code in Text(Locale(identifier: code).localizedString(forIdentifier: code) ?? code).tag(code) }
                    } label: { LText("settings.language") }
                }
                if gameCenter.enabled {
                    Section {
                        Button { gameCenter.authenticate() } label: { LText("settings.gamecenter") }
                        Button { gameCenter.leaderboards() } label: { LText("settings.leaderboards") }
                    }
                }
                Section {
                    Link("Privacy Policy", destination: URL(string: "https://lanray07.github.io/Scrap-Squad/privacy.html")!)
                    Link("Support", destination: URL(string: "https://github.com/lanray07/Scrap-Squad/issues")!)
                }
                Section {
                    ForEach(Progression.achievements(store.profile, content: store.content).keys.sorted(), id: \.self) { id in
                        VStack(alignment: .leading) { LText("achievement." + id); ProgressView(value: Progression.achievements(store.profile, content: store.content)[id, default: 0], total: 100) }
                    }
                } header: { LText("achievements.title") }
                Section {
                    LText("settings.reboot.detail").font(.caption)
                    Button(role: .destructive) { rebootConfirm = true } label: { LText("settings.reboot.confirm") }.disabled(store.profile.zone < store.content.economy.rebootZone)
                } header: { LText("settings.reboot") }
            }
            .navigationTitle(Text(LocalizationManager.string("settings.title", locale: store.profile.preferences.locale)))
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("common.done") { store.save(); dismiss() } } }
            .confirmationDialog(Text(LocalizationManager.string("settings.reboot")), isPresented: $rebootConfirm, titleVisibility: .visible) {
                Button("settings.reboot.confirm", role: .destructive) { store.perform { try Progression.reboot(&$0, content: store.content) } }
                Button("common.cancel", role: .cancel) {}
            } message: { LText("settings.reboot.detail") }
        }.preferredColorScheme(.dark).onAppear { if reduceMotion { store.profile.preferences.reducedMotion = true } }
    }
    func binding<T>(_ path: WritableKeyPath<Preferences, T>) -> Binding<T> {
        Binding(get: { store.profile.preferences[keyPath: path] }, set: { store.profile.preferences[keyPath: path] = $0; store.save(); AudioBus.shared.stop() })
    }
    func toggle(_ key: String, _ path: WritableKeyPath<Preferences, Bool>) -> some View { Toggle(isOn: binding(path)) { LText(key) } }
    func slider(_ key: String, _ path: WritableKeyPath<Preferences, Double>) -> some View {
        VStack(alignment: .leading) { LText(key); Slider(value: binding(path), in: 0...1).accessibilityLabel(Text(LocalizationManager.string(key))) }
    }
}
