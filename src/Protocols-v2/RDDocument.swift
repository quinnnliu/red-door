//
//  RDDocument.swift
//  RedDoor
//
//  Created by Quinn Liu on 4/25/26.
//

protocol RDDocument: Codable, Hashable, Identifiable {
    var id: String { get }
    var displayName: String { get }

    static var collectionName: String { get }
    static var orderByField: String { get }
    static var searchField: String { get }

    static func normalizeSearchText(_ text: String) -> String
}

extension RDDocument {
    static func normalizeSearchText(_ text: String) -> String {
        text.lowercased()
    }
}
