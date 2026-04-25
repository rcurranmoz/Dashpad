import SwiftUI

struct ContentView: View {
    @Environment(DashStore.self) private var store

    @State private var inputText = ""
    @State private var inputTags: [String] = []
    @State private var isInputActive = false
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var selectedTagFilter: String? = nil
    @State private var editingItem: DashItem? = nil
    @State private var showBackburner = false
    @State private var showArchived = false
    @AppStorage("sortMode") private var sortMode: SortMode = .newest
    @FocusState private var isInputFocused: Bool
    @FocusState private var isSearchFocused: Bool
    @State private var selectedGroup: IdeaGroup? = nil

    private static let backburnerDays = 28

    // MARK: - Derived Collections

    private var backburnerThreshold: Date {
        Calendar.current.date(byAdding: .day, value: -Self.backburnerDays, to: Date()) ?? Date()
    }

    private var backburnerItems: [DashItem] {
        store.activeItems.filter { !$0.isPinned && $0.createdAt < backburnerThreshold }
    }

    private var pinnedItems: [DashItem] {
        store.activeItems.filter { $0.isPinned }
    }

    private var regularItems: [DashItem] {
        store.activeItems.filter { !$0.isPinned && $0.createdAt >= backburnerThreshold }
    }

    private var allActiveTags: [String] {
        Array(Set(store.activeItems.flatMap { $0.tags })).sorted()
    }

    private var filteredRegular: [DashItem] {
        applyFilters(regularItems)
    }

    private var filteredPinned: [DashItem] {
        applyFilters(pinnedItems)
    }

    private func applyFilters(_ items: [DashItem]) -> [DashItem] {
        var result = items
        if let tag = selectedTagFilter {
            result = result.filter { $0.tags.contains(tag) }
        }
        if !searchText.isEmpty {
            let q = searchText.lowercased()
            result = result.filter {
                $0.title.lowercased().contains(q)
                || ($0.body?.lowercased().contains(q) ?? false)
                || $0.tags.contains { $0.lowercased().contains(q) }
            }
        }
        return result.sorted(by: sortMode)
    }

    private var suggestedInputTags: [String] {
        guard !inputText.isEmpty else { return [] }
        let firstLine = inputText.components(separatedBy: "\n").first ?? inputText
        return TagPredictor.suggestTags(for: firstLine, existingUserTags: allActiveTags)
            .filter { !inputTags.contains($0) }
    }

    private var isGroupingMode: Bool {
        selectedTagFilter == nil && !isSearching
    }

    private var groupableTags: Set<String> {
        Set(regularItems.flatMap { $0.tags })
    }

    private var activeGroups: [IdeaGroup] {
        groupableTags.map { IdeaGroup(tag: $0) }
            .sorted { TagPredictor.friendlyName(for: $0.tag) < TagPredictor.friendlyName(for: $1.tag) }
    }

    private var soloItems: [DashItem] {
        regularItems.filter { $0.tags.isEmpty }
    }

