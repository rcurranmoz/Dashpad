import Foundation
import SwiftData

@Model
final class DashItem {
    var title: String
    var dueDate: Date?
    var isComplete: Bool
    var createdAt: Date
    var completedAt: Date?
    var tags: [String]
    
    init(title: String, dueDate: Date? = nil, tags: [String] = []) {
        self.title = title
        self.dueDate = dueDate
        self.isComplete = false
        self.createdAt = Date()
        self.completedAt = nil
        self.tags = tags
    }
    
    func complete() {
        isComplete = true
        completedAt = Date()
    }
    
    func uncomplete() {
        isComplete = false
        completedAt = nil
    }
}
