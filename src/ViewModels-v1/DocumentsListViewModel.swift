//
//  DocumentsListViewModel.swift
//  RedDoor
//
//  Created by Quinn Liu on 3/10/25.
//

import FirebaseCore
import FirebaseFirestore
import Foundation

@Observable
class DocumentsListViewModel {
    let db = Firestore.firestore()
    private var lastDocument: DocumentSnapshot?
    private var hasMoreData: Bool = true

    var documentType: DocumentType
    var documentsArray: [Codable] = [] // Generic array to store different types of data
    let fetchLimit: Int = 10

    init(_ documentType: DocumentType) {
        self.documentType = documentType
    }

    // MARK: Fetch Initial Documents

    func fetchInitialDocuments(
        filters: [String: Any]? = nil
    ) async {
        documentsArray = []
        lastDocument = nil
        hasMoreData = true

        var query: Query = db.collection(documentType.collectionString)
            .limit(to: fetchLimit)
            .order(by: documentType.orderByField)

        // applying search and additional features
        if let filters {
            query = applyQueryFilters(query, filters: filters)
        }

        do {
            let querySnapshot = try await query.getDocuments()
            lastDocument = querySnapshot.documents.last

            let dataType = documentType.documentDataType

            let documents: [Codable] = querySnapshot.documents.compactMap { document in
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: document.data(), options: [])
                    return try JSONDecoder().decode(dataType, from: jsonData)
                } catch {
                    print("Error decoding document: \(error)")
                    return nil
                }
            }

            hasMoreData = !querySnapshot.documents.isEmpty && querySnapshot.documents.count == fetchLimit

            documentsArray = documents
        } catch {
            print("Error fetching documents: \(error.localizedDescription)")
        }
    }

    func fetchMoreDocuments(
        filters: [String: Any]? = nil
    ) async {
        guard hasMoreData, let lastDocument else {
            return
        }

        var query: Query = db.collection(documentType.collectionString)
            .order(by: documentType.orderByField)
            .limit(to: fetchLimit)
            .start(afterDocument: lastDocument)

        // applying search and additional features
        if let filters {
            query = applyQueryFilters(query, filters: filters)
        }

        do {
            let querySnapshot = try await query.getDocuments()
            self.lastDocument = querySnapshot.documents.last

            let dataType = documentType.documentDataType

            let documents = querySnapshot.documents.compactMap { document in
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: document.data(), options: [])
                    return try JSONDecoder().decode(dataType, from: jsonData)
                } catch {
                    print("Error decoding document: \(error)")
                    return nil
                }
            }

            hasMoreData = !querySnapshot.documents.isEmpty && querySnapshot.documents.count == fetchLimit

            documentsArray.append(contentsOf: documents)
        } catch {
            print("Error fetching documents: \(error.localizedDescription)")
        }
    }

    // MARK: Fetch All Documents (no pagination)

    func fetchAllDocuments(
        filters: [String: Any]? = nil
    ) async -> [Codable] {
        var query: Query = db.collection(documentType.collectionString)
            .order(by: documentType.orderByField)

        if let filters {
            query = applyQueryFilters(query, filters: filters)
        }

        do {
            let querySnapshot = try await query.getDocuments()
            let dataType = documentType.documentDataType

            let documents: [Codable] = querySnapshot.documents.compactMap { document in
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: document.data(), options: [])
                    return try JSONDecoder().decode(dataType, from: jsonData)
                } catch {
                    print("Error decoding document: \(error)")
                    return nil
                }
            }

            return documents
        } catch {
            print("Error fetching all documents: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: Apply query filters and search filter

    func applyQueryFilters(_ query: Query, filters: [String: Any]) -> Query {
        var updatedQuery = query

        for (key, value) in filters {
            if key == "nameLowercased", let searchText = value as? String {
                updatedQuery = updatedQuery
                    .whereField("nameLowercased", isGreaterThanOrEqualTo: searchText)
                    .whereField("nameLowercased", isLessThan: searchText + "\u{f8ff}")
            } else if key == "itemsAvailable" {
                updatedQuery = updatedQuery
                    .whereField("availableItemCount", isNotEqualTo: 0)
            }  else if key == "addressId", let searchText: String = value as? String {
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
