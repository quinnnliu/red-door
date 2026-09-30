//
//  ItemsListLoader.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/27/26.
//

import Foundation

/// Item cache plus fetch-by-document, shared by every screen that renders the
/// contents of an `ItemsListableDocument` (a room or an essentials group).
/// Extracted because seven ViewModels carried near-identical copies of this.
///
/// Safe to call from any thread. It has to be: a ViewModel invalidates right
/// after a write completes, while the listener that write triggered is already
/// refetching on the main actor, so both touch `cache` at once.
final class ItemsListLoader {
    private let itemRepo: ItemRepository
    private let lock = NSLock()
    private var cache: [String: ItemV2] = [:]

    init(itemRepo: ItemRepository = ItemRepository(), seed: [ItemV2] = []) {
        self.itemRepo = itemRepo
        for item in seed {
            cache[item.id] = item
        }
    }

    // MARK: - Fetch

    /// Fetches any of `ids` that aren't cached yet, then returns every item
    /// that resolved, sorted by display name.
    ///
    /// Takes raw IDs rather than a document so that item collections which
    /// aren't an `ItemsListableDocument` can share the cache — a pull list's
    /// unassigned pool is a plain `[String]` on the list, and the list itself
    /// can't conform, since its items also live across rooms and an
    /// essentials group.
    ///
    /// `Collection` rather than `Sequence`: `ids` is traversed twice, and a
    /// single-pass sequence would be consumed by the cache check.
    func items(ids: some Collection<String>) async throws -> [ItemV2] {
        let uncachedIds = lock.withLock {
            ids.filter { cache[$0] == nil }
        }

        if !uncachedIds.isEmpty {
            let fetched = try await itemRepo.get(ids: uncachedIds)
            lock.withLock {
                for item in fetched {
                    cache[item.id] = item
                }
            }
        }

        return lock.withLock {
            ids.compactMap { cache[$0] }
        }
        .sorted { $0.displayName < $1.displayName }
    }

    /// Callers that publish one section per document should check
    /// `isComplete(_:)` first, so a section never renders half-filled.
    func items(for document: some ItemsListableDocument) async throws -> [ItemV2] {
        try await items(ids: document.itemIds)
    }

    /// True when every one of `ids` resolved. A collection can come back
    /// partially loaded if some items are missing or still in flight.
    func isComplete(ids: some Collection<String>) -> Bool {
        lock.withLock {
            ids.allSatisfy { cache[$0] != nil }
        }
    }

    func isComplete(_ document: some ItemsListableDocument) -> Bool {
        isComplete(ids: document.itemIds)
    }

    // MARK: - Cache

    func cached(_ itemId: String) -> ItemV2? {
        lock.withLock { cache[itemId] }
    }

    func seed(_ items: [ItemV2]) {
        lock.withLock {
            for item in items {
                cache[item.id] = item
            }
        }
    }

    func invalidate() {
        lock.withLock { cache.removeAll() }
    }

    func invalidate(_ itemIds: some Sequence<String>) {
        lock.withLock {
            for id in itemIds {
                cache.removeValue(forKey: id)
            }
        }
    }
}
