//
//  RDListDocumentViewModel.swift
//  RedDoor
//
//  Created by Quinn Liu on 3/29/25.
//

import Foundation
import FirebaseFirestore

@Observable
class RDListDocumentViewModel {
    // MARK: - Configuration
    
    let documentType: DocumentType
    let primaryStatus: InstallationStatus
    let secondaryStatus: InstallationStatus
    
    // MARK: - Data Properties
    
    var primaryLists: [RDList] = []
    var secondaryLists: [RDList] = []
    var searchResults: [RDList] = []
    
    // MARK: - Loading States
    
    var isLoadingPrimary = false
    var isLoadingSecondary = false
    var isLoadingSearch = false
    
    // MARK: - Error Handling
    
    var errorMessage: String?
    
    // MARK: - Private Properties
    
    private let documentsListViewModel: DocumentsListViewModel
    
    // MARK: - Initialization
    
    init(
        documentType: DocumentType,
        primaryStatus: InstallationStatus,
        secondaryStatus: InstallationStatus
    ) {
        self.documentType = documentType
        self.primaryStatus = primaryStatus
        self.secondaryStatus = secondaryStatus
        self.documentsListViewModel = DocumentsListViewModel(documentType)
    }
    
    // MARK: - Public Methods
    
    /// Fetch both primary and secondary lists in parallel
    @MainActor
    func fetchInitialData() async {
        async let primaryTask: Void = fetchPrimaryLists()
        async let secondaryTask: Void = fetchSecondaryLists(initial: true)
        
        _ = await (primaryTask, secondaryTask)
    }
    
    /// Fetch all primary status lists (no pagination)
    @MainActor
    func fetchPrimaryLists() async {
        isLoadingPrimary = true
        errorMessage = nil
        
        defer { isLoadingPrimary = false }
        
        let filters: [String: Any] = ["status": primaryStatus.rawValue]
        let documents = await documentsListViewModel.fetchAllDocuments(filters: filters)
        primaryLists = documents.compactMap { $0 as? RDList }
    }
    
    /// Fetch secondary status lists with pagination
    @MainActor
    func fetchSecondaryLists(initial isInitial: Bool) async {
        isLoadingSecondary = true
        errorMessage = nil
        
        defer { isLoadingSecondary = false }
        
        let filters: [String: Any] = ["status": secondaryStatus.rawValue]
        
        if isInitial {
            await documentsListViewModel.fetchInitialDocuments(filters: filters)
        } else {
            await documentsListViewModel.fetchMoreDocuments(filters: filters)
        }
        
        // Update secondaryLists from the viewModel's documentsArray
        secondaryLists = documentsListViewModel.documentsArray.compactMap { $0 as? RDList }
    }
    
    /// Fetch search results combining primary and secondary status lists
    @MainActor
    func fetchSearchResults(query: String) async {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isLoadingSearch = true
        errorMessage = nil
        
        defer { isLoadingSearch = false }
        
        let filters: [String: Any] = [
            "addressId": query
        ]
        
        let documents = await documentsListViewModel.fetchAllDocuments(filters: filters)
        searchResults = documents.compactMap { $0 as? RDList }
    }
    
    /// Clear search results
    func clearSearchResults() {
        searchResults = []
    }
}

// MARK: - Helper Extensions

extension Array where Element == RDList {
    func sortedByStatus(primary: InstallationStatus, secondary: InstallationStatus) -> [RDList] {
        let primaryLists = self.filter { $0.status == primary }
            .sorted { $0.createdDate > $1.createdDate }
        let secondaryLists = self.filter { $0.status == secondary }
            .sorted { $0.createdDate > $1.createdDate }
        return primaryLists + secondaryLists
    }
}

