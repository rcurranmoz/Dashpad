import SwiftUI

struct IdeaCard: View {
    let item: DashItem
    let onArchive: () -> Void
    let onEdit: () -> Void

    @Environment(DashStore.self) private var store

    @State private var isArchiving = false

    private var isEnriching: Bool { store.enrichingIDs.contains(item.id) }
    @State private var showParticles = false
    @State private var particleProgress: CGFloat = 0
    @State private var particleOpacity: Double = 1

    private var isOverdue: Bool {
        guard let due = item.dueDate else { return false }
        return due < Date()
    }

    private var tagColor: Color? {
        item.tags.first.map { Color(hex: TagPredictor.color(for: $0)) }
    }

    private var miniTimeLabel: String? {
        guard let due = item.dueDate else { return nil }
        let cal = Calendar.current
        if due < Date() { return "overdue" }
        if cal.isDateInToday(due) { return due.formatted(date: .omitted, time: .shortened).lowercased() }
        if cal.isDateInTomorrow(due) { return "tmrw" }
        let days = cal.dateComponents([.day], from: Date(), to: due).day ?? 0
        if days <= 6 { return due.formatted(.dateTime.weekday(.abbreviated)).lowercased() }
        return due.formatted(.dateTime.month(.abbreviated).day())
    }

    private var miniTimeLabelColor: Color {
        guard let due = item.dueDate else { return Dash.Colors.textTertiary }
        if due < Date() { return Dash.Colors.danger }
        if Calendar.current.isDateInToday(due) { return Dash.Colors.warning }
        return Dash.Colors.textTertiary
    }

    var body: some View {
        Button { onEdit() } label: {
                HStack(alignment: .top, spacing: Dash.Spacing.md) {
                    archiveButton
                        .padding(.leading, Dash.Spacing.lg)
                        .padding(.top, Dash.Spacing.md)

                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .top, spacing: Dash.Spacing.sm) {
                            Text(item.title)
                                .font(Dash.Typography.idea)
                                .foregroundStyle(isArchiving ? Dash.Colors.textTertiary : Dash.Colors.textPrimary)
                                .strikethrough(isArchiving, color: Dash.Colors.textTertiary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            if item.isPinned {
                                Image(systemName: "pin.fill")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(Dash.Colors.accent.opacity(0.8))
                                    .rotationEffect(.degrees(45))
                            }

                            if isEnriching {
                                // On-device model is reading this idea right now
                                Image(systemName: "sparkles")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(Dash.Colors.accent)
                                    .symbolEffect(.pulse, options: .repeating)
                                    .transition(.scale.combined(with: .opacity))
                            }

                            if let label = miniTimeLabel {
                                Text(label)
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .foregroundStyle(miniTimeLabelColor)
                                    .opacity(isArchiving ? 0.4 : 1)
                            }
                        }

                        if let bodyText = item.body, !bodyText.isEmpty {
                            Text(bodyText)
                                .font(Dash.Typography.ideaBody)
                                .foregroundStyle(Dash.Colors.textTertiary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }

                        // Quiet ink annotations — a colored dot and a name,
                        // like a margin note, not a badge.
                        if !item.tags.isEmpty {
                            HStack(spacing: Dash.Spacing.md) {
                                ForEach(item.tags.prefix(3), id: \.self) { tag in
                                    HStack(spacing: 5) {
                                        Circle()
                                            .fill(Color(hex: TagPredictor.color(for: tag)))
                                            .frame(width: 5, height: 5)
                                        Text(TagPredictor.friendlyName(for: tag).uppercased())
                                            .font(.system(size: 9.5, weight: .semibold))
                                            .tracking(0.8)
                                            .foregroundStyle(Color(hex: TagPredictor.color(for: tag)).opacity(0.85))
                                    }
                                }
                                if item.tags.count > 3 {
                                    Text("+\(item.tags.count - 3)")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundStyle(Dash.Colors.textTertiary)
                                }
                            }
                            .padding(.top, 2)
                            .transition(.scale(scale: 0.85, anchor: .leading).combined(with: .opacity))
                        }
                    }
                    .padding(.vertical, Dash.Spacing.lg)
                    .padding(.trailing, Dash.Spacing.lg)
            }
            .dashCard(glow: cardGlow)
            .opacity(isArchiving ? 0.5 : 1)
        }
        .buttonStyle(.plain)
    }

    private var cardGlow: Color {
        if item.isPinned { return Dash.Colors.accentDim.opacity(0.5) }
        if isOverdue { return Dash.Colors.dangerDim.opacity(0.5) }
        return .clear
    }

    // MARK: - Archive Button

    private var archiveButton: some View {
        Button { triggerArchive() } label: {
            ZStack {
                if showParticles {
                    // Sparks fly off when an idea is done
                    ForEach(0..<7, id: \.self) { i in
                        let angle = (Double(i) / 7.0) * 2 * .pi
                        Circle()
                            .fill(i.isMultiple(of: 2) ? Dash.Colors.accentBright : Dash.Colors.accentDeep)
                            .frame(width: i.isMultiple(of: 3) ? 3 : 4.5, height: i.isMultiple(of: 3) ? 3 : 4.5)
                            .offset(
                                x: Foundation.cos(angle) * 18 * particleProgress,
                                y: Foundation.sin(angle) * 18 * particleProgress
                            )
                            .opacity(particleOpacity)
                    }
                }

                Circle()
                    .fill(isArchiving ? Dash.Colors.success : .clear)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle().stroke(
                            isArchiving ? Dash.Colors.success
                                : isOverdue ? Dash.Colors.danger.opacity(0.6)
                                : (tagColor?.opacity(0.45) ?? Dash.Colors.textTertiary.opacity(0.55)),
                            lineWidth: 1.5
                        )
                    )
                    .scaleEffect(isArchiving ? 1.1 : 1.0)

                if isArchiving {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                }

                if isOverdue && !isArchiving {
                    Circle().fill(Dash.Colors.dangerDim).frame(width: 24, height: 24)
                    Circle().fill(Dash.Colors.danger).frame(width: 6, height: 6)
                }
            }
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Archive animation

    private func triggerArchive() {
        guard !isArchiving else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            isArchiving = true
        }

        showParticles = true
        particleProgress = 0
        particleOpacity = 1
        withAnimation(.easeOut(duration: 0.5)) {
            particleProgress = 1
            particleOpacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            onArchive()
        }
    }
}
