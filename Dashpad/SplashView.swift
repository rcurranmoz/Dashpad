import SwiftUI

struct SplashView: View {
    @Environment(DashStore.self) private var store
    @Binding var isFinished: Bool

    @State private var bulbOpacity: Double = 0
    @State private var bulbScale: CGFloat = 0.9
    @State private var bulbGlow: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = 14
    @State private var strokeProgress: CGFloat = 0
    @State private var dotVisible = false
    @State private var showTagline = false
    @State private var glowOpacity: Double = 0

    private var tagline: String {
        let count = store.archivedCount
        switch count {
        case 0: return "Ready to capture"
        case 1: return "1 idea acted on"
        case 2...10: return "\(count) ideas acted on"
        case 11...50: return "\(count) ideas captured"
        case 51...200: return "\(count) ideas and counting"
        default: return "You've been busy"
        }
    }

    var body: some View {
        ZStack {
            Dash.Colors.background.ignoresSafeArea()

            // Ember floor glow warms up as the ink goes down
            RadialGradient(
                colors: [Dash.Colors.emberGlow.opacity(0.7), .clear],
                center: UnitPoint(x: 0.5, y: 1.15),
                startRadius: 30,
                endRadius: 480
            )
            .ignoresSafeArea()
            .opacity(glowOpacity)

            VStack(spacing: 18) {
                // The idea strikes: a bulb flickers to life…
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 46))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "FFE29A"), Dash.Colors.accentBright],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .shadow(color: Dash.Colors.accentBright.opacity(bulbGlow), radius: 22)
                    .shadow(color: Color(hex: "FFE29A").opacity(bulbGlow * 0.6), radius: 8)
                    .opacity(bulbOpacity)
                    .scaleEffect(bulbScale)
                    .padding(.bottom, 6)

                VStack(spacing: 8) {
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("Dashpad")
                            .font(.system(size: 42, weight: .bold, design: .serif))
                            .foregroundStyle(Dash.Colors.textPrimary)

                        Circle()
                            .fill(LinearGradient(
                                colors: [Dash.Colors.accentBright, Dash.Colors.accentDeep],
                                startPoint: .top, endPoint: .bottom
                            ))
                            .frame(width: 9, height: 9)
                            .shadow(color: Dash.Colors.accent.opacity(0.9), radius: 6)
                            .scaleEffect(dotVisible ? 1 : 0.01, anchor: .center)
                    }
                    .opacity(titleOpacity)
                    .offset(y: titleOffset)

                    // The scribble: a hand-drawn underline inking itself in
                    ScribbleUnderline()
                        .trim(from: 0, to: strokeProgress)
                        .stroke(
                            LinearGradient(
                                colors: [Dash.Colors.accentBright, Dash.Colors.accentDeep],
                                startPoint: .leading, endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 4.5, lineCap: .round, lineJoin: .round)
                        )
                        .frame(width: 200, height: 16)
                        .shadow(color: Dash.Colors.accent.opacity(0.45), radius: 8, y: 2)
                }

                Text(tagline.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.6)
                    .foregroundStyle(Dash.Colors.textTertiary)
                    .opacity(showTagline ? 1 : 0)
            }
        }
        .onAppear { startAnimation() }
    }

    // The story: an idea strikes (the bulb flickers on), and you jot it
    // down before it escapes (the scribble). That's the whole app.
    private func startAnimation() {
        // Load the on-device model while the ink dries,
        // so the first capture gets filed without a cold start.
        DashIntelligence.prewarm()

        // 0.0–0.45s — the bulb sputters: flick… flick… ON
        let flicker: [(Double, Double)] = [
            (0.08, 0.85), (0.16, 0.15), (0.26, 0.95), (0.34, 0.35),
        ]
        for (delay, opacity) in flicker {
            withAnimation(.easeIn(duration: 0.06).delay(delay)) {
                bulbOpacity = opacity
                bulbGlow = opacity * 0.5
            }
        }
        // 0.45s — it catches: full glow, happy little bounce
        withAnimation(.spring(response: 0.32, dampingFraction: 0.55).delay(0.45)) {
            bulbOpacity = 1
            bulbGlow = 0.9
            bulbScale = 1.08
        }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.62)) {
            bulbScale = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.6)
        }
        withAnimation(.easeOut(duration: 1.2).delay(0.45)) { glowOpacity = 1 }

        // 0.65s — wordmark rises in under the lit bulb
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8).delay(0.65)) {
            titleOpacity = 1
            titleOffset = 0
        }

        // 0.9s — jot it down: the underline scribbles in fast
        withAnimation(.easeInOut(duration: 0.42).delay(0.9)) {
            strokeProgress = 1
        }

        // 1.35s — the ember full stop lands
        withAnimation(.spring(response: 0.32, dampingFraction: 0.5).delay(1.35)) {
            dotVisible = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.35) {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }

        // 1.5s — tagline settles in
        withAnimation(.easeOut(duration: 0.25).delay(1.5)) { showTagline = true }

        // 2.15s — hand off to the cascade
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.15) {
            withAnimation(.easeOut(duration: 0.25)) { isFinished = true }
        }
    }
}

/// A wobbly, hand-drawn underline — drawn via `.trim` so it inks in
/// left to right like a real pen stroke.
struct ScribbleUnderline: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let y = rect.midY
        let w = rect.width
        p.move(to: CGPoint(x: rect.minX, y: y + 2))
        p.addCurve(
            to: CGPoint(x: rect.minX + w * 0.36, y: y - 3),
            control1: CGPoint(x: rect.minX + w * 0.12, y: y + 6),
            control2: CGPoint(x: rect.minX + w * 0.24, y: y - 6)
        )
        p.addCurve(
            to: CGPoint(x: rect.minX + w * 0.72, y: y + 3),
            control1: CGPoint(x: rect.minX + w * 0.48, y: y + 1),
            control2: CGPoint(x: rect.minX + w * 0.60, y: y + 7)
        )
        p.addCurve(
            to: CGPoint(x: rect.maxX, y: y - 2),
            control1: CGPoint(x: rect.minX + w * 0.84, y: y - 1),
            control2: CGPoint(x: rect.minX + w * 0.94, y: y - 6)
        )
        return p
    }
}
