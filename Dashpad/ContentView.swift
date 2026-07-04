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
    @State private var aiSuggestedTags: [String] = []
    @State private var emberBreathing = false
    @State private var hasAppeared = false

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

    // Keyword suggestions are instant; the on-device model's picks merge in
    // once it has had a beat to think (see the .task(id:) on the input bar).
    private var suggestedInputTags: [String] {
        guard !inputText.isEmpty else { return [] }
        let firstLine = inputText.components(separatedBy: "\n").first ?? inputText
        let keyword = TagPredictor.suggestTags(for: firstLine, existingUserTags: allActiveTags)
        var merged = keyword
        for tag in aiSuggestedTags where !merged.contains(tag) { merged.append(tag) }
        return Array(merged.filter { !inputTags.contains($0) }.prefix(4))
    }

    private func isSmartSuggestion(_ tag: String) -> Bool {
        aiSuggestedTags.contains(tag)
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

    // Anything time-sensitive surfaces here no matter where it's filed —
    // auto-filing must never mean forgetting.
    private var upNextItems: [DashItem] {
        let horizon = Date().addingTimeInterval(7 * 24 * 3600)
        return Array(
            store.activeItems
                .filter { !$0.isPinned && ($0.dueDate.map { $0 < horizon } ?? false) }
                .sorted { ($0.dueDate ?? .distantPast) < ($1.dueDate ?? .distantPast) }
                .prefix(3)
        )
    }

    // Fresh captures stay on the pad for a day — you see them land and
    // watch the filing happen — then they graduate to their groups and
    // the pad is clean again. Untagged ideas stay until filed; the pad
    // is their only home.
    private var recentItems: [DashItem] {
        let upNextIDs = Set(upNextItems.map(\.id))
        let freshCutoff = Date().addingTimeInterval(-24 * 3600)
        return regularItems.filter {
            !upNextIDs.contains($0.id)
                && ($0.tags.isEmpty || $0.createdAt > freshCutoff)
        }
    }

    private var isEmpty: Bool {
        isSearching
            ? filteredRegular.isEmpty && filteredPinned.isEmpty
            : recentItems.isEmpty && filteredPinned.isEmpty && upNextItems.isEmpty
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
                // Serif wordmark with an ember full stop — set type, not WordArt
                HStack(alignment: .lastTextBaseline, spacing: 3) {
                    Text("Dashpad")
                        .font(Dash.Typography.largeTitle)
                        .foregroundStyle(Dash.Colors.textPrimary)
                    Circle()
                        .fill(LinearGradient(
                            colors: [Dash.Colors.accentBright, Dash.Colors.accentDeep],
                            startPoint: .top, endPoint: .bottom
                        ))
                        .frame(width: 7, height: 7)
                        .shadow(color: Dash.Colors.accent.opacity(0.8), radius: 5)
                }

                // The splash's scribble, carried into the app — a small
                // handwritten note under all that glass
                ScribbleUnderline()
                    .stroke(
                        LinearGradient(
                            colors: [Dash.Colors.accentBright, Dash.Colors.accentDeep],
                            startPoint: .leading, endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                    )
                    .frame(width: 96, height: 8)
                    .shadow(color: Dash.Colors.accent.opacity(0.4), radius: 4, y: 1)
                    .padding(.vertical, 2)

                Text(Date().formatted(.dateTime.weekday(.wide).month().day()).uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.6)
                    .foregroundStyle(Dash.Colors.textTertiary)
            }

            Spacer()

            // One quiet button. Everything occasional lives behind it —
            // the screen belongs to the ideas.
            Menu {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { isSearching = true }
                } label: {
                    Label("Search", systemImage: "magnifyingglass")
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
                    Label("Sort by", systemImage: sortMode.icon)
                }

                Divider()

                Button { showBackburner = true } label: {
                    Label(
                        backburnerItems.isEmpty ? "Backburner" : "Backburner (\(backburnerItems.count))",
                        systemImage: "flame"
                    )
                }

                Button { showArchived = true } label: {
                    Label("Archive", systemImage: "archivebox")
                }
            } label: {
                ZStack(alignment: .topTrailing) {
                    headerIconButtonLabel(icon: "ellipsis")
                    if !backburnerItems.isEmpty {
                        Circle()
                            .fill(Dash.Colors.accent)
                            .frame(width: 8, height: 8)
                            .overlay(Circle().stroke(Dash.Colors.background, lineWidth: 2))
                            .offset(x: 2, y: -2)
                    }
                }
            }
        }
    }

    private func headerIconButtonLabel(icon: String? = nil, emoji: String? = nil) -> some View {
        Group {
            if let emoji {
                Text(emoji).font(.system(size: 18))
            } else if let icon {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Dash.Colors.textSecondary)
            }
        }
        .frame(width: 40, height: 40)
        .glassEffect(.regular.interactive(), in: .circle)
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
                        isSelected: inputTags.contains(tag),
                        count: store.activeItems.count(where: { $0.tags.contains(tag) })
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
            // Up Next — time-sensitive ideas from any category.
            // Filed never means forgotten.
            if !upNextItems.isEmpty && !isSearching {
                Section {
                    ForEach(Array(upNextItems.enumerated()), id: \.element.id) { index, item in
                        upNextRow(item)
                            .cascadeIn(index: index, revealed: hasAppeared)
                    }
                } header: {
                    sectionHeader(icon: "clock.fill", title: "UP NEXT", color: Dash.Colors.accent)
                }
            }

            // Pinned section
            if !filteredPinned.isEmpty {
                Section {
                    ForEach(Array(filteredPinned.enumerated()), id: \.element.id) { index, item in
                        ideaRow(item)
                            .cascadeIn(index: index + upNextItems.count, revealed: hasAppeared)
                    }
                } header: {
                    pinnedSectionHeader
                }
            }

            // Main feed — every recent capture, tagged or not
            Section {
                if isSearching {
                    ForEach(filteredRegular) { item in ideaRow(item) }
                } else {
                    let recent = recentItems.sorted(by: sortMode)
                    ForEach(Array(recent.enumerated()), id: \.element.id) { index, item in
                        ideaRow(item)
                            .cascadeIn(index: index + upNextItems.count + filteredPinned.count, revealed: hasAppeared)
                    }
                }
            } header: {
                if !isSearching && (!upNextItems.isEmpty || !filteredPinned.isEmpty) && !recentItems.isEmpty {
                    sectionHeader(icon: "tray.fill", title: "RECENT", color: Dash.Colors.textTertiary)
                }
            }

        }
        .listStyle(.plain)
        .onAppear {
            // Cards deal in just as the splash hands off
            Task {
                try? await Task.sleep(for: .seconds(2.2))
                hasAppeared = true
            }
        }
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
        sectionHeader(icon: "pin.fill", title: "PINNED", color: Dash.Colors.warning.opacity(0.7))
    }

    private func sectionHeader(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: Dash.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(color)
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(color)
                .tracking(1.5)
            Spacer()
        }
        .padding(.horizontal, Dash.Spacing.xl)
        .padding(.vertical, Dash.Spacing.xs)
        .listRowInsets(EdgeInsets())
    }

    // MARK: - Up Next Row

    private func dueChip(_ due: Date) -> (label: String, color: Color) {
        let cal = Calendar.current
        let time = due.formatted(date: .omitted, time: .shortened).lowercased()
        if due < Date() { return ("overdue", Dash.Colors.danger) }
        if cal.isDateInToday(due) { return ("today \(time)", Dash.Colors.accent) }
        if cal.isDateInTomorrow(due) { return ("tmrw \(time)", Dash.Colors.accent) }
        let day = due.formatted(.dateTime.weekday(.abbreviated)).lowercased()
        return ("\(day) \(time)", Dash.Colors.textSecondary)
    }

    private func upNextRow(_ item: DashItem) -> some View {
        let chip = dueChip(item.dueDate ?? Date())
        return Button { editingItem = item } label: {
            HStack(spacing: Dash.Spacing.md) {
                Text(chip.label)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(chip.color)
                    .padding(.horizontal, Dash.Spacing.sm)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(chip.color.opacity(0.14)))

                Text(item.title)
                    .font(Dash.Typography.ideaBody)
                    .foregroundStyle(Dash.Colors.textPrimary)
                    .lineLimit(1)

                Spacer(minLength: Dash.Spacing.sm)

                if let tag = item.tags.first {
                    Circle()
                        .fill(Color(hex: TagPredictor.color(for: tag)))
                        .frame(width: 5, height: 5)
                }
            }
            .padding(.horizontal, Dash.Spacing.md)
            .padding(.vertical, Dash.Spacing.sm + 2)
            .background(
                RoundedRectangle(cornerRadius: Dash.Radius.sm)
                    .fill(Dash.Colors.surface.opacity(0.65))
                    .overlay(
                        RoundedRectangle(cornerRadius: Dash.Radius.sm)
                            .strokeBorder(Dash.Colors.borderSubtle, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 0, leading: Dash.Spacing.xl, bottom: 6, trailing: Dash.Spacing.xl))
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button { archive(item) } label: {
                Label("Done", systemImage: "checkmark")
            }
            .tint(Dash.Colors.success)
        }
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
            Image(systemName: isSearching ? "magnifyingglass" : "lightbulb.fill")
                .font(.system(size: 26))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Dash.Colors.accentBright, Dash.Colors.accentDeep],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .shadow(color: Dash.Colors.accent.opacity(emberBreathing ? 0.7 : 0.3), radius: 14)
                .animation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true), value: emberBreathing)
                .frame(width: 64, height: 64)
                .glassEffect(.regular, in: .circle)

            VStack(spacing: Dash.Spacing.xs) {
                // Everything filed ≠ nothing captured. Say which one it is.
                let allFiled = !isSearching && !store.activeItems.isEmpty
                Text(isSearching ? "No results" : allFiled ? "All filed away" : msg.0)
                    .font(.system(size: 19, weight: .medium, design: .serif))
                    .foregroundStyle(Dash.Colors.textPrimary)
                if !isSearching {
                    if allFiled {
                        Text("Every idea is in its place. Tap a category to browse.")
                            .font(.system(size: 14, design: .serif).italic())
                            .foregroundStyle(Dash.Colors.textTertiary)
                    } else if !msg.1.isEmpty {
                        Text(msg.1)
                            .font(.system(size: 14, design: .serif).italic())
                            .foregroundStyle(Dash.Colors.textTertiary)
                    }
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
                            prompt: isInputActive ? nil : Text("Capture a thought…")
                                .font(.system(size: 15, design: .serif).italic())
                                .foregroundStyle(Dash.Colors.textTertiary),
                            axis: .vertical
                        )
                        .font(Dash.Typography.idea)
                        .foregroundStyle(Dash.Colors.textPrimary)
                        .multilineTextAlignment(isInputActive ? .leading : .center)
                        .focused($isInputFocused)
                        .lineLimit(1...8)
                        .onSubmit { addItem() }
                        .onChange(of: isInputFocused) { _, focused in
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                isInputActive = focused
                            }
                            if focused { DashIntelligence.prewarm() }
                        }
                    }
                    .padding(.horizontal, Dash.Spacing.lg)
                    .padding(.vertical, Dash.Spacing.md + 2)
                    .glassEffect(
                        isInputActive
                            ? .regular.tint(Dash.Colors.accent.opacity(0.16)).interactive()
                            : .regular,
                        in: .rect(cornerRadius: Dash.Radius.xl)
                    )
                    .shadow(color: isInputActive ? Dash.Colors.accentGlow.opacity(0.5) : .clear, radius: 16, y: 4)

                    if !inputText.trimmingCharacters(in: .whitespaces).isEmpty {
                        Button { addItem() } label: {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 48, height: 48)
                                .glassEffect(.regular.tint(Dash.Colors.accent).interactive(), in: .circle)
                                .shadow(color: Dash.Colors.accentGlow, radius: 12, y: 4)
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
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: suggestedInputTags)
        .task(id: inputText) {
            // Debounced on-device read of what's being typed: pause for a
            // moment and the model's category pick joins the suggestion chips.
            aiSuggestedTags = []
            let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard DashIntelligence.isAvailable, text.count >= 10 else { return }
            try? await Task.sleep(for: .milliseconds(600))
            guard !Task.isCancelled else { return }
            let result = await DashIntelligence.analyze(text, knownTags: allActiveTags)
            guard !Task.isCancelled, let result else { return }
            aiSuggestedTags = result.tags
        }
    }

    private var tagSuggestionsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Dash.Spacing.sm) {
                Text("Tag:")
                    .font(Dash.Typography.micro)
                    .foregroundStyle(Dash.Colors.textTertiary)
                ForEach(suggestedInputTags, id: \.self) { tag in
                    TagSuggestionChip(tag: tag, isSmart: isSmartSuggestion(tag)) {
                        if !inputTags.contains(tag) { inputTags.append(tag) }
                        addItem()
                    }
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
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

    // Warm ink black, lit faintly from below like a bed of coals.
    // The glow breathes on a slow cycle — alive, but never distracting.
    private var backgroundView: some View {
        ZStack {
            LinearGradient(
                colors: [Dash.Colors.bgTop, Dash.Colors.background],
                startPoint: .top, endPoint: .bottom
            )

            // No fireplace wallpaper — just a cool sheen falling from the
            // top-left, like room light on glass. The ember only appears
            // where it means something: the dot, the scribble, the sparks.
            LinearGradient(
                colors: [Color.white.opacity(0.045), .clear],
                startPoint: .topLeading,
                endPoint: UnitPoint(x: 0.55, y: 0.4)
            )
        }
        .ignoresSafeArea()
        .onAppear { emberBreathing = true }
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

        let newItem = DashItem(title: finalTitle, body: finalBody, dueDate: date, tags: inputTags)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            store.add(newItem)
            inputText = ""
            inputTags = []
            aiSuggestedTags = []
        }

        // Capture is instant; understanding arrives a beat later.
        // The on-device model files the idea while the card is already on screen.
        if newItem.tags.isEmpty {
            store.enrich(newItem)
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
