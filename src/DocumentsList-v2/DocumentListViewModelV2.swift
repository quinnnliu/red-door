//
//  DocumentsListViewModelV2.swift
//  RedDoor
//
//  Created by Quinn Liu on 4/25/26.
//

import FirebaseFirestore
import Foundation

@Observable
final class DocumentListViewModelV2<T: AnyRDDocument> {
    private let collectionRef: CollectionReference
    private let pageSize: Int
    private var lastDocument: DocumentSnapshot?
    private var isFetching = false
    private var activeFilters: [String: Any] = [:]
    
    var documentsArray: [T] = []
    var hasMoreData = true
    var isLoading = false
    private(set) var activeTypeFilter: String? = nil
    
    init(
        pageSize: Int = 10,
        db: Firestore = Firestore.firestore()
    ) {
        self.pageSize = pageSize
        self.collectionRef = db.collection(T.collectionName)
    }
    
    // MARK: Public Actions
    
    /// Initial load or refresh — resets pagination and uses the current type filter.
    @MainActor
    func refresh() async {
        await reloadWithCurrentFilters()
    }
    
    /// Apply a type filter by raw string value (e.g. ItemType.rawValue).
    /// Clears any active text search and reloads from page 1.
    @MainActor
    func applyTypeFilter(_ rawValue: String?) async {
        activeTypeFilter = rawValue
        await reloadWithCurrentFilters()
    }
    
    /// Trigger a text search against the current type filter.
    @MainActor
    func search(text: String) async {
        await reloadWithCurrentFilters(searchText: text.isEmpty ? nil : text)
    }
    
    @MainActor
    func loadMoreDocuments() async {
        await loadPage(replacingExisting: false)
    }
    
    // MARK: Private Helpers
    
    @MainActor
    private func reloadWithCurrentFilters(searchText: String? = nil) async {
        var filters: [String: Any] = [:]
        if let activeTypeFilter {
            filters["type"] = activeTypeFilter
        }
        if let searchText {
            filters["nameLowercased"] = searchText.lowercased()
        }
        activeFilters = filters
        documentsArray = []
        lastDocument = nil
        hasMoreData = true
        await loadPage(replacingExisting: true)
    }
    
    @MainActor
    func loadInitialDocuments(filters: [String: Any] = [:]) async {
        activeFilters = filters
        documentsArray = []
        lastDocument = nil
        hasMoreData = true
        await loadPage(replacingExisting: true)
    }
    
    @MainActor
    private func loadPage(replacingExisting: Bool) async {
        guard hasMoreData, !isFetching else { return }
        
        isFetching = true
        isLoading = true
        defer {
            isFetching = false
            isLoading = false
        }
        
        do {
            var query = collectionRef
                .order(by: T.orderByField)
                .limit(to: pageSize)
            
            query = applyQueryFilters(query, filters: activeFilters)
            
            if !replacingExisting, let lastDocument {
                query = query.start(afterDocument: lastDocument)
            }
            
            let snapshot = try await query.getDocuments()
            lastDocument = snapshot.documents.last
            hasMoreData = snapshot.documents.count == pageSize
            
            let page = snapshot.documents.compactMap { document -> T? in
                do {
                    return try document.data(as: T.self)
                } catch {
                    print("DocumentsListViewModelV2 decode failed: \(error)")
                    return nil
                }
            }
            
            if replacingExisting {
                documentsArray = page
            } else {
                documentsArray.append(contentsOf: page)
            }
        } catch {
            print("DocumentsListViewModelV2 load failed: \(error)")
        }
    }
    
    // MARK: Query Filters
    
    private func applyQueryFilters(_ query: Query, filters: [String: Any]) -> Query {
        var updatedQuery = query
        
        for (key, value) in filters {
            if key == "nameLowercased", let searchText = value as? String {
                updatedQuery = updatedQuery
                    .whereField("nameLowercased", isGreaterThanOrEqualTo: searchText)
                    .whereField("nameLowercased", isLessThan: searchText + "\u{f8ff}")
            } else if key == "itemsAvailable" {
                updatedQuery = updatedQuery
                    .whereField("availableItemCount", isNotEqualTo: 0)
            } else if key == "addressId", let searchText = value as? String {
                updatedQuery = updatedQuery
                    .whereField("addressId", isGreaterThanOrEqualTo: searchText)
                    .whereField("addressId", isLessThan: searchText + "\u{f8ff}")
            } else {
                updatedQuery = updatedQuery.whereField(key, isEqualTo: value)
            }
        }
        
        return updatedQuery
    }
}
