import Foundation
import SwiftUI

/// Observable store that persists items to JSON
@Observable
final class DashStore {
    private(set) var items: [DashItem] = []
    
    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    
    init() {
        // Store in Application Support
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        self.fileURL = appSupport.appendingPathComponent("dashpad-items.json")
        
        self.encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        self.decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        load()
    }
    
    // MARK: - Persistence
    
    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            items = []
            return
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            items = try decoder.decode([DashItem].self, from: data)
        } catch {
            print("Failed to load items: \(error)")
            items = []
        }
    }
    
    private func save() {
        do {
            let data = try encoder.encode(items)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to save items: \(error)")
        }
    }
    
    // MARK: - CRUD Operations
    
    func add(_ item: DashItem) {
        items.append(item)
        save()
    }
    
    func update(_ item: DashItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index] = item
        save()
    }
    
    func delete(_ item: DashItem) {
        items.removeAll { $0.id == item.id }
        save()
    }
    
    func delete(id: UUID) {
        items.removeAll { $0.id == id }
        save()
    }
    
    /// Batch update multiple items (single save)
    func updateBatch(_ updatedItems: [DashItem]) {
        for updated in updatedItems {
            if let index = items.firstIndex(where: { $0.id == updated.id }) {
                items[index] = updated
            }
        }
        save()
    }
    
    // MARK: - Convenience Methods
    
    func complete(_ item: DashItem) {
        update(item.completing())
    }
    
    func uncomplete(_ item: DashItem) {
        update(item.uncompleting())
    }
    
    func moveToTop(_ item: DashItem) {
        update(item.movedToTop())
    }
    
    func revive(_ item: DashItem) {
        update(item.revived())
    }
    
    // MARK: - Computed Properties
    
    var completedItems: [DashItem] {
        items.filter { $0.isComplete }
    }
    
    var incompleteItems: [DashItem] {
        items.filter { !$0.isComplete }
    }
    
    var completedCount: Int {
        items.filter { $0.isComplete }.count
    }
}

// MARK: - Environment Key

private struct DashStoreKey: EnvironmentKey {
    static let defaultValue = DashStore()
}

extension EnvironmentValues {
    var dashStore: DashStore {
        get { self[DashStoreKey.self] }
        set { self[DashStoreKey.self] = newValue }
    }
}
