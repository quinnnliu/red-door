//
//  GenericRepository.swift
//  RedDoor
//
//  Created by Quinn Liu on 4/24/26.
//

import Firebase

class GenericRepository<T: AnyRDDocument> {
    var collectionRef: CollectionReference
    var db: Firestore
    
    init(db: Firestore = Firestore.firestore()) {
        self.db = db
        self.collectionRef = db.collection(T.collectionName)
    }
    
    func newBatch() -> WriteBatch {
        return db.batch()
    }
    
    // MARK: - Standard
    func set(document: T) throws {
        try collectionRef.document(document.id).setData(from: document)
    }
    
    func delete(id: String) async throws {
        try await collectionRef.document(id).delete()
    }
    
    func get(id: String) async throws -> T {
        let snapshot = try await collectionRef.document(id).getDocument()
        return try snapshot.data(as: T.self)
    }
    
    func update(id: String, fields: [String: AnyHashable]) async throws {
        try await collectionRef.document(id).updateData(fields)
    }

    func get(ids: [String]) async throws -> [T] {
        guard !ids.isEmpty else { return [] }
        var result: [T] = []
        // Firestore "in" queries are capped at 30; chunk at 10 for safety
        let chunks = stride(from: 0, to: ids.count, by: 10).map {
            Array(ids[$0..<min($0 + 10, ids.count)])
        }
        for chunk in chunks {
            let snapshot = try await collectionRef
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments()
            let documents = try snapshot.documents.map { try $0.data(as: T.self) }
            result.append(contentsOf: documents)
        }
        return result
    }
    
    // MARK: - Batch participatory
    func set(document: T, id: String, inBatch batch: WriteBatch) throws {
        try batch.setData(
            from: document,
            forDocument: collectionRef.document(id)
        )
    }
    
    func delete(id: String, inBatch batch: WriteBatch) {
        batch.deleteDocument(collectionRef.document(id))
    }
    
    func update(id: String, fields: [String: AnyHashable], inBatch batch: WriteBatch) {
        let documentRef = collectionRef.document(id)
        batch.updateData(fields, forDocument: documentRef)
    }
    
    // MARK: - Transaction participatory
    func get(id: String, in transaction: Transaction) throws -> T {
        let ref = collectionRef.document(id)
        let snapshot = try transaction.getDocument(ref)
        return try snapshot.data(as: T.self)
    }

    func set(document: T, id: String, in transaction: Transaction) throws {
        try transaction.setData(
            from: document,
            forDocument: collectionRef.document(id)
        )
    }

    func delete(id: String, in transaction: Transaction) {
        transaction.deleteDocument(
            collectionRef.document(id)
        )
    }

    func update(id: String, fields: [String: AnyHashable], in transaction: Transaction) {
        let documentRef = collectionRef.document(id)
        transaction.updateData(fields, forDocument: documentRef)
    }

    // MARK: - Listeners
    typealias ListenerCallback<Value> = (Result<Value, Error>) -> Void

    func addDocumentListener(
        id: String,
        onChange: @escaping ListenerCallback<T>
    ) -> ListenerRegistration {
        collectionRef.document(id).addSnapshotListener { snapshot, error in
            if let error = error {
                onChange(.failure(error))
                return
            }

            guard let snapshot else {
                onChange(.failure(RepositoryError.decodeFailure))
                return
            }

            do {
                let document = try snapshot.data(as: T.self)
                onChange(.success(document))
            } catch {
                onChange(.failure(error))
            }
        }
    }

    func addCollectionListener(
        onChange: @escaping (Result<[T], Error>) -> Void
    ) -> ListenerRegistration {
        collectionRef.addSnapshotListener { snapshot, error in
            if let error = error {
                onChange(.failure(error))
                return
            }

            guard let snapshot else {
                onChange(.failure(RepositoryError.decodeFailure))
                return
            }

            do {
                let documents = try snapshot.documents.map { try $0.data(as: T.self) }
                onChange(.success(documents))
            } catch {
                onChange(.failure(error))
            }
        }
    }
}
