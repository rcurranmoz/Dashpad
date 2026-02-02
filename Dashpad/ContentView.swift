import SwiftUI
import SwiftData

// MARK: - Design System

enum Dash {
    enum Colors {
        // Richer, warmer dark palette
        static let background = Color(hex: "09090B")
        static let backgroundGradientTop = Color(hex: "13121A")
        static let backgroundGradientBottom = Color(hex: "09090B")
        
        static let cardBackground = Color(hex: "18181B")
        static let cardBackgroundElevated = Color(hex: "1F1F23")
        static let cardBorder = Color(hex: "27272A")
        
        // Vibrant accent palette
        static let accent = Color(hex: "8B5CF6") // Purple
        static let accentLight = Color(hex: "A78BFA")
        static let accentGlow = Color(hex: "8B5CF6").opacity(0.4)
        static let accentGradientStart = Color(hex: "8B5CF6")
        static let accentGradientEnd = Color(hex: "6366F1")
        
        static let success = Color(hex: "34D399")
        static let successLight = Color(hex: "6EE7B7")
        static let successGlow = Color(hex: "34D399").opacity(0.4)
        
        static let warning = Color(hex: "FBBF24")
        static let warningGlow = Color(hex: "FBBF24").opacity(0.3)
        
        static let overdue = Color(hex: "F87171")
        static let overdueLight = Color(hex: "FCA5A5")
        static let overdueGlow = Color(hex: "F87171").opacity(0.3)
        
        static let textPrimary = Color(hex: "FAFAFA")
        static let textSecondary = Color(hex: "A1A1AA")
        static let textTertiary = Color(hex: "52525B")
        
        static let divider = Color(hex: "3F3F46")
        
        // Tag colors
        static func tagColor(_ hex: String) -> Color {
            Color(hex: hex)
        }
    }
    
