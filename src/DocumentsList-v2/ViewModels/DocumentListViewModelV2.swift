//
//  DocumentsListViewModelV2.swift
//  RedDoor
//
//  Created by Quinn Liu on 4/25/26.
//

import FirebaseFirestore
import Foundation

@Observable
@MainActor
final class DocumentListViewModelV2<T: RDDocument> {

    // MARK: - Public State

    /// Every loaded document, ignoring any local search.
    private(set) var documents: [T] = []
    private(set) var localSearchText: String? = nil

    /// What a list should render: `documents` narrowed by the local search, if one is active.
    var visibleDocuments: [T] {
        guard useLocalSearch, let text = localSearchText else { return documents }
        return documents.filter { T.normalizeSearchText($0.displayName).contains(text) }
    }

    /// With user filters applied, every matching document is loaded at once and searched in memory.
    var useLocalSearch: Bool { activeFiltersApplied }

    private(set) var hasMore: Bool = true
    private(set) var isLoading: Bool = false

    // MARK: - Private State

    private let collectionRef: CollectionReference
    private let pageSize: Int
    private var cursor: DocumentSnapshot? = nil
    private(set) var activeFilters: [String: AnyHashable] = [:]
    private(set) var defaultFilters: [String: AnyHashable]?
    var activeFiltersApplied: Bool {
        activeFilters.keys.contains { $0 != T.searchField }
    }
    var defaultFilterKeys: Set<String> {
        defaultFilters.map { Set($0.keys) } ?? []
    }
    /// Incremented on every reload. After a Firestore await resumes, a fetch
    /// checks that its captured generation still matches — if not, it was
    /// superseded and discards its results without touching shared state.
    private var fetchGeneration: Int = 0

    init(pageSize: Int = 30, db: Firestore = Firestore.firestore(), defaultFilters: [String: AnyHashable]? = nil) {
        self.pageSize = pageSize
        self.collectionRef = db.collection(T.collectionName)
        self.defaultFilters = defaultFilters
    }

    // MARK: - Public API

    /// Reset and reload from page 1 using the current filters.
    func refresh() async {
        await startReload()
    }
    
    /// Update the value for a filter (adds if doesn't already exist) and reloads
    func updateFilter(key: String, value: AnyHashable) async {
        var updatedFilters = activeFilters
        updatedFilters.updateValue(value, forKey: key)
        await startReload(filters: updatedFilters)
    }
    
    /// Remove a filter and reloads
    func removeFilter(key: String) async {
        var updatedFilters = activeFilters
        updatedFilters.removeValue(forKey: key)
        await startReload(filters: updatedFilters)
    }

    /// Search by text and reload from page 1. Ignored while filters are applied.
    func search(text: String) async {
        guard !text.isEmpty, !activeFiltersApplied else { return }
        await updateFilter(key: T.searchField, value: T.normalizeSearchText(text))
    }

    /// Search the already-loaded documents in memory. Use while `useLocalSearch` is true.
    func localSearch(text: String) {
        localSearchText = text.isEmpty ? nil : T.normalizeSearchText(text)
    }

    func clearLocalSearch() {
        localSearchText = nil
    }

    func handleSearchAction(_ action: SearchBarAction) async {
        switch action {
        case .search(let text):
            await search(text: text)
        case .clear:
            await removeFilter(key: T.searchField)
        }
    }

    /// Replace all active filters and reload.
    func setFilters(_ filters: [String: AnyHashable]) async {
        await startReload(filters: filters)
    }

    func loadMore() async {
        guard hasMore, !isLoading else { return }
        await fetchPage(appending: true)
    }

    // MARK: - Private

    private func startReload(filters: [String: AnyHashable]? = nil) async {
        // Bump the generation so any in-flight fetch discards its results.
        fetchGeneration += 1
        documents = []
        // Only a filter change invalidates the local search. A plain refresh keeps it.
        if filters != nil { localSearchText = nil }
        cursor = nil
        hasMore = true
        isLoading = false
        if var filters {
            // A server prefix search never combines with user filters (search is local then).
            if filters.keys.contains(where: { $0 != T.searchField }) {
                filters.removeValue(forKey: T.searchField)
            }
            activeFilters = filters
        }
        await fetchPage(appending: false)
    }

    /// Filtered queries are left unsorted so Firestore can serve them from its automatic
    /// single-field indexes. Search sorts by its own range field.
    private var sortField: String? {
        if activeFilters[T.searchField] != nil { return T.searchField }
        return activeFiltersApplied ? nil : T.orderByField
    }

    private func fetchPage(appending: Bool) async {
        guard hasMore, !isLoading else { return }
        isLoading = true

        // Capture generation before yielding so we can detect superseded fetches.
        let generation = fetchGeneration
        let loadAll = useLocalSearch

        var query: Query = collectionRef
        query = applyFilters(to: query)
        if let sortField {
            query = query.order(by: sortField)
        }
        if !loadAll {
            query = query.limit(to: pageSize)
            if appending, let cursor {
                query = query.start(afterDocument: cursor)
            }
        }

        do {
            let snapshot = try await query.getDocuments()

            // A newer reload started while we were waiting — discard and exit.
            // isLoading will have already been reset by startReload.
            guard fetchGeneration == generation else { return }

            cursor = snapshot.documents.last
            hasMore = loadAll ? false : snapshot.documents.count == pageSize
            var page: [T] = snapshot.documents.compactMap { doc in
                do {
                    return try doc.data(as: T.self)
                } catch {
                    print("[DocumentList:\(T.collectionName)] decode error for doc \(doc.documentID): \(error)")
                    return nil
                }
            }

            if loadAll { page.sort { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending } }

            if appending {
                documents.append(contentsOf: page)
            } else {
                documents = page
            }
        } catch {
            guard fetchGeneration == generation else { return }
            print("[DocumentList:\(T.collectionName)] fetch FAILED: \(error)")
        }

        isLoading = false
    }

    private func applyFilters(to query: Query) -> Query {
        var q = query

        let allFilters = activeFilters.merging(defaultFilters ?? [:]) { (current, new) in return new }

        for (key, value) in allFilters {
            // Local search handles text matching while user filters are applied.
            if key == T.searchField, useLocalSearch { continue }

            if key == T.searchField, let text = value as? String {
                q = q.whereField(key, isGreaterThanOrEqualTo: text)
                     .whereField(key, isLessThan: text + "\u{f8ff}")
            } else if let values = value.base as? [AnyHashable] {
                // Multi-select. Empty means no filter (`in: []` throws).
                switch values.count {
                case 0:  continue
                case 1:  q = q.whereField(key, isEqualTo: values[0].base)
                default: q = q.whereField(key, in: values.map(\.base))
                }
            } else {
                q = q.whereField(key, isEqualTo: value.base)
            }
        }
        return q
    }
}
