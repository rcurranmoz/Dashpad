import Foundation

// MARK: - Sort Mode

enum SortMode: String, CaseIterable, Identifiable, Codable {
    case newest = "Newest First"
    case dueDate = "Due Date"
    case alphabetical = "A-Z"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .newest: return "clock"
        case .dueDate: return "calendar"
        case .alphabetical: return "textformat.abc"
        }
    }
}

// MARK: - Model

struct DashItem: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var body: String?
    var dueDate: Date?
    var isArchived: Bool
    var isPinned: Bool
    var createdAt: Date
    var archivedAt: Date?
    var tags: [String]
    var sortIndex: Int

    init(
        id: UUID = UUID(),
        title: String,
        body: String? = nil,
        dueDate: Date? = nil,
        tags: [String] = []
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.dueDate = dueDate
        self.isArchived = false
        self.isPinned = false
        self.createdAt = Date()
        self.archivedAt = nil
        self.tags = tags
        self.sortIndex = Int(Date().timeIntervalSince1970 * -1000)
    }

    // MARK: - Codable (with migration from v1 field names)

    enum CodingKeys: String, CodingKey {
        case id, title, body, dueDate
        case isArchived, isPinned
        case createdAt, archivedAt, tags, sortIndex
        // Legacy keys from original reminders app
        case isComplete, completedAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        body = try c.decodeIfPresent(String.self, forKey: .body)
        dueDate = try c.decodeIfPresent(Date.self, forKey: .dueDate)
        isArchived = try c.decodeIfPresent(Bool.self, forKey: .isArchived)
            ?? c.decodeIfPresent(Bool.self, forKey: .isComplete)
            ?? false
        isPinned = try c.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        archivedAt = try c.decodeIfPresent(Date.self, forKey: .archivedAt)
            ?? c.decodeIfPresent(Date.self, forKey: .completedAt)
        tags = try c.decodeIfPresent([String].self, forKey: .tags) ?? []
        sortIndex = try c.decodeIfPresent(Int.self, forKey: .sortIndex)
            ?? Int(createdAt.timeIntervalSince1970 * -1000)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(title, forKey: .title)
        try c.encodeIfPresent(body, forKey: .body)
        try c.encodeIfPresent(dueDate, forKey: .dueDate)
        try c.encode(isArchived, forKey: .isArchived)
        try c.encode(isPinned, forKey: .isPinned)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encodeIfPresent(archivedAt, forKey: .archivedAt)
        try c.encode(tags, forKey: .tags)
        try c.encode(sortIndex, forKey: .sortIndex)
    }

    // MARK: - Mutations

    func archiving() -> DashItem {
        var copy = self; copy.isArchived = true; copy.archivedAt = Date(); copy.isPinned = false; return copy
    }

    func unarchiving() -> DashItem {
        var copy = self; copy.isArchived = false; copy.archivedAt = nil; return copy
    }

    func pinned() -> DashItem {
        var copy = self; copy.isPinned = true; return copy
    }

    func unpinned() -> DashItem {
        var copy = self; copy.isPinned = false; return copy
    }

    func revived() -> DashItem {
        var copy = self
        copy.createdAt = Date()
        copy.sortIndex = Int(Date().timeIntervalSince1970 * -1000)
        return copy
    }

    func withTitle(_ title: String) -> DashItem {
        var copy = self; copy.title = title; return copy
    }

    func withBody(_ body: String?) -> DashItem {
        var copy = self; copy.body = body; return copy
    }

    func withTags(_ tags: [String]) -> DashItem {
        var copy = self; copy.tags = tags; return copy
    }

    func withDueDate(_ date: Date?) -> DashItem {
        var copy = self; copy.dueDate = date; return copy
    }

    func movedToTop() -> DashItem {
        var copy = self; copy.sortIndex = Int(Date().timeIntervalSince1970 * -1000) - 1_000_000; return copy
    }

    // MARK: - Backward compat (used by AppIntents)

    var isComplete: Bool { isArchived }

    func completing() -> DashItem { archiving() }
    func uncompleting() -> DashItem { unarchiving() }
}

// MARK: - Sorting

extension Array where Element == DashItem {
    func sorted(by mode: SortMode) -> [DashItem] {
        switch mode {
        case .newest:
            return sorted { $0.createdAt > $1.createdAt }
        case .dueDate:
            return sorted { lhs, rhs in
                switch (lhs.dueDate, rhs.dueDate) {
                case let (d1?, d2?): return d1 < d2
                case (_?, nil): return true
                case (nil, _?): return false
                case (nil, nil): return lhs.createdAt > rhs.createdAt
                }
            }
        case .alphabetical:
            return sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        }
    }
}
