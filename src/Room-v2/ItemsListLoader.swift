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
final class ItemsListLoader {
    private let itemRepo: ItemRepository
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
    @MainActor
    func items(for document: some ItemsListableDocument) async throws -> [ItemV2] {
        let uncachedIds = document.itemIds.filter { cache[$0] == nil }
        if !uncachedIds.isEmpty {
            let fetched = try await itemRepo.get(ids: Array(uncachedIds))
            for item in fetched {
                cache[item.id] = item
            }
        }

        return document.itemIds
            .compactMap { cache[$0] }
            .sorted { $0.displayName < $1.displayName }
    }

    /// True when every item the document references resolved. A document can
    /// come back partially loaded if some items are missing or still in flight.
    func isComplete(_ document: some ItemsListableDocument) -> Bool {
        document.itemIds.allSatisfy { cache[$0] != nil }
    }

    // MARK: - Cache

    func cached(_ itemId: String) -> ItemV2? {
        cache[itemId]
    }

    func seed(_ items: [ItemV2]) {
        for item in items {
            cache[item.id] = item
        }
    }

    func invalidate() {
        cache.removeAll()
    }

    func invalidate(_ itemIds: some Sequence<String>) {
        for id in itemIds {
            cache.removeValue(forKey: id)
        }
    }
}
