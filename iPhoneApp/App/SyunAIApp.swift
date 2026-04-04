import SwiftUI

@main
struct SyunAIApp: App {
    @StateObject private var connectivityService = PhoneConnectivityService()

    var body: some Scene {
        WindowGroup {
            PhoneHomeView()
                .environmentObject(connectivityService)
        }
    }
}
