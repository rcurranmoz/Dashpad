import SwiftUI

struct SplashView: View {
    @Environment(DashStore.self) private var store
    @Binding var isFinished: Bool

    @State private var flameScale: CGFloat = 4.0
    @State private var flameOpacity: Double = 0
    @State private var flameRotation: Double = 0
    @State private var glowOpacity: Double = 0
    @State private var showTitle = false
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = 12
    @State private var showTagline = false

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

            // Ambient glow behind flame
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.orange.opacity(0.3), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 180
                    )
                )
                .frame(width: 360, height: 360)
                .scaleEffect(flameScale * 0.5)
                .opacity(glowOpacity)
                .blur(radius: 20)

            VStack(spacing: 16) {
                // Flame
                Text("🔥")
                    .font(.system(size: 72))
                    .scaleEffect(flameScale)
                    .rotationEffect(.degrees(flameRotation))
                    .opacity(flameOpacity)

                // Title + tagline appear as flame settles
                VStack(spacing: 6) {
                    Text("Dashpad")
                        .font(Dash.Typography.largeTitle)
                        .tracking(-0.5)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Dash.Colors.accentGradStart, Dash.Colors.accent, Dash.Colors.textPrimary.opacity(0.9)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text(tagline)
                        .font(Dash.Typography.caption)
                        .foregroundStyle(Dash.Colors.textSecondary)
                        .opacity(showTagline ? 1 : 0)
                }
                .opacity(titleOpacity)
                .offset(y: titleOffset)
            }
        }
        .onAppear { startAnimation() }
    }

    private func startAnimation() {
        // 0.0s — flame slams in huge
        withAnimation(.spring(response: 0.25, dampingFraction: 0.45)) {
            flameOpacity = 1
            glowOpacity = 1
        }

        // 0.15s — wobble left
        withAnimation(.easeInOut(duration: 0.1).delay(0.15)) { flameRotation = -12 }
        // 0.25s — wobble right
        withAnimation(.easeInOut(duration: 0.1).delay(0.25)) { flameRotation = 10 }
        // 0.35s — settle
        withAnimation(.spring(response: 0.2, dampingFraction: 0.6).delay(0.35)) { flameRotation = 0 }

        // 0.55s — flame shrinks down
        withAnimation(.spring(response: 0.5, dampingFraction: 0.62).delay(0.55)) {
            flameScale = 0.65
            glowOpacity = 0
        }

        // 0.85s — title slides up
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.85)) {
            titleOpacity = 1
            titleOffset = 0
        }

        // 1.0s — tagline fades in
        withAnimation(.easeOut(duration: 0.25).delay(1.0)) { showTagline = true }

        // 1.9s — done
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.9) {
            withAnimation(.easeOut(duration: 0.2)) { isFinished = true }
        }
    }
}
