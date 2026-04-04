import SwiftUI

@main
struct SyunAIWatchApp: App {
    @StateObject private var viewModel = WatchChatViewModel()

    var body: some Scene {
        WindowGroup {
            WatchHomeView()
                .environmentObject(viewModel)
        }
    }
}
