import SwiftUI

struct BackburnerView: View {
    let items: [DashItem]
    let onRevive: (DashItem) -> Void
    let onLetGo: (DashItem) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Dash.Colors.background.ignoresSafeArea()

                if items.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: Dash.Spacing.md) {
                            Text("Ideas sitting here for 4+ weeks.\nStill relevant?")
                                .font(Dash.Typography.body)
                                .foregroundStyle(Dash.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.bottom, Dash.Spacing.md)

                            ForEach(items) { item in
                                BackburnerItemCard(
                                    item: item,
                                    onRevive: { onRevive(item) },
                                    onLetGo: { onLetGo(item) }
                                )
                            }
                        }
                        .padding(Dash.Spacing.xl)
                    }
                }
            }
            .navigationTitle("Backburner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Dash.Colors.accent)
                        .fontWeight(.semibold)
                }
            }
            .toolbarBackground(Dash.Colors.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
    }

    private var emptyState: some View {
        VStack(spacing: Dash.Spacing.xl) {
            Text("🔥")
                .font(.system(size: 56))

            VStack(spacing: Dash.Spacing.sm) {
                Text("The Backburner")
                    .font(Dash.Typography.title)
                    .foregroundStyle(Dash.Colors.textPrimary)

                Text("Ideas sitting for 4+ weeks\nlive here, out of the way.")
                    .font(Dash.Typography.body)
                    .foregroundStyle(Dash.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: Dash.Spacing.md) {
                featureRow("✨", "Out of sight, out of mind")
                featureRow("💡", "Revive when inspiration strikes")
                featureRow("👋", "Or let them go, guilt-free")
            }
        }
        .padding(Dash.Spacing.xl)
    }

    private func featureRow(_ emoji: String, _ text: String) -> some View {
        HStack(spacing: Dash.Spacing.md) {
            Text(emoji)
            Text(text)
                .font(Dash.Typography.caption)
                .foregroundStyle(Dash.Colors.textSecondary)
            Spacer()
        }
    }
}

// MARK: - Backburner Item Card

struct BackburnerItemCard: View {
    let item: DashItem
    let onRevive: () -> Void
    let onLetGo: () -> Void

    private var daysOld: Int {
        Calendar.current.dateComponents([.day], from: item.createdAt, to: Date()).day ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Dash.Spacing.md) {
            Text(item.title)
                .font(Dash.Typography.body)
                .foregroundStyle(Dash.Colors.textPrimary)
                .lineLimit(2)

            if let bodyText = item.body, !bodyText.isEmpty {
                Text(bodyText)
                    .font(Dash.Typography.caption)
                    .foregroundStyle(Dash.Colors.textTertiary)
                    .lineLimit(2)
            }

            HStack {
                Text("\(daysOld) days ago")
                    .font(Dash.Typography.caption)
                    .foregroundStyle(Dash.Colors.textTertiary)

                Spacer()

                HStack(spacing: Dash.Spacing.sm) {
                    Button(action: onRevive) {
                        Text("Revive")
                            .font(Dash.Typography.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, Dash.Spacing.md)
                            .padding(.vertical, Dash.Spacing.sm)
                            .background(Capsule().fill(Dash.Colors.accent))
                    }
                    .buttonStyle(.plain)

                    Button(action: onLetGo) {
                        Text("Let go")
                            .font(Dash.Typography.caption)
                            .foregroundStyle(Dash.Colors.textSecondary)
                            .padding(.horizontal, Dash.Spacing.md)
                            .padding(.vertical, Dash.Spacing.sm)
                            .background(Capsule().stroke(Dash.Colors.cardBorder, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(Dash.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Dash.Radius.md)
                .fill(Dash.Colors.warning.opacity(0.08))
                .overlay(RoundedRectangle(cornerRadius: Dash.Radius.md).stroke(Dash.Colors.warning.opacity(0.2), lineWidth: 1))
        )
    }
}
