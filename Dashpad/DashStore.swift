import Foundation
import SwiftUI

@Observable
final class DashStore {
    private(set) var items: [DashItem] = []

    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    static let shared = DashStore()

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        fileURL = appSupport.appendingPathComponent("dashpad-items.json")

        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        load()
    }

    // MARK: - Persistence

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            items = try decoder.decode([DashItem].self, from: data)
            migrateTagsIfNeeded()
        } catch {
            items = []
        }
    }

    private func migrateTagsIfNeeded() {
        var changed = false
        for i in items.indices where items[i].tags.isEmpty && !items[i].isArchived {
            if let tag = TagPredictor.autoApplyTag(for: items[i].title, existingUserTags: []) {
                items[i].tags = [tag]
                changed = true
            }
        }
        if changed { save() }
    }

    private func save() {
        guard let data = try? encoder.encode(items) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    // MARK: - CRUD

    func add(_ item: DashItem) {
        items.insert(item, at: 0)
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

    func deleteAll(in collection: [DashItem]) {
        let ids = Set(collection.map(\.id))
        items.removeAll { ids.contains($0.id) }
        save()
    }

    // MARK: - Actions

    func archive(_ item: DashItem) { update(item.archiving()) }
    func unarchive(_ item: DashItem) { update(item.unarchiving()) }
    func pin(_ item: DashItem) { update(item.pinned()) }
    func unpin(_ item: DashItem) { update(item.unpinned()) }
    func revive(_ item: DashItem) { update(item.revived()) }

    // MARK: - Computed

    var activeItems: [DashItem] { items.filter { !$0.isArchived } }
    var archivedItems: [DashItem] { items.filter { $0.isArchived } }
    var archivedCount: Int { archivedItems.count }

    // MARK: - Backward compat (used by AppIntents)

    var incompleteItems: [DashItem] { activeItems }
    var completedItems: [DashItem] { archivedItems }
    var completedCount: Int { archivedCount }
    func complete(_ item: DashItem) { archive(item) }
    func uncomplete(_ item: DashItem) { unarchive(item) }
}

// MARK: - Environment Key

private struct DashStoreKey: EnvironmentKey {
    static let defaultValue = DashStore.shared
}

extension EnvironmentValues {
    var dashStore: DashStore {
        get { self[DashStoreKey.self] }
        set { self[DashStoreKey.self] = newValue }
    }
}
