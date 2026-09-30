//
//  RDDocument.swift
//  RedDoor
//
//  Created by Quinn Liu on 4/25/26.
//

protocol RDDocument: Codable, Hashable, Identifiable {
    var id: String { get }
    var baseName: String { get }
    var nickname: String? { get }
    /// Secondary line shown beneath `displayName` in list rows. Declared here
    /// rather than only in the extension so generic callers dispatch to a
    /// conformer's own implementation instead of the default.
    var metadata: String? { get }

    static var collectionName: String { get }
    static var collectionPath: String { get }
    static var orderByField: String { get }
    static var searchField: String { get }

    static func normalizeSearchText(_ text: String) -> String
}

extension RDDocument {
    var nickname: String? { nil }
    var metadata: String? { nil }
    var displayName: String { nickname ?? baseName }

    static var collectionPath: String { collectionName }

    static func normalizeSearchText(_ text: String) -> String {
        text.lowercased()
    }
}
