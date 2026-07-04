import SwiftUI

struct EditIdeaView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(DashStore.self) private var store

    let item: DashItem
    let allTags: [String]

    @State private var titleText: String = ""
    @State private var noteText: String = ""
    @State private var tags: [String] = []
    @State private var hasDueDate: Bool = false
    @State private var dueDate: Date = Date()
    @State private var showDeleteConfirmation = false
    @State private var customTagInput: String = ""
    @State private var isSparking = false
    @FocusState private var isTitleFocused: Bool
    @FocusState private var isCustomTagFocused: Bool

    private var suggestedTags: [String] {
        guard !titleText.isEmpty else { return [] }
        return TagPredictor.suggestTags(for: titleText, existingUserTags: allTags)
            .filter { !tags.contains($0) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Dash.Colors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Dash.Spacing.xl) {
                        ideaField
                        notesField
                        if DashIntelligence.isAvailable {
                            sparkButton
                        }
                        dueDateField
                        tagsField
                        Spacer(minLength: 40)
                        deleteButton
                    }
                    .padding(Dash.Spacing.xl)
                }
            }
            .navigationTitle("Edit Idea")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Dash.Colors.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { saveChanges(); dismiss() }
                        .foregroundStyle(Dash.Colors.accent)
                        .fontWeight(.semibold)
                        .disabled(titleText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .toolbarBackground(Dash.Colors.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .alert("Delete Idea?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) { store.delete(item); dismiss() }
            } message: {
                Text("This cannot be undone.")
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
        .onAppear {
            titleText = item.title
            noteText = item.body ?? ""
            tags = item.tags
            hasDueDate = item.dueDate != nil
            dueDate = item.dueDate ?? Date()
            isTitleFocused = true
        }
    }

    // MARK: - Fields

    private var ideaField: some View {
        fieldSection(label: "IDEA") {
            TextField("What's the idea?", text: $titleText, axis: .vertical)
                .font(Dash.Typography.idea)
                .foregroundStyle(Dash.Colors.textPrimary)
                .focused($isTitleFocused)
                .lineLimit(1...5)
        }
    }

    private var notesField: some View {
        fieldSection(label: "NOTES") {
            TextField("Add notes, links, context...", text: $noteText, axis: .vertical)
                .font(.system(size: 15, weight: .regular, design: .serif))
                .foregroundStyle(Dash.Colors.textPrimary)
                .lineLimit(3...12)
        }
    }

    private var dueDateField: some View {
        VStack(alignment: .leading, spacing: Dash.Spacing.sm) {
            sectionLabel("DUE DATE")

            VStack(spacing: Dash.Spacing.md) {
                Toggle(isOn: $hasDueDate.animation(.spring(response: 0.3, dampingFraction: 0.8))) {
                    HStack(spacing: Dash.Spacing.md) {
                        Image(systemName: "calendar")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(hasDueDate ? Dash.Colors.accent : Dash.Colors.textTertiary)
                        Text(hasDueDate ? "Due date set" : "No due date")
                            .font(Dash.Typography.body)
                            .foregroundStyle(Dash.Colors.textPrimary)
                    }
                }
                .tint(Dash.Colors.accent)

                if hasDueDate {
                    DatePicker("", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.graphical)
                        .tint(Dash.Colors.accent)
                        .colorScheme(.dark)
                }
            }
            .padding(Dash.Spacing.lg)
            .background(cardBG)
        }
    }

    private var tagsField: some View {
        VStack(alignment: .leading, spacing: Dash.Spacing.sm) {
            sectionLabel("TAGS")

            if !tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Dash.Spacing.sm) {
                        ForEach(tags, id: \.self) { tag in
                            SelectedTagChip(tag: tag) {
                                withAnimation { tags.removeAll { $0 == tag } }
                            }
                        }
                    }
                }
            }

            if !suggestedTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Dash.Spacing.sm) {
                        ForEach(suggestedTags, id: \.self) { tag in
                            TagSuggestionChip(tag: tag) {
                                withAnimation { tags.append(tag) }
                            }
                        }
                    }
                }
            }

            if !allTags.isEmpty {
                Text("All tags")
                    .font(Dash.Typography.caption)
                    .foregroundStyle(Dash.Colors.textTertiary)
                    .padding(.top, Dash.Spacing.sm)

                FlowLayout(spacing: Dash.Spacing.sm) {
                    ForEach(allTags, id: \.self) { tag in
                        let isSelected = tags.contains(tag)
                        let color = Color(hex: TagPredictor.color(for: tag))
                        Button {
                            withAnimation {
                                if isSelected { tags.removeAll { $0 == tag } }
                                else { tags.append(tag) }
                            }
                        } label: {
                            Text(tag.capitalized)
                                .font(Dash.Typography.caption)
                                .foregroundStyle(isSelected ? .white : color)
                                .padding(.horizontal, Dash.Spacing.md)
                                .padding(.vertical, Dash.Spacing.sm)
                                .background(
                                    Capsule()
                                        .fill(isSelected ? color : Dash.Colors.cardBackground)
                                        .overlay(Capsule().stroke(color.opacity(0.3), lineWidth: 1))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Custom tag input
            HStack(spacing: Dash.Spacing.sm) {
                Image(systemName: "tag")
                    .font(.system(size: 13))
                    .foregroundStyle(Dash.Colors.textTertiary)

                TextField("Add custom tag...", text: $customTagInput)
                    .font(Dash.Typography.caption)
                    .foregroundStyle(Dash.Colors.textPrimary)
                    .focused($isCustomTagFocused)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onSubmit { addCustomTag() }

                if !customTagInput.isEmpty {
                    Button("Add") { addCustomTag() }
                        .font(Dash.Typography.caption.weight(.semibold))
                        .foregroundStyle(Dash.Colors.accent)
                }
            }
            .padding(.horizontal, Dash.Spacing.md)
            .padding(.vertical, Dash.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: Dash.Radius.sm)
                    .fill(Dash.Colors.cardBackground)
                    .overlay(RoundedRectangle(cornerRadius: Dash.Radius.sm).stroke(Dash.Colors.cardBorder, lineWidth: 1))
            )
            .padding(.top, Dash.Spacing.sm)
        }
    }

    // MARK: - Spark

    /// On-device model turns the idea into concrete next steps,
    /// appended to the notes. Nothing leaves the device.
    private var sparkButton: some View {
        Button { Task { await runSpark() } } label: {
            HStack(spacing: Dash.Spacing.sm) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .semibold))
                    .symbolEffect(.pulse, options: .repeating, isActive: isSparking)
                Text(isSparking ? "Sparking…" : "Spark next steps")
                    .font(Dash.Typography.caption.weight(.semibold))
            }
            .foregroundStyle(Dash.Colors.accentBright)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Dash.Spacing.md)
            .glassEffect(.regular.tint(Dash.Colors.accent.opacity(0.25)).interactive(), in: .capsule)
        }
        .buttonStyle(.plain)
        .disabled(isSparking || titleText.trimmingCharacters(in: .whitespaces).isEmpty)
        .opacity(isSparking ? 0.7 : 1)
    }

    private func runSpark() async {
        isSparking = true
        defer { isSparking = false }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        let trimmedNote = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let steps = await DashIntelligence.spark(
            title: titleText,
            body: trimmedNote.isEmpty ? nil : trimmedNote
        ) else { return }

        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            noteText = trimmedNote.isEmpty ? steps : trimmedNote + "\n\n" + steps
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private var deleteButton: some View {
        Button { showDeleteConfirmation = true } label: {
            HStack {
                Image(systemName: "trash")
                Text("Delete Idea")
            }
            .font(Dash.Typography.body)
            .foregroundStyle(Dash.Colors.overdue)
            .frame(maxWidth: .infinity)
            .padding(Dash.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: Dash.Radius.md)
                    .fill(Dash.Colors.overdueGlow.opacity(0.3))
                    .overlay(RoundedRectangle(cornerRadius: Dash.Radius.md).stroke(Dash.Colors.overdue.opacity(0.3), lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func fieldSection<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Dash.Spacing.sm) {
            sectionLabel(label)
            content()
                .padding(Dash.Spacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(cardBG)
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(Dash.Typography.micro)
            .foregroundStyle(Dash.Colors.textTertiary)
            .tracking(1)
    }

    private var cardBG: some View {
        RoundedRectangle(cornerRadius: Dash.Radius.md)
            .fill(Dash.Colors.cardBackground)
            .overlay(RoundedRectangle(cornerRadius: Dash.Radius.md).stroke(Dash.Colors.cardBorder, lineWidth: 1))
    }

    private func addCustomTag() {
        let trimmed = customTagInput.trimmingCharacters(in: .whitespaces).lowercased()
        guard !trimmed.isEmpty, !tags.contains(trimmed) else { customTagInput = ""; return }
        withAnimation { tags.append(trimmed) }
        customTagInput = ""
    }

    private func saveChanges() {
        let trimmedNote = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        let updated = item
            .withTitle(titleText.trimmingCharacters(in: .whitespaces))
            .withBody(trimmedNote.isEmpty ? nil : trimmedNote)
            .withTags(tags)
            .withDueDate(hasDueDate ? dueDate : nil)
        store.update(updated)
    }
}
