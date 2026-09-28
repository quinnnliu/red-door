//
//  FirestoreDocumentID.swift
//  RedDoor
//
//  Created by Quinn Liu on 09/27/26.
//

import Foundation

/// Firestore raises an Objective-C exception — not a Swift error, so nothing
/// can catch it — for a document ID that is empty, contains "/", is "." or
/// "..", or is wrapped in double underscores. Any ID that comes from user
/// input or a scanned code has to pass through here before reaching Firestore.
enum FirestoreDocumentID {

    static func isValid(_ id: String) -> Bool {
        !id.isEmpty
            && !id.contains("/")
            && id != "."
            && id != ".."
            && !(id.hasPrefix("__") && id.hasSuffix("__"))
            && id.utf8.count <= 1500
    }

    /// Slug form of a user-entered name. Returns nil when nothing usable
    /// survives, so callers fall back rather than writing an invalid path.
    static func slug(from name: String) -> String? {
        let slug = name
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "/", with: "-")

        return isValid(slug) ? slug : nil
    }
}