    enum Typography {
        static let largeTitle = Font.system(size: 32, weight: .semibold, design: .default)
        static let title = Font.system(size: 22, weight: .semibold, design: .default)
        static let title2 = Font.system(size: 18, weight: .medium, design: .default)
        static let headline = Font.system(size: 17, weight: .semibold, design: .default)
        static let body = Font.system(size: 16, weight: .regular, design: .default)
        static let caption = Font.system(size: 13, weight: .medium, design: .default)
        static let micro = Font.system(size: 11, weight: .semibold, design: .default)
    }
    
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 28
    }
    
    enum Radius {
        static let sm: CGFloat = 10
        static let md: CGFloat = 14
        static let lg: CGFloat = 18
        static let xl: CGFloat = 24
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Main View

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DashItem.createdAt, order: .reverse) private var items: [DashItem]
    
    @State private var newItemTitle = ""
    @State private var newItemTags: [String] = []
    @State private var isInputActive = false
    @State private var selectedTagFilter: String? = nil
    @State private var editingItem: DashItem? = nil
    @State private var showBackburner = false
    @FocusState private var isInputFocused: Bool
    
    // 14 days ago
    private var backburnerThreshold: Date {
        Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
    }
    
    // Items sitting for 14+ days (not complete)
    var backburnerItems: [DashItem] {
        items.filter { item in
            !item.isComplete && item.createdAt < backburnerThreshold
        }
    }
    
    // Active items (incomplete and not on backburner)
    var activeItems: [DashItem] {
        items.filter { item in
            !item.isComplete && item.createdAt >= backburnerThreshold
        }
    }
    
    // All unique tags from active incomplete items only
    var allTags: [String] {
        let incompleteTags = activeItems.flatMap { $0.tags }
        return Array(Set(incompleteTags)).sorted()
    }
    
    var incompleteItems: [DashItem] {
        var filtered = activeItems
        if let tag = selectedTagFilter {
            filtered = filtered.filter { $0.tags.contains(tag) }
        }
        return filtered
    }
    
    var overdueItems: [DashItem] {
        incompleteItems.filter { item in
            guard let due = item.dueDate else { return false }
            return due < Date()
        }
    }
    
    var upcomingItems: [DashItem] {
        incompleteItems.filter { item in
            guard let due = item.dueDate else { return true }
            return due >= Date()
        }
    }
    
    // Suggested tags based on input
    var suggestedTags: [String] {
        guard !newItemTitle.isEmpty else { return [] }
        return TagPredictor.suggestTags(for: newItemTitle, existingUserTags: allTags)
            .filter { !newItemTags.contains($0) }
    }
    
    var body: some View {
        ZStack {
            // Rich gradient background
            backgroundView
            
            VStack(spacing: 0) {
                // Header
                header
                    .padding(.horizontal, Dash.Spacing.xl)
                    .padding(.top, Dash.Spacing.md)
                    .padding(.bottom, Dash.Spacing.sm)
                
                // Tag filter bar
                if !allTags.isEmpty {
                    tagFilterBar
                        .padding(.bottom, Dash.Spacing.md)
                }
                
                // Content
                contentList
                
                Spacer(minLength: 0)
            }
            
            // Input bar
            VStack {
                Spacer()
                inputBar
            }
        }
        .preferredColorScheme(.dark)
        .sheet(item: $editingItem) { item in
            EditItemView(item: item, allTags: allTags)
        }
        .sheet(isPresented: $showBackburner) {
            BackburnerView(items: backburnerItems, onRevive: reviveItem, onLetGo: deleteItem)
        }
        .onChange(of: allTags) { _, newTags in
            // Clear filter if selected tag no longer exists
            if let selected = selectedTagFilter, !newTags.contains(selected) {
                selectedTagFilter = nil
            }
        }
    }
    
    private func reviveItem(_ item: DashItem) {
        // Reset createdAt to now, bringing it back to active list
        item.createdAt = Date()
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
    
    private func deleteItem(_ item: DashItem) {
        modelContext.delete(item)
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
    
    // MARK: - Content List
    
    private var contentList: some View {
        ScrollView {
            LazyVStack(spacing: Dash.Spacing.md) {
                // Overdue section
                overdueSection
                
                // Main list
                upcomingSection
            }
            .padding(.horizontal, Dash.Spacing.xl)
            .padding(.bottom, 140)
        }
        .overlay {
            // Empty state - centered on screen
            if incompleteItems.isEmpty {
                emptyState
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .offset(y: -40) // Slightly above center to account for input bar
            }
        }
    }
    
    // MARK: - Overdue Section
    
    private var overdueSection: some View {
        Group {
            if !overdueItems.isEmpty {
                sectionHeader("Overdue", count: overdueItems.count, style: .overdue)
                
                ForEach(overdueItems) { item in
                    DashItemCard(item: item, style: .overdue, onComplete: {
                        completeItem(item)
                    }, onEdit: {
                        editingItem = item
                    })
                }
                .padding(.bottom, Dash.Spacing.sm)
            }
        }
    }
    
    // MARK: - Upcoming Section
    
    private var upcomingSection: some View {
        Group {
            if !upcomingItems.isEmpty {
                if !overdueItems.isEmpty {
                    sectionHeader("Upcoming", count: upcomingItems.count, style: .normal)
                }
                
                ForEach(upcomingItems) { item in
                    DashItemCard(item: item, style: .normal, onComplete: {
                        completeItem(item)
                    }, onEdit: {
                        editingItem = item
                    })
                }
            }
        }
    }
    
    // MARK: - Background
    
    private var backgroundView: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [Dash.Colors.backgroundGradientTop, Dash.Colors.backgroundGradientBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Ambient glow orbs
            GeometryReader { geo in
                Circle()
                    .fill(Dash.Colors.accent.opacity(0.08))
                    .frame(width: 300, height: 300)
                    .blur(radius: 80)
                    .offset(x: -100, y: -50)
                
                Circle()
                    .fill(Dash.Colors.success.opacity(0.05))
                    .frame(width: 250, height: 250)
                    .blur(radius: 70)
                    .offset(x: geo.size.width - 100, y: geo.size.height * 0.4)
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: Dash.Spacing.xs) {
                Text("Dashpad")
                    .font(Dash.Typography.largeTitle)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Dash.Colors.textPrimary, Dash.Colors.textPrimary.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text(formattedDate)
                    .font(Dash.Typography.caption)
                    .foregroundStyle(Dash.Colors.textSecondary)
            }
            
            Spacer()
            
            // Backburner indicator - always visible
            Button {
                showBackburner = true
            } label: {
                ZStack {
                    Circle()
                        .fill(Dash.Colors.cardBackground)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle()
                                .stroke(Dash.Colors.cardBorder, lineWidth: 1)
                        )
                    
                    Text("🔥")
                        .font(.system(size: 18))
                    
                    // Amber dot indicator - only show if there are backburner items
                    if !backburnerItems.isEmpty {
                        Circle()
                            .fill(Color(hex: "F59E0B"))
                            .frame(width: 10, height: 10)
                            .overlay(
                                Circle()
                                    .stroke(Dash.Colors.background, lineWidth: 2)
                            )
                            .offset(x: 12, y: -12)
                    }
                }
            }
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: Date())
    }
    
    // MARK: - Tag Filter Bar
    
    private var tagFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Dash.Spacing.sm) {
                // "All" pill
                TagFilterPill(
                    label: "All",
                    color: Dash.Colors.accent,
                    isSelected: selectedTagFilter == nil
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedTagFilter = nil
                    }
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                }
                
                // Tag pills
                ForEach(allTags, id: \.self) { tag in
                    let tagColor = Color(hex: TagPredictor.color(for: tag))
                    
                    TagFilterPill(
                        label: tag,
                        color: tagColor,
                        isSelected: selectedTagFilter == tag
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            if selectedTagFilter == tag {
                                selectedTagFilter = nil
                            } else {
                                selectedTagFilter = tag
                            }
                        }
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                    }
                }
            }
            .padding(.horizontal, Dash.Spacing.xl)
        }
    }
    
    // MARK: - Stats Card
    
    private var statsCard: some View {
        HStack(spacing: Dash.Spacing.lg) {
            StatItem(
                value: "\(incompleteItems.count)",
                label: "Total",
                color: Dash.Colors.accent
            )
            
            Divider()
                .frame(height: 32)
                .background(Dash.Colors.divider)
            
            StatItem(
                value: "\(overdueItems.count)",
                label: "Overdue",
                color: overdueItems.isEmpty ? Dash.Colors.textTertiary : Dash.Colors.overdue
            )
            
            Divider()
                .frame(height: 32)
                .background(Dash.Colors.divider)
            
            StatItem(
                value: "\(items.filter { $0.isComplete }.count)",
                label: "Done",
                color: Dash.Colors.success
            )
        }
        .padding(.horizontal, Dash.Spacing.xl)
        .padding(.vertical, Dash.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Dash.Radius.lg)
                .fill(Dash.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: Dash.Radius.lg)
                        .stroke(Dash.Colors.cardBorder, lineWidth: 1)
                )
        )
    }
    
    // MARK: - Section Header
    
    enum SectionStyle {
        case normal, overdue
    }
    
    private func sectionHeader(_ title: String, count: Int, style: SectionStyle) -> some View {
        HStack(spacing: Dash.Spacing.sm) {
            // Icon
            Circle()
                .fill(style == .overdue ? Dash.Colors.overdueGlow : Dash.Colors.accent.opacity(0.2))
                .frame(width: 8, height: 8)
            
            Text(title)
                .font(Dash.Typography.caption)
                .foregroundStyle(style == .overdue ? Dash.Colors.overdue : Dash.Colors.textSecondary)
                .textCase(.uppercase)
                .tracking(1)
            
            Capsule()
                .fill(style == .overdue ? Dash.Colors.overdueGlow : Dash.Colors.accent.opacity(0.15))
                .frame(width: 24, height: 20)
                .overlay(
                    Text("\(count)")
                        .font(Dash.Typography.micro)
                        .foregroundStyle(style == .overdue ? Dash.Colors.overdue : Dash.Colors.accent)
                )
            
            Spacer()
        }
        .padding(.top, Dash.Spacing.md)
        .padding(.bottom, Dash.Spacing.xs)
    }
    
    // MARK: - Empty State
    
    private var emptyStateMessages: [(title: String, subtitle: String)] {
        [
            ("Nothing here", "Nice work."),
            ("Clean slate", "Enjoy it."),
            ("You handled it", "All done."),
            ("All clear", "Go live your life."),
            ("Empty", "As it should be."),
            ("Inbox zero energy", "You earned this."),
            ("Look at you go", "Everything's done."),
            ("Blank canvas", "Until next time.")
        ]
    }
    
    private var currentEmptyMessage: (title: String, subtitle: String) {
        // Use the hour to rotate messages throughout the day
        let hour = Calendar.current.component(.hour, from: Date())
        let index = hour % emptyStateMessages.count
        return emptyStateMessages[index]
    }
    
    private var emptyState: some View {
        VStack(spacing: Dash.Spacing.lg) {
            // Subtle icon - just a soft circle with dash
            ZStack {
                Circle()
                    .fill(Dash.Colors.cardBackground)
                    .frame(width: 64, height: 64)
                    .overlay(
                        Circle()
                            .stroke(Dash.Colors.cardBorder, lineWidth: 1)
                    )
                
                // Simple dash mark
                RoundedRectangle(cornerRadius: 2)
                    .fill(Dash.Colors.textTertiary)
                    .frame(width: 20, height: 4)
            }
            
            VStack(spacing: Dash.Spacing.xs) {
                if selectedTagFilter != nil {
                    Text("No items with this tag")
                        .font(Dash.Typography.body)
                        .foregroundStyle(Dash.Colors.textSecondary)
                } else {
                    Text(currentEmptyMessage.title)
                        .font(Dash.Typography.body)
                        .foregroundStyle(Dash.Colors.textPrimary)
                    
                    Text(currentEmptyMessage.subtitle)
                        .font(Dash.Typography.caption)
                        .foregroundStyle(Dash.Colors.textTertiary)
                }
            }
        }
    }
    
    // MARK: - Input Bar
    
    private var inputBar: some View {
        VStack(spacing: 0) {
            // Gradient fade
            LinearGradient(
                colors: [Dash.Colors.background.opacity(0), Dash.Colors.background],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 30)
            
            VStack(spacing: Dash.Spacing.sm) {
                // Tag suggestions
                if isInputActive && !suggestedTags.isEmpty {
                    tagSuggestionsBar
                }
                
                // Selected tags for new item
                if !newItemTags.isEmpty {
                    selectedTagsBar
                }
                
                // Main input row
                HStack(spacing: Dash.Spacing.md) {
                    // Text field with icon
                    HStack(spacing: Dash.Spacing.md) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(isInputActive ? Dash.Colors.accent : Dash.Colors.textTertiary)
                        
                        TextField("", text: $newItemTitle, prompt: Text("What do you need to remember?").foregroundStyle(Dash.Colors.textTertiary))
                            .font(Dash.Typography.body)
                            .foregroundStyle(Dash.Colors.textPrimary)
                            .focused($isInputFocused)
                            .onSubmit { addItem() }
                            .onChange(of: isInputFocused) { _, focused in
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    isInputActive = focused
                                }
                            }
                    }
                    .padding(.horizontal, Dash.Spacing.lg)
                    .padding(.vertical, Dash.Spacing.md + 2)
                    .background(
                        RoundedRectangle(cornerRadius: Dash.Radius.xl)
                            .fill(Dash.Colors.cardBackgroundElevated)
                            .overlay(
                                RoundedRectangle(cornerRadius: Dash.Radius.xl)
                                    .stroke(
                                        isInputActive
                                            ? LinearGradient(colors: [Dash.Colors.accent.opacity(0.6), Dash.Colors.accent.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                            : LinearGradient(colors: [Dash.Colors.cardBorder, Dash.Colors.cardBorder], startPoint: .top, endPoint: .bottom),
                                        lineWidth: 1
                                    )
                            )
                            .shadow(color: isInputActive ? Dash.Colors.accentGlow.opacity(0.5) : .clear, radius: 16, y: 4)
                    )
                    
                    // Send button - only show when there's text
                    if !newItemTitle.trimmingCharacters(in: .whitespaces).isEmpty {
                        Button {
                            addItem()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Dash.Colors.accentGradientStart, Dash.Colors.accentGradientEnd],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 48, height: 48)
                                    .shadow(color: Dash.Colors.accentGlow, radius: 12, y: 4)
                                
                                Image(systemName: "arrow.up")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: newItemTitle.isEmpty)
            }
            .padding(.horizontal, Dash.Spacing.xl)
            .padding(.bottom, Dash.Spacing.xxl)
            .background(Dash.Colors.background)
        }
    }
    
    // MARK: - Tag Suggestions Bar
    
    private var tagSuggestionsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Dash.Spacing.sm) {
                Text("Suggest:")
                    .font(Dash.Typography.micro)
                    .foregroundStyle(Dash.Colors.textTertiary)
                
                ForEach(suggestedTags, id: \.self) { tag in
                    TagSuggestionChip(tag: tag) {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            newItemTags.append(tag)
                        }
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                    }
                }
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    // MARK: - Selected Tags Bar
    
    private var selectedTagsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Dash.Spacing.sm) {
                ForEach(newItemTags, id: \.self) { tag in
                    SelectedTagChip(tag: tag) {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            newItemTags.removeAll { $0 == tag }
                        }
                    }
                }
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    // MARK: - Actions
    
    private func addItem() {
        let trimmed = newItemTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            let item = DashItem(title: trimmed, tags: newItemTags)
            modelContext.insert(item)
            newItemTitle = ""
            newItemTags = []
        }
        
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
    
    private func completeItem(_ item: DashItem) {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            item.complete()
        }
    }
}

