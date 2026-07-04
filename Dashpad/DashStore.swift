import Foundation
import SwiftUI

@Observable
final class DashStore {
    private(set) var items: [DashItem] = []

    /// IDs currently being analyzed by on-device intelligence.
    /// Cards show a pulsing sparkle while their ID is in here.
    private(set) var enrichingIDs: Set<UUID> = []

    private let localFileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private var cloudObserver: NSObjectProtocol?

    private let cloudKey = "dashpad_items_v1"

    static let shared = DashStore()

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        localFileURL = appSupport.appendingPathComponent("dashpad-items.json")

        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        load()
        setupCloudSync()
    }

    // MARK: - Persistence

    private func load() {
        // iCloud KV store takes priority (most up-to-date across devices)
        if let data = NSUbiquitousKeyValueStore.default.data(forKey: cloudKey),
           let decoded = try? decoder.decode([DashItem].self, from: data) {
            items = decoded
            migrateTagsIfNeeded()
            return
        }
        // Fall back to local file and push it up to iCloud
        guard FileManager.default.fileExists(atPath: localFileURL.path),
              let data = try? Data(contentsOf: localFileURL),
              let decoded = try? decoder.decode([DashItem].self, from: data)
        else { return }
        items = decoded
        migrateTagsIfNeeded()
        save() // migrate local data → iCloud on first run
    }

    private func save() {
        guard let data = try? encoder.encode(items) else { return }
        // Write to iCloud KV store (syncs to all devices automatically)
        NSUbiquitousKeyValueStore.default.set(data, forKey: cloudKey)
        NSUbiquitousKeyValueStore.default.synchronize()
        // Keep a local backup in case iCloud isn't available
        try? data.write(to: localFileURL, options: .atomic)
    }

    // MARK: - iCloud Sync

    private func setupCloudSync() {
        // Kick off an immediate sync request
        NSUbiquitousKeyValueStore.default.synchronize()

        // Watch for changes pushed from other devices
        cloudObserver = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default,
            queue: .main
        ) { [weak self] notification in
            self?.handleCloudChange(notification)
        }
    }

    private func handleCloudChange(_ notification: Notification) {
        // Only act if our key actually changed
        let changedKeys = notification.userInfo?[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String] ?? []
        guard changedKeys.contains(cloudKey) else { return }
        guard let data = NSUbiquitousKeyValueStore.default.data(forKey: cloudKey),
              let decoded = try? decoder.decode([DashItem].self, from: data) else { return }
        items = decoded
    }

    // MARK: - Migration

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

    // MARK: - On-Device Intelligence

    /// Files an untagged capture using the on-device model: picks category
    /// tags and a due date, then applies whatever the user hasn't already
    /// set by the time the model answers. No-op when the model is unavailable.
    func enrich(_ item: DashItem) {
        guard DashIntelligence.isAvailable, !enrichingIDs.contains(item.id) else { return }
        enrichingIDs.insert(item.id)

        let knownTags = Array(Set(activeItems.flatMap(\.tags)))
        Task { @MainActor [weak self] in
            let result = await DashIntelligence.analyze(item.title, knownTags: knownTags)
            guard let self else { return }
            self.enrichingIDs.remove(item.id)

            guard let result,
                  let current = self.items.first(where: { $0.id == item.id }),
                  !current.isArchived else { return }

            var updated = current
            if current.tags.isEmpty, !result.tags.isEmpty { updated.tags = result.tags }
            if current.dueDate == nil, let due = result.dueDate { updated.dueDate = due }
            guard updated != current else { return }

            withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
                self.update(updated)
            }
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        }
    }

    /// Second-chance filing: every untagged active idea gets another pass.
    /// Called when the app comes to the foreground, so a capture that
    /// slipped through (model busy, device asleep, Siri race) still gets
    /// filed. Idempotent — enrich() skips in-flight IDs and re-checks
    /// state before applying anything.
    func enrichUntagged(limit: Int = 8) {
        guard DashIntelligence.isAvailable else { return }
        for item in activeItems.filter({ $0.tags.isEmpty }).prefix(limit) {
            enrich(item)
        }
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
