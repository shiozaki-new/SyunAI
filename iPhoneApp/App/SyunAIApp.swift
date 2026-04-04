import SwiftUI

@main
struct SyunAIApp: App {
    @StateObject private var connectivityService = PhoneConnectivityService()
    @StateObject private var modelManager = ModelManager()

    var body: some Scene {
        WindowGroup {
            PhoneHomeView()
                .environmentObject(connectivityService)
                .environmentObject(modelManager)
        }
    }
}
