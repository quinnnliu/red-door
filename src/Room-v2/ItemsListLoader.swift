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

    /// Fetches any of the document's items that aren't cached yet, then returns
    /// every item that resolved, sorted by display name.
    ///
    /// Callers that publish one section per document should check
    /// `isComplete(_:)` first, so a section never renders half-filled.
    func items(for document: some ItemsListableDocument) async throws -> [ItemV2] {
        let uncachedIds = lock.withLock {
            document.itemIds.filter { cache[$0] == nil }
        }

        if !uncachedIds.isEmpty {
            let fetched = try await itemRepo.get(ids: Array(uncachedIds))
            lock.withLock {
                for item in fetched {
                    cache[item.id] = item
                }
            }
        }

        return lock.withLock {
            document.itemIds.compactMap { cache[$0] }
        }
        .sorted { $0.displayName < $1.displayName }
    }

    /// True when every item the document references resolved. A document can
    /// come back partially loaded if some items are missing or still in flight.
    func isComplete(_ document: some ItemsListableDocument) -> Bool {
        lock.withLock {
            document.itemIds.allSatisfy { cache[$0] != nil }
        }
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
