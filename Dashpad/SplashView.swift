import SwiftUI

struct SplashView: View {
    @Environment(DashStore.self) private var store
    @State private var showLogo = false
    @State private var showTagline = false
    @Binding var isFinished: Bool

    private var tagline: String {
        let count = store.archivedCount
        switch count {
        case 0: return "Ready to capture"
        case 1: return "1 idea acted on"
        case 2...10: return "\(count) ideas acted on"
        case 11...50: return "\(count) ideas captured 🧠"
        case 51...200: return "\(count) ideas and counting 🚀"
        default: return "You've been busy 🔥"
        }
    }

    var body: some View {
        ZStack {
            Dash.Colors.background.ignoresSafeArea()

            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(
                            colors: [Dash.Colors.accentLight, Dash.Colors.accent],
                            startPoint: .leading, endPoint: .trailing
                        ))
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

                Text("Dashpad")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(Dash.Colors.textPrimary)
                    .opacity(showLogo ? 1 : 0)

                Text(tagline)
                    .font(Dash.Typography.caption)
                    .foregroundStyle(Dash.Colors.textSecondary)
                    .opacity(showTagline ? 1 : 0)
                    .offset(y: showTagline ? 0 : 10)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { showLogo = true }
            withAnimation(.easeOut(duration: 0.3).delay(0.2)) { showTagline = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeOut(duration: 0.2)) { isFinished = true }
            }
        }
    }
}
