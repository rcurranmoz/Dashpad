import SwiftUI

struct IdeaCard: View {
    let item: DashItem
    let onArchive: () -> Void
    let onEdit: () -> Void

    @State private var isArchiving = false
    @State private var showParticles = false
    @State private var particleProgress: CGFloat = 0
    @State private var particleOpacity: Double = 1

    private var isOverdue: Bool {
        guard let due = item.dueDate else { return false }
        return due < Date() && !item.isArchived
    }

    private var miniTimeLabel: String? {
        guard let due = item.dueDate else { return nil }
        let cal = Calendar.current
        if due < Date() { return "overdue" }
        if cal.isDateInToday(due) { return due.formatted(date: .omitted, time: .shortened).lowercased() }
        if cal.isDateInTomorrow(due) { return "tomorrow" }
        let days = cal.dateComponents([.day], from: Date(), to: due).day ?? 0
        if days <= 6 { return due.formatted(.dateTime.weekday(.abbreviated)).lowercased() }
        return due.formatted(.dateTime.month(.abbreviated).day())
    }

    private var miniTimeLabelColor: Color {
        guard let due = item.dueDate else { return Dash.Colors.textTertiary }
        if due < Date() { return Dash.Colors.overdue }
        if Calendar.current.isDateInToday(due) { return Dash.Colors.warning }
        return Dash.Colors.textTertiary
    }

    var body: some View {
        HStack(spacing: Dash.Spacing.md) {
            archiveButton

            Button { onEdit() } label: {
                VStack(alignment: .leading, spacing: Dash.Spacing.xs) {
                    HStack(alignment: .top) {
                        Text(item.title)
                            .font(Dash.Typography.body)
                            .foregroundStyle(isArchiving ? Dash.Colors.textTertiary : Dash.Colors.textPrimary)
                            .strikethrough(isArchiving, color: Dash.Colors.textTertiary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        if let label = miniTimeLabel {
                            Text(label)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(miniTimeLabelColor)
                                .opacity(isArchiving ? 0.4 : 1)
                        }
                    }

                    if let bodyText = item.body, !bodyText.isEmpty {
                        Text(bodyText)
                            .font(Dash.Typography.caption)
                            .foregroundStyle(Dash.Colors.textTertiary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }

                    if !item.tags.isEmpty {
                        HStack(spacing: Dash.Spacing.xs) {
                            ForEach(item.tags.prefix(3), id: \.self) { tag in
                                TagDot(tag: tag)
                            }
                            if item.tags.count > 3 {
                                Text("+\(item.tags.count - 3)")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(Dash.Colors.textTertiary)
                            }
                        }
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(isArchiving)
        }
        .padding(Dash.Spacing.lg)
        .background(cardBackground)
        .opacity(isArchiving ? 0.6 : 1)
    }

    // MARK: - Archive Button (checkbox)

    private var archiveButton: some View {
        Button { triggerArchive() } label: {
            ZStack {
                // Particle burst — starts at center, expands outward
                if showParticles {
                    ForEach(0..<6, id: \.self) { i in
                        let angle = (Double(i) / 6.0) * 2 * .pi
                        Circle()
                            .fill(Dash.Colors.success)
                            .frame(width: 4, height: 4)
                            .offset(
                                x: Foundation.cos(angle) * 16 * particleProgress,
                                y: Foundation.sin(angle) * 16 * particleProgress
                            )
                            .opacity(particleOpacity)
                    }
                }

                Circle()
                    .fill(isArchiving ? Dash.Colors.success : .clear)
                    .frame(width: 22, height: 22)
                    .overlay(
                        Circle().stroke(
                            isArchiving ? Dash.Colors.success
                                : isOverdue ? Dash.Colors.overdue.opacity(0.5)
                                : Dash.Colors.divider,
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
                    Circle().fill(Dash.Colors.overdueGlow).frame(width: 22, height: 22)
                    Circle().fill(Dash.Colors.overdue).frame(width: 6, height: 6)
                }
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var cardBackground: some View {
        let borderColor: Color = item.isPinned ? Dash.Colors.warning.opacity(0.3)
            : isOverdue ? Dash.Colors.overdue.opacity(0.3)
            : Dash.Colors.cardBorder

        let shadowColor: Color = item.isPinned ? Dash.Colors.warning.opacity(0.12)
            : isOverdue ? Dash.Colors.overdueGlow.opacity(0.2)
            : .black.opacity(0.08)

        RoundedRectangle(cornerRadius: Dash.Radius.md)
            .fill(Dash.Colors.cardBackground)
            .overlay(RoundedRectangle(cornerRadius: Dash.Radius.md).stroke(borderColor, lineWidth: 1))
            .shadow(color: shadowColor, radius: 8, y: 2)
    }

    // MARK: - Archive animation

    private func triggerArchive() {
        guard !isArchiving else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            isArchiving = true
        }

        // Particle burst: start at center (progress=0, opacity=1) → expand + fade
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
