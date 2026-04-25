import SwiftUI

@main
struct DashpadApp: App {
    @State private var splashFinished = false
    @State private var store = DashStore.shared
    
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
        }
    }
}
