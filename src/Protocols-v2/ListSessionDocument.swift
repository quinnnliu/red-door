//
//  ListSessionDocument.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/27/26.
//

/// A transient plan for moving a list's items, held in Firestore so every
/// client sees it live. The document ID is always the list being worked on,
/// which makes "is this in progress?" a single get and gives session creation
/// a deterministic target.
///
/// `lockGeneration` is a fencing token: only the holder of the current
/// generation may write, and a holder of a lower one knows it was displaced.
protocol ListSessionDocument: RDDocument {
    associatedtype Destination: Codable & Hashable

    var lockGeneration: Int { get }
    var itemDestinations: [String: Destination] { get }

    /// True once the session has been committed. Each flow names the underlying
    /// field for itself, so this is the only way shared lifecycle code can ask.
    var isComplete: Bool { get }

    static func newSession(id: String) -> Self
    static var lockGenerationField: String { get }
    static var itemDestinationsField: String { get }
}
