//
//  ListSessionRepository.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/27/26.
//

import Firebase

/// Shared session lifecycle and destination writes. Concrete subclasses add
/// only the parts specific to their flow, including the commit transaction.
class ListSessionRepository<T: ListSessionDocument>: GenericRepository<T> {

    // MARK: - Listener

    /// `.success(nil)` means the document does not exist — the session has not
    /// been created yet, or was deleted out of band.
    ///
    /// `GenericRepository.addDocumentListener` cannot express this: it calls
    /// `snapshot.data(as:)` unconditionally, which throws on a missing document
    /// and surfaces deletion as a `.failure` indistinguishable from a real error.
    func addSessionListener(
        id: String,
        onChange: @escaping (Result<T?, Error>) -> Void
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
                onChange(.success(try snapshot.data(as: T.self)))
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
                if snapshot.exists {
                    // A committed session is a record. Joining it as a viewer
                    // would present a finished plan as one in progress.
                    guard !(try snapshot.data(as: T.self)).isComplete else {
                        throw RepositoryError.sessionComplete
                    }
                    return nil
                }
                try transaction.setData(from: T.newSession(id: id), forDocument: ref)
                return 1
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
        return result as? Int
    }

    /// Claims the lock and returns the generation this caller now holds.
    /// A transaction rather than `FieldValue.increment` because the caller has
    /// to know which generation it got in order to recognise being displaced.
    func takeoverSession(id: String) async throws -> Int {
        let ref = collectionRef.document(id)
        let result = try await db.runTransaction { transaction, errorPointer -> Any? in
            do {
                let current = try transaction.getDocument(ref).data(as: T.self)
                let next = current.lockGeneration + 1
                transaction.updateData([T.lockGenerationField: next], forDocument: ref)
                return next
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
        guard let generation = result as? Int else { throw RepositoryError.decodeFailure }
        return generation
    }

    // MARK: - Assignment writes
    func assign(
        sessionId: String,
        itemIds: [String],
        destination: T.Destination
    ) async throws {
        guard !itemIds.isEmpty else { return }
        let encoded = try Firestore.Encoder().encode(destination)
        var fields: [String: Any] = [:]
        for itemId in itemIds {
            fields["\(T.itemDestinationsField).\(itemId)"] = encoded
        }
        try await update(id: sessionId, fields: fields)
    }

    func unassign(sessionId: String, itemIds: [String]) async throws {
        guard !itemIds.isEmpty else { return }
        var fields: [String: Any] = [:]
        for itemId in itemIds {
            fields["\(T.itemDestinationsField).\(itemId)"] = FieldValue.delete()
        }
        try await update(id: sessionId, fields: fields)
    }
}
