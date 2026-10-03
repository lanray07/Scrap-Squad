import SwiftUI
import ScrapCore

@main struct ScrapSquadApp: App {
    private let contentResult = Result { try GameContent.bundled() }
    var body: some Scene {
        WindowGroup {
            switch contentResult {
            case .success(let content): RootView(store: GameStore(content: content))
            case .failure: ContentUnavailableView {
                Label(Text("error.invalidContent"), systemImage: "exclamationmark.triangle")
            }
            }
        }
    }
}