// MARK: - Tag Filter Pill

struct TagFilterPill: View {
    let label: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label.capitalized)
                .font(Dash.Typography.caption)
                .foregroundStyle(isSelected ? .white : color)
                .padding(.horizontal, Dash.Spacing.md)
                .padding(.vertical, Dash.Spacing.sm)
                .background(
                    Capsule()
                        .fill(isSelected ? color : Dash.Colors.cardBackground)
                        .overlay(
                            Capsule()
                                .stroke(isSelected ? color : color.opacity(0.3), lineWidth: 1)
                        )
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
    
    var tagColor: Color {
        Color(hex: TagPredictor.color(for: tag))
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Dash.Spacing.xs) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 12))
                
                Text(tag.capitalized)
                    .font(Dash.Typography.caption)
            }
            .foregroundStyle(tagColor)
            .padding(.horizontal, Dash.Spacing.md)
            .padding(.vertical, Dash.Spacing.sm)
            .background(
                Capsule()
                    .fill(tagColor.opacity(0.15))
                    .overlay(
                        Capsule()
                            .stroke(tagColor.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Selected Tag Chip

struct SelectedTagChip: View {
    let tag: String
    let onRemove: () -> Void
    
    var tagColor: Color {
        Color(hex: TagPredictor.color(for: tag))
    }
    
    var body: some View {
        HStack(spacing: Dash.Spacing.xs) {
            Text(tag.capitalized)
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
        .background(
            Capsule()
                .fill(tagColor)
        )
        .shadow(color: tagColor.opacity(0.4), radius: 4, y: 2)
    }
}

// MARK: - Stat Item

struct StatItem: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: Dash.Spacing.xs) {
            Text(value)
                .font(Dash.Typography.title)
                .foregroundStyle(color)
            
            Text(label)
                .font(Dash.Typography.micro)
                .foregroundStyle(Dash.Colors.textTertiary)
                .textCase(.uppercase)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Item Card

struct DashItemCard: View {
    let item: DashItem
    let style: ContentView.SectionStyle
    let onComplete: () -> Void
    let onEdit: () -> Void
    
    @State private var isCompleting = false
    @State private var showParticles = false
    
    private var isOverdue: Bool { style == .overdue }
    
    var body: some View {
        HStack(spacing: Dash.Spacing.md) {
            // Tappable checkbox with celebration
            Button {
                triggerCompletion()
            } label: {
                ZStack {
                    // Particle burst
                    if showParticles {
                        ForEach(0..<6, id: \.self) { index in
                            Circle()
                                .fill(Dash.Colors.success)
                                .frame(width: 4, height: 4)
                                .offset(particleOffset(for: index))
                                .opacity(showParticles ? 0 : 1)
                                .animation(
                                    .easeOut(duration: 0.4)
                                    .delay(Double(index) * 0.02),
                                    value: showParticles
                                )
                        }
                    }
                    
                    // Outer ring / fill
                    Circle()
                        .fill(isCompleting ? Dash.Colors.success : Color.clear)
                        .frame(width: 20, height: 20)
                        .overlay(
                            Circle()
                                .stroke(
                                    isCompleting
                                        ? Dash.Colors.success
                                        : (isOverdue ? Dash.Colors.overdue.opacity(0.5) : Dash.Colors.divider),
                                    lineWidth: 1.5
                                )
                        )
                        .scaleEffect(isCompleting ? 1.15 : 1.0)
                    
                    // Checkmark (shows on completion)
                    if isCompleting {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                    // Inner fill for overdue (when not completing)
                    if isOverdue && !isCompleting {
                        Circle()
                            .fill(Dash.Colors.overdueGlow)
                            .frame(width: 20, height: 20)
                        
                        Circle()
                            .fill(Dash.Colors.overdue)
                            .frame(width: 6, height: 6)
                    }
                }
            }
            .buttonStyle(.plain)
            
            // Content - tappable for edit
            Button {
                onEdit()
            } label: {
                VStack(alignment: .leading, spacing: Dash.Spacing.xs) {
                    Text(item.title)
                        .font(Dash.Typography.body)
                        .foregroundStyle(isCompleting ? Dash.Colors.textTertiary : Dash.Colors.textPrimary)
                        .strikethrough(isCompleting, color: Dash.Colors.textTertiary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    if let dueDate = item.dueDate {
                        HStack(spacing: Dash.Spacing.xs) {
                            Image(systemName: isOverdue ? "exclamationmark.triangle.fill" : "calendar")
                                .font(.system(size: 11, weight: .semibold))
                            
                            Text(formatDate(dueDate))
                                .font(Dash.Typography.caption)
                        }
                        .foregroundStyle(isOverdue ? Dash.Colors.overdue : Dash.Colors.textSecondary)
                        .padding(.horizontal, Dash.Spacing.sm)
                        .padding(.vertical, Dash.Spacing.xs)
                        .background(
                            Capsule()
                                .fill(isOverdue ? Dash.Colors.overdueGlow : Dash.Colors.accent.opacity(0.1))
                        )
                        .opacity(isCompleting ? 0.5 : 1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .disabled(isCompleting)
        }
        .padding(Dash.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Dash.Radius.md)
                .fill(Dash.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: Dash.Radius.md)
                        .stroke(
                            isOverdue ? Dash.Colors.overdue.opacity(0.3) : Dash.Colors.cardBorder,
                            lineWidth: 1
                        )
                )
                .shadow(color: isOverdue ? Dash.Colors.overdueGlow.opacity(0.3) : .black.opacity(0.1), radius: 8, y: 2)
        )
        .opacity(isCompleting ? 0.7 : 1)
    }
    
    private func triggerCompletion() {
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        // Start animation
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            isCompleting = true
            showParticles = true
        }
        
        // Success haptic after a beat
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.success)
        }
        
        // Actually complete the item after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            onComplete()
        }
    }
    
    private func particleOffset(for index: Int) -> CGSize {
        let angle = (Double(index) / 6.0) * 2 * Double.pi
        let distance: Double = showParticles ? 18 : 0
        return CGSize(
            width: Foundation.cos(angle) * distance,
            height: Foundation.sin(angle) * distance
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "Today, " + date.formatted(date: .omitted, time: .shortened)
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow, " + date.formatted(date: .omitted, time: .shortened)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            return date.formatted(.dateTime.month(.abbreviated).day())
        }
    }
}

// MARK: - Item Tag Badge

struct ItemTagBadge: View {
    let tag: String
    
    var tagColor: Color {
        Color(hex: TagPredictor.color(for: tag))
    }
    
    var body: some View {
        Text(tag.capitalized)
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundStyle(tagColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(tagColor.opacity(0.15))
            )
    }
}

// MARK: - Edit Item View

struct EditItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var item: DashItem
    let allTags: [String]
    
    @State private var title: String = ""
    @State private var tags: [String] = []
    @State private var showDeleteConfirmation = false
    @FocusState private var isTitleFocused: Bool
    
    var suggestedTags: [String] {
        guard !title.isEmpty else { return [] }
        return TagPredictor.suggestTags(for: title, existingUserTags: allTags)
            .filter { !tags.contains($0) }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Dash.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Dash.Spacing.xl) {
                        // Title field
                        VStack(alignment: .leading, spacing: Dash.Spacing.sm) {
                            Text("REMINDER")
                                .font(Dash.Typography.micro)
                                .foregroundStyle(Dash.Colors.textTertiary)
                                .tracking(1)
                            
                            TextField("What do you need to remember?", text: $title, axis: .vertical)
                                .font(Dash.Typography.body)
                                .foregroundStyle(Dash.Colors.textPrimary)
                                .focused($isTitleFocused)
                                .lineLimit(1...5)
                                .padding(Dash.Spacing.lg)
                                .background(
                                    RoundedRectangle(cornerRadius: Dash.Radius.md)
                                        .fill(Dash.Colors.cardBackground)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: Dash.Radius.md)
                                                .stroke(Dash.Colors.cardBorder, lineWidth: 1)
                                        )
                                )
                        }
                        
                        // Tags section
                        VStack(alignment: .leading, spacing: Dash.Spacing.sm) {
                            Text("TAGS")
                                .font(Dash.Typography.micro)
                                .foregroundStyle(Dash.Colors.textTertiary)
                                .tracking(1)
                            
                            // Current tags
                            if !tags.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: Dash.Spacing.sm) {
                                        ForEach(tags, id: \.self) { tag in
                                            SelectedTagChip(tag: tag) {
                                                withAnimation {
                                                    tags.removeAll { $0 == tag }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // Suggested tags
                            if !suggestedTags.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: Dash.Spacing.sm) {
                                        ForEach(suggestedTags, id: \.self) { tag in
                                            TagSuggestionChip(tag: tag) {
                                                withAnimation {
                                                    tags.append(tag)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // All available tags
                            if !allTags.isEmpty {
                                Text("All tags")
                                    .font(Dash.Typography.caption)
                                    .foregroundStyle(Dash.Colors.textTertiary)
                                    .padding(.top, Dash.Spacing.sm)
                                
                                FlowLayout(spacing: Dash.Spacing.sm) {
                                    ForEach(allTags, id: \.self) { tag in
                                        let isSelected = tags.contains(tag)
                                        Button {
                                            withAnimation {
                                                if isSelected {
                                                    tags.removeAll { $0 == tag }
                                                } else {
                                                    tags.append(tag)
                                                }
                                            }
                                        } label: {
                                            Text(tag.capitalized)
                                                .font(Dash.Typography.caption)
                                                .foregroundStyle(isSelected ? .white : Color(hex: TagPredictor.color(for: tag)))
                                                .padding(.horizontal, Dash.Spacing.md)
                                                .padding(.vertical, Dash.Spacing.sm)
                                                .background(
                                                    Capsule()
                                                        .fill(isSelected ? Color(hex: TagPredictor.color(for: tag)) : Dash.Colors.cardBackground)
                                                        .overlay(
                                                            Capsule()
                                                                .stroke(Color(hex: TagPredictor.color(for: tag)).opacity(0.3), lineWidth: 1)
                                                        )
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        
                        Spacer(minLength: 40)
                        
                        // Delete button
                        Button {
                            showDeleteConfirmation = true
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete Reminder")
                            }
                            .font(Dash.Typography.body)
                            .foregroundStyle(Dash.Colors.overdue)
                            .frame(maxWidth: .infinity)
                            .padding(Dash.Spacing.lg)
                            .background(
                                RoundedRectangle(cornerRadius: Dash.Radius.md)
                                    .fill(Dash.Colors.overdueGlow.opacity(0.3))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Dash.Radius.md)
                                            .stroke(Dash.Colors.overdue.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(Dash.Spacing.xl)
                }
            }
            .navigationTitle("Edit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Dash.Colors.textSecondary)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveChanges()
                        dismiss()
                    }
                    .foregroundStyle(Dash.Colors.accent)
                    .fontWeight(.semibold)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .toolbarBackground(Dash.Colors.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .alert("Delete Reminder?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteItem()
                }
            } message: {
                Text("This cannot be undone.")
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
        .onAppear {
            title = item.title
            tags = item.tags
        }
    }
    
    private func saveChanges() {
        item.title = title.trimmingCharacters(in: .whitespaces)
        item.tags = tags
    }
    
    private func deleteItem() {
        modelContext.delete(item)
        dismiss()
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
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
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
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }
            
            height = y + rowHeight
        }
    }
}

// MARK: - Backburner View

struct BackburnerView: View {
    let items: [DashItem]
    let onRevive: (DashItem) -> Void
    let onLetGo: (DashItem) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Dash.Colors.background
                    .ignoresSafeArea()
                
                if items.isEmpty {
                    // Empty state - explain the feature
                    VStack(spacing: Dash.Spacing.xl) {
                        Text("🔥")
                            .font(.system(size: 56))
                        
                        VStack(spacing: Dash.Spacing.sm) {
                            Text("The Backburner")
                                .font(Dash.Typography.title)
                                .foregroundStyle(Dash.Colors.textPrimary)
                            
                            Text("Tasks sitting for 2+ weeks\nautomatically land here.")
                                .font(Dash.Typography.body)
                                .foregroundStyle(Dash.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        VStack(spacing: Dash.Spacing.md) {
                            HStack(spacing: Dash.Spacing.md) {
                                Text("✨")
                                Text("Out of sight, out of mind")
                                    .font(Dash.Typography.caption)
                                    .foregroundStyle(Dash.Colors.textSecondary)
                            }
                            
                            HStack(spacing: Dash.Spacing.md) {
                                Text("💪")
                                Text("Revive them when you're ready")
                                    .font(Dash.Typography.caption)
                                    .foregroundStyle(Dash.Colors.textSecondary)
                            }
                            
                            HStack(spacing: Dash.Spacing.md) {
                                Text("👋")
                                Text("Or let them go guilt-free")
                                    .font(Dash.Typography.caption)
                                    .foregroundStyle(Dash.Colors.textSecondary)
                            }
                        }
                        .padding(.top, Dash.Spacing.md)
                    }
                    .padding(Dash.Spacing.xl)
                } else {
                    ScrollView {
                        VStack(spacing: Dash.Spacing.md) {
                            // Friendly message
                            Text("These have been waiting a while.\nStill need them?")
                                .font(Dash.Typography.body)
                                .foregroundStyle(Dash.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.bottom, Dash.Spacing.md)
                            
                            ForEach(items) { item in
                                BackburnerItemCard(
                                    item: item,
                                    onRevive: {
                                        onRevive(item)
                                    },
                                    onLetGo: {
                                        onLetGo(item)
                                    }
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
                    Button("Done") {
                        dismiss()
                    }
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
}

// MARK: - Backburner Item Card

struct BackburnerItemCard: View {
    let item: DashItem
    let onRevive: () -> Void
    let onLetGo: () -> Void
    
    private var daysOld: Int {
        let days = Calendar.current.dateComponents([.day], from: item.createdAt, to: Date()).day ?? 0
        return days
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Dash.Spacing.md) {
            HStack {
                Text(item.title)
                    .font(Dash.Typography.body)
                    .foregroundStyle(Dash.Colors.textPrimary)
                    .lineLimit(2)
                
                Spacer()
            }
            
            HStack {
                // How long it's been waiting
                Text("\(daysOld) days")
                    .font(Dash.Typography.caption)
                    .foregroundStyle(Dash.Colors.textTertiary)
                
                Spacer()
                
                // Actions
                HStack(spacing: Dash.Spacing.sm) {
                    Button {
                        onRevive()
                    } label: {
                        Text("Revive")
                            .font(Dash.Typography.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, Dash.Spacing.md)
                            .padding(.vertical, Dash.Spacing.sm)
                            .background(
                                Capsule()
                                    .fill(Dash.Colors.accent)
                            )
                    }
                    
                    Button {
                        onLetGo()
                    } label: {
                        Text("Let go")
                            .font(Dash.Typography.caption)
                            .foregroundStyle(Dash.Colors.textSecondary)
                            .padding(.horizontal, Dash.Spacing.md)
                            .padding(.vertical, Dash.Spacing.sm)
                            .background(
                                Capsule()
                                    .stroke(Dash.Colors.cardBorder, lineWidth: 1)
                            )
                    }
                }
            }
        }
        .padding(Dash.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Dash.Radius.md)
                .fill(Color(hex: "F59E0B").opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: Dash.Radius.md)
                        .stroke(Color(hex: "F59E0B").opacity(0.2), lineWidth: 1)
                )
        )
    }
}

#Preview {
    ContentView()
        .modelContainer(for: DashItem.self, inMemory: true)
}
