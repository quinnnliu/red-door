//
//  UninstallSessionRepository.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/27/26.
//

import Firebase

final class UninstallSessionRepository: GenericRepository<UninstallSession> {

    // MARK: - Listener

    /// `.success(nil)` means the document does not exist — the session was
    /// committed or abandoned.
    ///
    /// `GenericRepository.addDocumentListener` cannot express this: it calls
    /// `snapshot.data(as:)` unconditionally, which throws on a missing document
    /// and surfaces deletion as a `.failure` indistinguishable from a real error.
    func addSessionListener(
        id: String,
        onChange: @escaping (Result<UninstallSession?, Error>) -> Void
    ) -> ListenerRegistration {
        collectionRef.document(id).addSnapshotListener { snapshot, error in
            if let error {
                onChange(.failure(error))
                return
            }
            guard let snapshot, snapshot.exists else {
                onChange(.success(nil))
                return
            }
            do {
                onChange(.success(try snapshot.data(as: UninstallSession.self)))
            } catch {
                onChange(.failure(error))
            }
        }
    }

    // MARK: - Session lifecycle

    /// Creates the session only if absent. Returns the lock generation this
    /// caller owns, or `nil` if a session already existed (caller joins as a
    /// viewer).
    func createSession(id: String) async throws -> Int? {
        let ref = collectionRef.document(id)
        let result = try await db.runTransaction { transaction, errorPointer -> Any? in
            do {
                let snapshot = try transaction.getDocument(ref)
                guard !snapshot.exists else { return nil }
                try transaction.setData(
                    from: UninstallSession(id: id, lockGeneration: 1),
                    forDocument: ref
                )
                return 1
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
        return result as? Int
    }

    // MARK: - Assignment writes

    /// Assigns every given item in a single write. Each item is its own map key,
    /// so this cannot conflict with another client assigning different items.
    func assign(
        sessionId: String,
        itemIds: [String],
        destination: UninstallDestination
    ) async throws {
        guard !itemIds.isEmpty else { return }
        let encoded = try Firestore.Encoder().encode(destination)
        let prefix = UninstallSession.CodingKeys.itemDestinations.stringValue
        var fields: [String: Any] = [:]
        for itemId in itemIds {
            fields["\(prefix).\(itemId)"] = encoded
        }
        try await update(id: sessionId, fields: fields)
    }

    func setCopyPullListId(sessionId: String, _ copyId: String) async throws {
        try await update(
            id: sessionId,
            fields: [UninstallSession.CodingKeys.copyPullListId.stringValue: copyId]
        )
    }

    func unassign(sessionId: String, itemIds: [String]) async throws {
        guard !itemIds.isEmpty else { return }
        let prefix = UninstallSession.CodingKeys.itemDestinations.stringValue
        var fields: [String: Any] = [:]
        for itemId in itemIds {
            fields["\(prefix).\(itemId)"] = FieldValue.delete()
        }
        try await update(id: sessionId, fields: fields)
    }
}
