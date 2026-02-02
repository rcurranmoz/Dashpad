import SwiftUI
import SwiftData

@main
struct DashpadApp: App {
    @State private var splashFinished = false
    
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
        }
        .modelContainer(for: DashItem.self)
    }
}
