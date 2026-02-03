import SwiftUI

struct SplashView: View {
    @Environment(DashStore.self) private var store
    
    @State private var showLogo = false
    @State private var showCount = false
    @Binding var isFinished: Bool
    
    private var funMessage: String {
        let count = store.completedCount
        switch count {
        case 0:
            return "Ready to crush it"
        case 1...5:
            return "\(count) tasks crushed"
        case 6...20:
            return "\(count) tasks crushed 💪"
        case 21...50:
            return "\(count) tasks demolished"
        case 51...100:
            return "\(count) tasks destroyed 🔥"
        default:
            return "\(count) tasks annihilated 🚀"
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            Dash.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Logo mark - three stacked lines like icon 02
                VStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [Dash.Colors.accentLight, Dash.Colors.accent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 64, height: 10)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Dash.Colors.accent.opacity(0.6))
                        .frame(width: 48, height: 8)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Dash.Colors.accent.opacity(0.3))
                        .frame(width: 32, height: 6)
                }
                .scaleEffect(showLogo ? 1 : 0.5)
                .opacity(showLogo ? 1 : 0)
                
                // App name
                Text("Dashpad")
                    .font(.system(size: 28, weight: .semibold, design: .default))
                    .foregroundStyle(Dash.Colors.textPrimary)
                    .opacity(showLogo ? 1 : 0)
                
                // Fun count
                Text(funMessage)
                    .font(Dash.Typography.caption)
                    .foregroundStyle(Dash.Colors.textSecondary)
                    .opacity(showCount ? 1 : 0)
                    .offset(y: showCount ? 0 : 10)
            }
        }
        .onAppear {
            // Animate in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showLogo = true
            }
            
            withAnimation(.easeOut(duration: 0.3).delay(0.2)) {
                showCount = true
            }
            
            // Dismiss after brief moment
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeOut(duration: 0.2)) {
                    isFinished = true
                }
            }
        }
    }
}
