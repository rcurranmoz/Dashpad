import Foundation
import AppIntents

// MARK: - Add Item Intent

struct AddDashItemIntent: AppIntent {
    static var title: LocalizedStringResource = "Add to Dashpad"
    static var description = IntentDescription("Quickly add a new item to Dashpad")
    static var openAppWhenRun: Bool = false
    
    @Parameter(title: "Title", description: "What do you need to remember?")
    var title: String
    
    @Parameter(title: "Tags", description: "Tags to categorize this item (optional)", default: [])
    var tags: [String]
    
    @Parameter(title: "Due Date", description: "When is this due? (optional)", default: nil)
    var dueDate: Date?
    
    static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$title) to Dashpad") {
            \.$tags
            \.$dueDate
        }
    }
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Get the shared store
        let store = DashStore.shared
        
        // Parse the title for date information
        let (parsedDate, cleanedTitle) = DateParser.parse(title)
        let finalTitle = cleanedTitle.isEmpty ? title : cleanedTitle
        let finalDate = dueDate ?? parsedDate
        
        // Create and add the item
        let item = DashItem(title: finalTitle, dueDate: finalDate, tags: tags)
        store.add(item)
        
        // Return success message
        let message = if let date = finalDate {
            "Added '\(finalTitle)' to Dashpad with due date \(date.formatted(date: .abbreviated, time: .shortened))"
        } else if !tags.isEmpty {
            "Added '\(finalTitle)' to Dashpad with tags: \(tags.joined(separator: ", "))"
        } else {
            "Added '\(finalTitle)' to Dashpad"
        }
        
        return .result(dialog: IntentDialog(stringLiteral: message))
    }
}

// MARK: - Quick Add Intent (Simplified for Action Button)

struct QuickAddDashItemIntent: AppIntent {
    static var title: LocalizedStringResource = "Quick Add to Dashpad"
    static var description = IntentDescription("Quickly add text to Dashpad (great for Action Button)")
    static var openAppWhenRun: Bool = false
    
    @Parameter(title: "Text", requestValueDialog: IntentDialog("What do you need to remember?"))
    var text: String
    
    static var parameterSummary: some ParameterSummary {
        Summary("Quick add \(\.$text) to Dashpad")
    }
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let store = DashStore.shared
        
        // Parse for date information
        let (parsedDate, cleanedTitle) = DateParser.parse(text)
        let finalTitle = cleanedTitle.isEmpty ? text : cleanedTitle
        
        // Suggest tags based on the title
        let allTags = Array(Set(store.incompleteItems.flatMap { $0.tags })).sorted()
        let suggestedTags = TagPredictor.suggestTags(for: finalTitle, existingUserTags: allTags)
        
        // Create item with suggested tags
        let item = DashItem(title: finalTitle, dueDate: parsedDate, tags: Array(suggestedTags.prefix(2)))
        store.add(item)
        
        return .result(dialog: IntentDialog(stringLiteral: "Added to Dashpad"))
    }
}

// MARK: - View Recent Items Intent

struct ViewRecentDashItemsIntent: AppIntent {
    static var title: LocalizedStringResource = "View Recent Dashpad Items"
    static var description = IntentDescription("See your most recent incomplete items")
    static var openAppWhenRun: Bool = false
    
    @Parameter(title: "Limit", description: "Number of items to show", default: 5)
    var limit: Int
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<[DashItemEntity]> & ProvidesDialog {
        let store = DashStore.shared
        
        let recentItems = store.incompleteItems
            .sorted(by: .newest)
            .prefix(limit)
            .map { DashItemEntity(item: $0) }
        
        let message = if recentItems.isEmpty {
            "You have no incomplete items in Dashpad"
        } else {
            "Here are your \(recentItems.count) most recent items"
        }
        
        return .result(value: Array(recentItems), dialog: IntentDialog(stringLiteral: message))
    }
}

// MARK: - Complete Item Intent

struct CompleteDashItemIntent: AppIntent {
    static var title: LocalizedStringResource = "Complete Dashpad Item"
    static var description = IntentDescription("Mark a Dashpad item as complete")
    static var openAppWhenRun: Bool = false
    
    @Parameter(title: "Item")
    var item: DashItemEntity
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let store = DashStore.shared
        
        guard let foundItem = store.items.first(where: { $0.id.uuidString == item.id }) else {
            throw DashpadIntentError.itemNotFound
        }
        
        store.complete(foundItem)
        
        return .result(dialog: IntentDialog(stringLiteral: "Completed '\(foundItem.title)'"))
    }
}

// MARK: - App Shortcuts Provider

struct DashpadShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: QuickAddDashItemIntent(),
            phrases: [
                "Add to \(.applicationName)",
                "Quick add to \(.applicationName)",
                "Remember in \(.applicationName)",
                "Add a reminder to \(.applicationName)"
            ],
            shortTitle: "Quick Add",
            systemImageName: "plus.circle.fill"
        )
        
        AppShortcut(
            intent: AddDashItemIntent(),
            phrases: [
                "Create item in \(.applicationName)",
                "New reminder in \(.applicationName)"
            ],
            shortTitle: "Add Item",
            systemImageName: "plus.square.fill"
        )
        
        AppShortcut(
            intent: ViewRecentDashItemsIntent(),
            phrases: [
                "Show my \(.applicationName) items",
                "What's in \(.applicationName)",
                "View \(.applicationName)"
            ],
            shortTitle: "View Items",
            systemImageName: "list.bullet"
        )
    }
}

// MARK: - Dash Item Entity

struct DashItemEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Dashpad Item")
    static var defaultQuery = DashItemQuery()
    
    var id: String
    var title: String
    var dueDate: Date?
    var tags: [String]
    var isComplete: Bool
    var createdAt: Date
    
    var displayRepresentation: DisplayRepresentation {
        var subtitle: String?
        if let due = dueDate {
            subtitle = "Due: \(due.formatted(date: .abbreviated, time: .shortened))"
        } else if !tags.isEmpty {
            subtitle = tags.joined(separator: ", ")
        }
        
        return DisplayRepresentation(
            title: "\(title)",
            subtitle: subtitle.map { LocalizedStringResource(stringLiteral: $0) },
            image: DisplayRepresentation.Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
        )
    }
    
    init(item: DashItem) {
        self.id = item.id.uuidString
        self.title = item.title
        self.dueDate = item.dueDate
        self.tags = item.tags
        self.isComplete = item.isComplete
        self.createdAt = item.createdAt
    }
}

// MARK: - Entity Query

struct DashItemQuery: EntityQuery {
    @MainActor
    func entities(for identifiers: [String]) async throws -> [DashItemEntity] {
        let store = DashStore.shared
        return store.items
            .filter { identifiers.contains($0.id.uuidString) }
            .map { DashItemEntity(item: $0) }
    }
    
    @MainActor
    func suggestedEntities() async throws -> [DashItemEntity] {
        let store = DashStore.shared
        return store.incompleteItems
            .sorted(by: .newest)
            .prefix(5)
            .map { DashItemEntity(item: $0) }
    }
}

// MARK: - Intent Errors

enum DashpadIntentError: Error, CustomLocalizedStringResourceConvertible {
    case itemNotFound
    case invalidInput
    
    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .itemNotFound:
            return "Item not found in Dashpad"
        case .invalidInput:
            return "Invalid input provided"
        }
    }
}