    private var isEmpty: Bool {
        isSearching
            ? filteredRegular.isEmpty && filteredPinned.isEmpty
            : soloItems.isEmpty && filteredPinned.isEmpty
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            backgroundView

            VStack(spacing: 0) {
                if isSearching {
                    searchBar
                        .padding(.horizontal, Dash.Spacing.xl)
                        .padding(.top, Dash.Spacing.md)
                        .padding(.bottom, Dash.Spacing.sm)
                } else {
                    header
                        .padding(.horizontal, Dash.Spacing.xl)
                        .padding(.top, Dash.Spacing.md)
                        .padding(.bottom, Dash.Spacing.sm)
                }

                if !allActiveTags.isEmpty && !isSearching {
                    tagFilterBar
                        .padding(.bottom, Dash.Spacing.sm)
                }

                ideaList
            }

            if isInputActive && inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Color.clear
                    .contentShape(Rectangle())
                    .ignoresSafeArea()
                    .onTapGesture {
                        isInputFocused = false
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
            }

            VStack {
                Spacer()
                inputBar
            }
        }
        .preferredColorScheme(.dark)
        .sheet(item: $editingItem) { item in
            EditIdeaView(item: item, allTags: allActiveTags)
        }
        .sheet(isPresented: $showBackburner) {
            BackburnerView(
                items: backburnerItems,
                onRevive: { store.revive($0); UIImpactFeedbackGenerator(style: .medium).impactOccurred() },
                onLetGo: { store.delete($0); UIImpactFeedbackGenerator(style: .light).impactOccurred() }
            )
        }
        .sheet(isPresented: $showArchived) {
            ArchivedView()
        }
        .sheet(item: $selectedGroup) { group in
            GroupView(group: group)
        }
        .onChange(of: allActiveTags) { _, newTags in
            if let sel = selectedTagFilter, !newTags.contains(sel) {
                selectedTagFilter = nil
            }
        }
        .onChange(of: isSearching) { _, searching in
            if searching {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { isSearchFocused = true }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: Dash.Spacing.xs) {
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
                Text(Date().formatted(.dateTime.weekday(.wide).month().day()))
                    .font(Dash.Typography.caption)
                    .foregroundStyle(Dash.Colors.textSecondary)
            }

            Spacer()

            HStack(spacing: Dash.Spacing.sm) {
                headerIconButton(icon: "magnifyingglass") {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { isSearching = true }
                }

                Menu {
                    ForEach(SortMode.allCases) { mode in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { sortMode = mode }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            Label(mode.rawValue, systemImage: mode.icon)
                            if sortMode == mode { Image(systemName: "checkmark") }
                        }
                    }
                } label: {
                    headerIconButtonLabel(icon: sortMode.icon)
                }

                Button { showBackburner = true } label: {
                    ZStack(alignment: .topTrailing) {
                        headerIconButtonLabel(emoji: "🔥")
                        if !backburnerItems.isEmpty {
                            Circle()
                                .fill(Dash.Colors.warning)
                                .frame(width: 10, height: 10)
                                .overlay(Circle().stroke(Dash.Colors.background, lineWidth: 2))
                                .offset(x: 4, y: -4)
                        }
                    }
                }

                Button { showArchived = true } label: {
                    headerIconButtonLabel(icon: "archivebox")
                }
            }
        }
    }

    private func headerIconButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) { headerIconButtonLabel(icon: icon) }
    }

    private func headerIconButtonLabel(icon: String? = nil, emoji: String? = nil) -> some View {
        ZStack {
            Circle()
                .fill(Dash.Colors.cardBackground)
                .frame(width: 40, height: 40)
                .overlay(Circle().stroke(Dash.Colors.cardBorder, lineWidth: 1))
            if let emoji {
                Text(emoji).font(.system(size: 18))
            } else if let icon {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Dash.Colors.textSecondary)
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: Dash.Spacing.md) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Dash.Colors.accent)

            TextField("Search ideas...", text: $searchText)
                .font(Dash.Typography.body)
                .foregroundStyle(Dash.Colors.textPrimary)
                .focused($isSearchFocused)
                .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(Dash.Colors.textTertiary)
                }
            }

            Button("Done") {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isSearching = false
                    searchText = ""
                }
            }
            .font(Dash.Typography.caption.weight(.semibold))
            .foregroundStyle(Dash.Colors.accent)
        }
        .padding(.horizontal, Dash.Spacing.lg)
        .padding(.vertical, Dash.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Dash.Radius.xl)
                .fill(Dash.Colors.cardBackgroundElevated)
                .overlay(RoundedRectangle(cornerRadius: Dash.Radius.xl).stroke(Dash.Colors.accent.opacity(0.4), lineWidth: 1))
        )
    }

    // MARK: - Tag Filter Bar

    private var tagFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Dash.Spacing.sm) {
                ForEach(allActiveTags, id: \.self) { tag in
                    TagFilterPill(
                        label: tag,
                        color: Color(hex: TagPredictor.color(for: tag)),
                        isSelected: inputTags.contains(tag)
                    ) {
                        if !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            if !inputTags.contains(tag) { inputTags.append(tag) }
                            addItem()
                        } else {
                            selectedGroup = IdeaGroup(tag: tag)
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    }
                }
            }
            .padding(.horizontal, Dash.Spacing.xl)
        }
    }

    // MARK: - Idea List

    private var ideaList: some View {
        List {
            // Pinned section
            if !filteredPinned.isEmpty {
                Section {
                    ForEach(filteredPinned) { item in
                        ideaRow(item)
                    }
                } header: {
                    pinnedSectionHeader
                }
            }

            // Main content — untagged items only (tagged items live in their category GroupView)
            Section {
                if isSearching {
                    ForEach(filteredRegular) { item in ideaRow(item) }
                } else {
                    ForEach(soloItems.sorted(by: sortMode)) { item in ideaRow(item) }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .contentMargins(.bottom, 130, for: .scrollContent)
        .overlay {
            if isEmpty {
                emptyState
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .offset(y: -60)
            }
        }
    }

    private var pinnedSectionHeader: some View {
        HStack(spacing: Dash.Spacing.xs) {
            Image(systemName: "pin.fill")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(Dash.Colors.warning.opacity(0.7))
            Text("PINNED")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Dash.Colors.warning.opacity(0.7))
                .tracking(1.5)
            Spacer()
        }
        .padding(.horizontal, Dash.Spacing.xl)
        .padding(.vertical, Dash.Spacing.xs)
        .listRowInsets(EdgeInsets())
    }

    // Compact checklist row (used when a tag filter is active for list-style tags)
    private func compactRow(_ item: DashItem) -> some View {
        HStack(spacing: Dash.Spacing.md) {
            Button { archive(item) } label: {
                Image(systemName: "circle")
                    .font(.system(size: 18, weight: .light))
                    .foregroundStyle(Dash.Colors.divider)
            }
            .buttonStyle(.plain)

            Text(item.title)
                .font(Dash.Typography.body)
                .foregroundStyle(Dash.Colors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, Dash.Spacing.lg)
        .padding(.vertical, Dash.Spacing.md)
        .background(Color.clear)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 0, leading: Dash.Spacing.xl, bottom: 2, trailing: Dash.Spacing.xl))
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) { withAnimation { store.delete(item) } } label: {
                Label("Delete", systemImage: "trash")
            }
            Button { editingItem = item } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(Dash.Colors.accent)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button { archive(item) } label: {
                Label("Done", systemImage: "checkmark")
            }
            .tint(Dash.Colors.success)
        }
    }

    // Normal card row
    private func ideaRow(_ item: DashItem) -> some View {
        IdeaCard(
            item: item,
            onArchive: { archive(item) },
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
            Button { archive(item) } label: {
                Label("Archive", systemImage: "archivebox")
            }
            .tint(Dash.Colors.success)

            Button {
                withAnimation { item.isPinned ? store.unpin(item) : store.pin(item) }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                Label(item.isPinned ? "Unpin" : "Pin", systemImage: item.isPinned ? "pin.slash" : "pin")
            }
            .tint(Dash.Colors.warning)
        }
    }

    private func groupRow(_ group: IdeaGroup) -> some View {
        let groupItems = regularItems.filter { $0.tags.contains(group.tag) }.sorted(by: sortMode)
        return GroupCard(group: group, items: groupItems) {
            selectedGroup = group
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 0, leading: Dash.Spacing.xl, bottom: Dash.Spacing.md, trailing: Dash.Spacing.xl))
    }

    // List mode: grocery/shopping → compact checklist; movies/games → still cards
    private var isListMode: Bool {
        guard let tag = selectedTagFilter else { return false }
        return ["grocery", "shopping"].contains(tag.lowercased())
    }

    // MARK: - Empty State

    private var emptyStateMessages: [(String, String)] {[
        ("What's on your mind?", "Ideas live here."),
        ("Brain empty", "A good sign."),
        ("Blank canvas", "Go make something."),
        ("Nothing captured", "Yet."),
        ("Clear head", "Dangerous."),
        ("Ready when you are", ""),
        ("Good ideas", "usually show up here."),
        ("Waiting for a spark", ""),
    ]}

    private var emptyState: some View {
        let msg = emptyStateMessages[Calendar.current.component(.hour, from: Date()) % emptyStateMessages.count]
        return VStack(spacing: Dash.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(Dash.Colors.cardBackground)
                    .frame(width: 64, height: 64)
                    .overlay(Circle().stroke(Dash.Colors.cardBorder, lineWidth: 1))
                Image(systemName: isSearching ? "magnifyingglass" : "lightbulb")
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(Dash.Colors.textTertiary)
            }
            VStack(spacing: Dash.Spacing.xs) {
                Text(isSearching ? "No results" : msg.0)
                    .font(Dash.Typography.body)
                    .foregroundStyle(Dash.Colors.textPrimary)
                if !isSearching && !msg.1.isEmpty {
                    Text(msg.1)
                        .font(Dash.Typography.caption)
                        .foregroundStyle(Dash.Colors.textTertiary)
                }
            }
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [Dash.Colors.background.opacity(0), Dash.Colors.background],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 30)

            VStack(spacing: Dash.Spacing.sm) {
                if isInputActive && !suggestedInputTags.isEmpty {
                    tagSuggestionsBar
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                if !inputTags.isEmpty {
                    selectedTagsBar
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                HStack(alignment: .bottom, spacing: Dash.Spacing.md) {
                    HStack(alignment: .top, spacing: Dash.Spacing.md) {
                        if isInputActive {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Dash.Colors.accent)
                                .padding(.top, 3)
                                .transition(.opacity)
                        }

                        TextField(
                            "",
                            text: $inputText,
                            prompt: isInputActive ? nil : Text("Capture").foregroundStyle(Dash.Colors.textTertiary),
                            axis: .vertical
                        )
                        .font(Dash.Typography.body)
                        .foregroundStyle(Dash.Colors.textPrimary)
                        .multilineTextAlignment(isInputActive ? .leading : .center)
                        .focused($isInputFocused)
                        .lineLimit(1...8)
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
                                RoundedRectangle(cornerRadius: Dash.Radius.xl).stroke(
                                    isInputActive
                                        ? LinearGradient(colors: [Dash.Colors.accent.opacity(0.6), Dash.Colors.accent.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                        : LinearGradient(colors: [Dash.Colors.cardBorder, Dash.Colors.cardBorder], startPoint: .top, endPoint: .bottom),
                                    lineWidth: 1
                                )
                            )
                            .shadow(color: isInputActive ? Dash.Colors.accentGlow.opacity(0.5) : .clear, radius: 16, y: 4)
                    )

                    if !inputText.trimmingCharacters(in: .whitespaces).isEmpty {
                        Button { addItem() } label: {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(
                                        colors: [Dash.Colors.accentGradientStart, Dash.Colors.accentGradientEnd],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    ))
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
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: inputText.isEmpty)
            }
            .padding(.horizontal, Dash.Spacing.xl)
            .padding(.bottom, Dash.Spacing.xxl)
            .background(Dash.Colors.background)
        }
    }

    private var tagSuggestionsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Dash.Spacing.sm) {
                Text("Tag:")
                    .font(Dash.Typography.micro)
                    .foregroundStyle(Dash.Colors.textTertiary)
                ForEach(suggestedInputTags, id: \.self) { tag in
                    TagSuggestionChip(tag: tag) {
                        if !inputTags.contains(tag) { inputTags.append(tag) }
                        addItem()
                    }
                }
            }
            .padding(.horizontal, Dash.Spacing.xl)
        }
    }

    private var selectedTagsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Dash.Spacing.sm) {
                ForEach(inputTags, id: \.self) { tag in
                    SelectedTagChip(tag: tag) {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            inputTags.removeAll { $0 == tag }
                        }
                    }
                }
            }
            .padding(.horizontal, Dash.Spacing.xl)
        }
    }

    // MARK: - Background

    private var backgroundView: some View {
        ZStack {
            LinearGradient(
                colors: [Dash.Colors.backgroundGradientTop, Dash.Colors.backgroundGradientBottom],
                startPoint: .top, endPoint: .bottom
            )
            GeometryReader { geo in
                Circle()
                    .fill(Dash.Colors.accent.opacity(0.07))
                    .frame(width: 300, height: 300)
                    .blur(radius: 80)
                    .offset(x: -100, y: -50)
                Circle()
                    .fill(Dash.Colors.accentGradientEnd.opacity(0.04))
                    .frame(width: 250, height: 250)
                    .blur(radius: 70)
                    .offset(x: geo.size.width - 100, y: geo.size.height * 0.4)
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Actions

    private func addItem() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Split pasted multi-line content: first line = title, rest = body
        let lines = trimmed.components(separatedBy: "\n")
        let firstLine = lines.first?.trimmingCharacters(in: .whitespaces) ?? trimmed
        let bodyText = lines.dropFirst()
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let (date, cleanedTitle) = DateParser.parse(firstLine)
        let finalTitle = cleanedTitle.isEmpty ? firstLine : cleanedTitle
        let finalBody = bodyText.isEmpty ? nil : bodyText

        isInputFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            store.add(DashItem(title: finalTitle, body: finalBody, dueDate: date, tags: inputTags))
            inputText = ""
            inputTags = []
        }

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private func archive(_ item: DashItem) {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            store.archive(item)
        }
    }
}

#Preview {
    ContentView()
        .environment(DashStore())
}
