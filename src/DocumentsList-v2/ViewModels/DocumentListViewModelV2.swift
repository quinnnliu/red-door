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
final class DocumentListViewModelV2<T: AnyRDDocument> {

    // MARK: - Public State

    private(set) var documents: [T] = []
    private(set) var hasMore: Bool = true
    private(set) var isLoading: Bool = false

    // MARK: - Private State

    private let collectionRef: CollectionReference
    private let pageSize: Int
    private var cursor: DocumentSnapshot? = nil
    private var activeFilters: [String: AnyHashable] = [:]
    private var defaultFilters: [String: AnyHashable]?
    /// Incremented on every reload. After a Firestore await resumes, a fetch
    /// checks that its captured generation still matches — if not, it was
    /// superseded and discards its results without touching shared state.
    private var fetchGeneration: Int = 0

    init(pageSize: Int = 10, db: Firestore = Firestore.firestore(), defaultFilters: [String: AnyHashable]? = nil) {
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
    
    /// Remove  a filter and reloads
    func removeFilter(key: String) async {
        var updatedFilters = activeFilters
        updatedFilters.removeValue(forKey: key)
        await startReload(filters: updatedFilters)
    }

    /// Search by text and reload from page 1.
    func search(text: String) async {
        if !text.isEmpty {
            await updateFilter(key: "name_lowercased", value: text.lowercased())
        }
    }

    /// Append the next page. No-op if already loading or no more pages exist.
    func loadMore() async {
        guard hasMore, !isLoading else { return }
        await fetchPage(appending: true)
    }

    // MARK: - Private

    private func startReload(filters: [String: AnyHashable]? = nil) async {
        // Bump the generation so any in-flight fetch discards its results.
        fetchGeneration += 1
        documents = []
        cursor = nil
        hasMore = true
        isLoading = false
        if let filters {
            activeFilters = filters
        }
        await fetchPage(appending: false)
    }

    private func fetchPage(appending: Bool) async {
        guard hasMore, !isLoading else { return }
        isLoading = true

        // Capture generation before yielding so we can detect superseded fetches.
        let generation = fetchGeneration

        var query: Query = collectionRef
            .order(by: T.orderByField)
            .limit(to: pageSize)
        query = applyFilters(to: query)
        if appending, let cursor {
            query = query.start(afterDocument: cursor)
        }

        do {
            let snapshot = try await query.getDocuments()

            // A newer reload started while we were waiting — discard and exit.
            // isLoading will have already been reset by startReload.
            guard fetchGeneration == generation else { return }

            cursor = snapshot.documents.last
            hasMore = snapshot.documents.count == pageSize
            let page = snapshot.documents.compactMap { try? $0.data(as: T.self) }
            if appending {
                documents.append(contentsOf: page)
            } else {
                documents = page
            }
        } catch {
            guard fetchGeneration == generation else { return }
            print("DocumentListViewModelV2 fetch failed: \(error)")
        }

        isLoading = false
    }

    private func applyFilters(to query: Query) -> Query {
        var q = query
        
        let allFilters = activeFilters.merging(defaultFilters ?? [:]) { (current, new) in return new }
        
        for (key, value) in allFilters {
            if key == "name_lowercased", let text = value as? String {
                q = q.whereField("name_lowercased", isGreaterThanOrEqualTo: text)
                     .whereField("name_lowercased", isLessThan: text + "\u{f8ff}")
            } else if key == "address_id", let text = value as? String {
                q = q.whereField("address_id", isGreaterThanOrEqualTo: text)
                     .whereField("address_id", isLessThan: text + "\u{f8ff}")
            } else {
                q = q.whereField(key, isEqualTo: value)
            }
        }
        return q
    }
}
