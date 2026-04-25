import SwiftUI

struct IdeaGroup: Identifiable, Equatable {
    let tag: String
    var id: String { tag }

    var emoji: String { TagPredictor.emoji(for: tag) }
    var name: String { TagPredictor.friendlyName(for: tag) }
    var color: Color { Color(hex: TagPredictor.color(for: tag)) }
}

// MARK: - Group Card

struct GroupCard: View {
    let group: IdeaGroup
    let items: [DashItem]
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            headerBand
                .clipShape(RoundedRectangle(cornerRadius: Dash.Radius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: Dash.Radius.md)
                        .stroke(group.color.opacity(0.25), lineWidth: 1)
                )
                .shadow(color: group.color.opacity(0.15), radius: 14, y: 4)
        }
        .buttonStyle(.plain)
    }

    private var headerBand: some View {
        HStack(spacing: Dash.Spacing.sm) {
            Text(group.emoji)
                .font(.system(size: 20))

            Spacer()

            Text("\(items.count)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, Dash.Spacing.sm)
                .padding(.vertical, 3)
                .background(Capsule().fill(.white.opacity(0.2)))

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.horizontal, Dash.Spacing.lg)
        .padding(.vertical, Dash.Spacing.md)
        .background(
            LinearGradient(
                colors: [group.color, group.color.opacity(0.7)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }

}

// MARK: - Group View

struct GroupView: View {
    let group: IdeaGroup
    @Environment(DashStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var editingItem: DashItem? = nil

    private var items: [DashItem] {
        store.activeItems
            .filter { $0.tags.contains(group.tag) }
            .sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Dash.Colors.background.ignoresSafeArea()

                List {
                    ForEach(items) { item in
                        IdeaCard(
                            item: item,
                            onArchive: {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                    store.archive(item)
                                }
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            },
                            onEdit: { editingItem = item }
                        )
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 0, leading: Dash.Spacing.xl, bottom: Dash.Spacing.md, trailing: Dash.Spacing.xl))
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                withAnimation { store.delete(item) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            Button { editingItem = item } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(Dash.Colors.accent)
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                    store.archive(item)
                                }
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            } label: {
                                Label("Archive", systemImage: "archivebox")
                            }
                            .tint(Dash.Colors.success)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .contentMargins(.bottom, 40, for: .scrollContent)
                .overlay {
                    if items.isEmpty { emptyView }
                }
            }
            .navigationTitle("\(group.emoji) \(group.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Dash.Colors.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(Dash.Typography.caption.weight(.semibold))
                        .foregroundStyle(Dash.Colors.accent)
                }
            }
        }
        .sheet(item: $editingItem) { item in
            EditIdeaView(item: item, allTags: Array(Set(store.activeItems.flatMap { $0.tags })).sorted())
        }
        .onChange(of: items.count) { _, count in
            if count == 0 { dismiss() }
        }
        .preferredColorScheme(.dark)
    }

    private var emptyView: some View {
        VStack(spacing: Dash.Spacing.lg) {
            Text(group.emoji).font(.system(size: 48))
            Text("All clear!")
                .font(Dash.Typography.body)
                .foregroundStyle(Dash.Colors.textPrimary)
            Text("Nothing left in \(group.name)")
                .font(Dash.Typography.caption)
                .foregroundStyle(Dash.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
