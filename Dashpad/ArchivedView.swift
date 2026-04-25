import SwiftUI

struct ArchivedView: View {
    @Environment(DashStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var showClearConfirmation = false

    private var sortedArchived: [DashItem] {
        store.archivedItems.sorted {
            ($0.archivedAt ?? $0.createdAt) > ($1.archivedAt ?? $1.createdAt)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Dash.Colors.background.ignoresSafeArea()

                if store.archivedItems.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(sortedArchived) { item in
                            ArchivedItemRow(item: item) {
                                withAnimation { store.unarchive(item) }
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 0, leading: Dash.Spacing.xl, bottom: Dash.Spacing.md, trailing: Dash.Spacing.xl))
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    withAnimation { store.delete(item) }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Archive")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !store.archivedItems.isEmpty {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Clear All") { showClearConfirmation = true }
                            .foregroundStyle(Dash.Colors.overdue)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Dash.Colors.accent)
                        .fontWeight(.semibold)
                }
            }
            .toolbarBackground(Dash.Colors.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .alert("Clear all archived ideas?", isPresented: $showClearConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Clear All", role: .destructive) {
                    withAnimation { store.deleteAll(in: store.archivedItems) }
                }
            } message: {
                Text("This cannot be undone.")
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
    }

    private var emptyState: some View {
        VStack(spacing: Dash.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(Dash.Colors.cardBackground)
                    .frame(width: 64, height: 64)
                    .overlay(Circle().stroke(Dash.Colors.cardBorder, lineWidth: 1))
                Image(systemName: "archivebox")
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(Dash.Colors.textTertiary)
            }
            VStack(spacing: Dash.Spacing.xs) {
                Text("Nothing archived yet")
                    .font(Dash.Typography.body)
                    .foregroundStyle(Dash.Colors.textPrimary)
                Text("Swipe right on an idea to archive it.")
                    .font(Dash.Typography.caption)
                    .foregroundStyle(Dash.Colors.textTertiary)
            }
        }
    }
}

// MARK: - Archived Item Row

struct ArchivedItemRow: View {
    let item: DashItem
    let onRestore: () -> Void

    private var archivedLabel: String {
        guard let date = item.archivedAt else { return "" }
        let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        if days == 0 { return "today" }
        if days == 1 { return "yesterday" }
        return "\(days)d ago"
    }

    var body: some View {
        HStack(spacing: Dash.Spacing.md) {
            VStack(alignment: .leading, spacing: Dash.Spacing.xs) {
                Text(item.title)
                    .font(Dash.Typography.body)
                    .foregroundStyle(Dash.Colors.textSecondary)
                    .strikethrough(true, color: Dash.Colors.textTertiary)
                    .lineLimit(2)

                if !archivedLabel.isEmpty {
                    Text("Archived \(archivedLabel)")
                        .font(Dash.Typography.caption)
                        .foregroundStyle(Dash.Colors.textTertiary)
                }
            }

            Spacer()

            Button(action: onRestore) {
                Text("Restore")
                    .font(Dash.Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Dash.Colors.accent)
                    .padding(.horizontal, Dash.Spacing.md)
                    .padding(.vertical, Dash.Spacing.sm)
                    .background(Capsule().stroke(Dash.Colors.accent.opacity(0.4), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(Dash.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Dash.Radius.md)
                .fill(Dash.Colors.cardBackground)
                .overlay(RoundedRectangle(cornerRadius: Dash.Radius.md).stroke(Dash.Colors.cardBorder, lineWidth: 1))
        )
    }
}
