import SwiftUI

@main
struct DashpadApp: App {
    @State private var splashFinished = false
    @State private var store = DashStore.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ZStack {
                NavigationStack {
                    ContentView()
                }
                .opacity(splashFinished ? 1 : 0)

                if !splashFinished {
                    SplashView(isFinished: $splashFinished)
                        .transition(.opacity)
                }
            }
            .environment(store)
            .onChange(of: scenePhase) { _, phase in
                // Auto-filing is the product: any idea that slipped through
                // untagged gets another pass whenever the app wakes up.
                if phase == .active { store.enrichUntagged() }
            }
        }
    }
}
