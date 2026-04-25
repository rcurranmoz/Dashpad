import SwiftUI

// MARK: - Tag Filter Pill

struct TagFilterPill: View {
    let label: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    private var displayLabel: String {
        if label == "All" { return "All" }
        return TagPredictor.emoji(for: label)
    }

    var body: some View {
        Button(action: action) {
            Text(displayLabel)
                .font(Dash.Typography.caption)
                .foregroundStyle(isSelected ? .white : color)
                .padding(.horizontal, Dash.Spacing.md)
                .padding(.vertical, Dash.Spacing.sm)
                .background(
                    Capsule()
                        .fill(isSelected ? color : Dash.Colors.surface)
                        .overlay(Capsule().stroke(isSelected ? color : color.opacity(0.3), lineWidth: 1))
                )
                .shadow(color: isSelected ? color.opacity(0.4) : .clear, radius: 8, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tag Suggestion Chip

struct TagSuggestionChip: View {
    let tag: String
    let action: () -> Void

    private var tagColor: Color { Color(hex: TagPredictor.color(for: tag)) }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Dash.Spacing.xs) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 12))
                Text("\(TagPredictor.emoji(for: tag)) \(TagPredictor.friendlyName(for: tag))")
                    .font(Dash.Typography.caption)
            }
            .foregroundStyle(tagColor)
            .padding(.horizontal, Dash.Spacing.md)
            .padding(.vertical, Dash.Spacing.sm)
            .background(
                Capsule()
                    .fill(tagColor.opacity(0.15))
                    .overlay(Capsule().stroke(tagColor.opacity(0.3), lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Selected Tag Chip

struct SelectedTagChip: View {
    let tag: String
    let onRemove: () -> Void

    private var tagColor: Color { Color(hex: TagPredictor.color(for: tag)) }

    var body: some View {
        HStack(spacing: Dash.Spacing.xs) {
            Text("\(TagPredictor.emoji(for: tag)) \(TagPredictor.friendlyName(for: tag))")
                .font(Dash.Typography.caption)
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, Dash.Spacing.md)
        .padding(.vertical, Dash.Spacing.sm)
        .background(Capsule().fill(tagColor))
        .shadow(color: tagColor.opacity(0.4), radius: 4, y: 2)
    }
}

// MARK: - Inline Tag Dot (used in cards)

struct TagDot: View {
    let tag: String

    private var color: Color { Color(hex: TagPredictor.color(for: tag)) }

    var body: some View {
        Text(tag.capitalized)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Capsule().fill(color.opacity(0.15)))
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return CGSize(width: proposal.width ?? 0, height: result.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(
                at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y),
                proposal: .unspecified
            )
        }
    }

    struct FlowResult {
        var positions: [CGPoint] = []
        var height: CGFloat = 0

        init(in width: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > width && x > 0 {
                    x = 0; y += rowHeight + spacing; rowHeight = 0
                }
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }
            height = y + rowHeight
        }
    }
}
