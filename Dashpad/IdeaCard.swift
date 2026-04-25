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
        return due < Date()
    }

    private var stripColor: Color {
        if item.isPinned { return Dash.Colors.warning }
        if isOverdue { return Dash.Colors.danger }
        if let tag = item.tags.first { return Color(hex: TagPredictor.color(for: tag)) }
        return .clear
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
            HStack(spacing: 0) {
                // Left tag-color accent strip
                Rectangle()
                    .fill(stripColor)
                    .frame(width: 3)

                HStack(spacing: Dash.Spacing.md) {
                    archiveButton
                        .padding(.leading, Dash.Spacing.lg)

                    VStack(alignment: .leading, spacing: 5) {
                        HStack(alignment: .top, spacing: Dash.Spacing.sm) {
                            Text(item.title)
                                .font(Dash.Typography.body)
                                .foregroundStyle(isArchiving ? Dash.Colors.textTertiary : Dash.Colors.textPrimary)
                                .strikethrough(isArchiving, color: Dash.Colors.textTertiary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            if let label = miniTimeLabel {
                                Text(label)
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .foregroundStyle(miniTimeLabelColor)
                                    .opacity(isArchiving ? 0.4 : 1)
                            }
                        }

                        if let bodyText = item.body, !bodyText.isEmpty {
                            Text(bodyText)
                                .font(.system(size: 13, weight: .regular))
                                .foregroundStyle(Dash.Colors.textTertiary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }

                        if !item.tags.isEmpty {
                            HStack(spacing: 5) {
                                ForEach(item.tags.prefix(3), id: \.self) { tag in
                                    HStack(spacing: 3) {
                                        Text(TagPredictor.emoji(for: tag))
                                            .font(.system(size: 10))
                                        Text(TagPredictor.friendlyName(for: tag))
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundStyle(Color(hex: TagPredictor.color(for: tag)))
                                    }
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule()
                                            .fill(Color(hex: TagPredictor.color(for: tag)).opacity(0.12))
                                    )
                                }
                                if item.tags.count > 3 {
                                    Text("+\(item.tags.count - 3)")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundStyle(Dash.Colors.textTertiary)
                                }
                            }
                        }
                    }
                    .padding(.vertical, Dash.Spacing.lg)
                    .padding(.trailing, Dash.Spacing.lg)
                }
            }
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Dash.Radius.md))
            .opacity(isArchiving ? 0.5 : 1)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Archive Button

    private var archiveButton: some View {
        Button { triggerArchive() } label: {
            ZStack {
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
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle().stroke(
                            isArchiving ? Dash.Colors.success
                                : isOverdue ? Dash.Colors.danger.opacity(0.6)
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
                    Circle().fill(Dash.Colors.dangerDim).frame(width: 24, height: 24)
                    Circle().fill(Dash.Colors.danger).frame(width: 6, height: 6)
                }
            }
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var cardBackground: some View {
        ZStack {
            Dash.Colors.surface

            if item.isPinned {
                LinearGradient(
                    colors: [Dash.Colors.warning.opacity(0.06), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: Dash.Radius.md)
                .stroke(
                    item.isPinned ? Dash.Colors.warning.opacity(0.25)
                        : isOverdue ? Dash.Colors.danger.opacity(0.3)
                        : Dash.Colors.border,
                    lineWidth: 1
                )
        )
        .shadow(
            color: item.isPinned ? Dash.Colors.warning.opacity(0.1)
                : isOverdue ? Dash.Colors.dangerDim.opacity(0.3)
                : .black.opacity(0.25),
            radius: 10, y: 4
        )
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
