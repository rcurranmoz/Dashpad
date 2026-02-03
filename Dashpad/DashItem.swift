import Foundation

// MARK: - Sort Mode

enum SortMode: String, CaseIterable, Identifiable, Codable {
    case dueDate = "Due Date"
    case newest = "Newest First"
    case alphabetical = "A-Z"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .dueDate: return "calendar"
        case .newest: return "clock"
        case .alphabetical: return "textformat.abc"
        }
    }
}

// MARK: - Dash Item Model

struct DashItem: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var dueDate: Date?
    var isComplete: Bool
    var createdAt: Date
    var completedAt: Date?
    var tags: [String]
    var sortIndex: Int
    
    init(
        id: UUID = UUID(),
        title: String,
        dueDate: Date? = nil,
        tags: [String] = []
    ) {
        self.id = id
        self.title = title
        self.dueDate = dueDate
        self.isComplete = false
        self.createdAt = Date()
        self.completedAt = nil
        self.tags = tags
        self.sortIndex = Int(Date().timeIntervalSince1970 * -1000) // Newest first
    }
    
    // MARK: - Codable with defaults for new fields
    
    enum CodingKeys: String, CodingKey {
        case id, title, dueDate, isComplete, createdAt, completedAt, tags, sortIndex
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        dueDate = try container.decodeIfPresent(Date.self, forKey: .dueDate)
        isComplete = try container.decodeIfPresent(Bool.self, forKey: .isComplete) ?? false
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        // Default sortIndex based on createdAt if missing
        sortIndex = try container.decodeIfPresent(Int.self, forKey: .sortIndex) 
            ?? Int(createdAt.timeIntervalSince1970 * -1000)
    }
    
    // MARK: - Mutations (return new copies)
    
    func completing() -> DashItem {
        var copy = self
        copy.isComplete = true
        copy.completedAt = Date()
        return copy
    }
    
    func uncompleting() -> DashItem {
        var copy = self
        copy.isComplete = false
        copy.completedAt = nil
        return copy
    }
    
    func movedToTop() -> DashItem {
        var copy = self
        copy.sortIndex = Int(Date().timeIntervalSince1970 * -1000) - 1_000_000
        return copy
    }
    
    func revived() -> DashItem {
        var copy = self
        copy.createdAt = Date()
        return copy
    }
    
    func withSortIndex(_ index: Int) -> DashItem {
        var copy = self
        copy.sortIndex = index
        return copy
    }
    
    func withTitle(_ title: String) -> DashItem {
        var copy = self
        copy.title = title
        return copy
    }
    
    func withTags(_ tags: [String]) -> DashItem {
        var copy = self
        copy.tags = tags
        return copy
    }
    
    func withDueDate(_ date: Date?) -> DashItem {
        var copy = self
        copy.dueDate = date
        return copy
    }
}

// MARK: - Sorting Extensions

extension Array where Element == DashItem {
    func sorted(by mode: SortMode) -> [DashItem] {
        switch mode {
        case .dueDate:
            return sorted { item1, item2 in
                switch (item1.dueDate, item2.dueDate) {
                case let (date1?, date2?):
                    return date1 < date2
                case (_?, nil):
                    return true
                case (nil, _?):
                    return false
                case (nil, nil):
                    return item1.createdAt > item2.createdAt
                }
            }
        case .newest:
            return sorted { $0.createdAt > $1.createdAt }
        case .alphabetical:
            return sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        }
    }
}
