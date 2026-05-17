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
    func set(_ document: T, id: String) throws {
        try collectionRef.document(id).setData(from: document)
    }
    
    func delete(id: String) {
        collectionRef.document(id).delete()
    }
    
    func get(id: String) async throws -> T {
        let snapshot = try await collectionRef.document(id).getDocument()
        return try snapshot.data(as: T.self)
    }
    
    func update(id: String, fields: [AnyHashable: Any]) {
        let documentRef = collectionRef.document(id)
        documentRef.updateData(fields)
    }
    
    // MARK: - Batch participatory
    func set(_ document: T, id: String, inBatch batch: WriteBatch) throws {
        try batch.setData(
            from: document,
            forDocument: collectionRef.document(id)
        )
    }
    
    func delete(id: String, inBatch batch: WriteBatch) {
        batch.deleteDocument(collectionRef.document(id))
    }
    
    func update(id: String, fields: [AnyHashable: Any], inBatch batch: WriteBatch) {
        let documentRef = collectionRef.document(id)
        batch.updateData(fields, forDocument: documentRef)
    }
    
    // MARK: - Transaction participatory
    func get(id: String, in transaction: Transaction) throws -> T {
        let ref = collectionRef.document(id)
        let snapshot = try transaction.getDocument(ref)
        return try snapshot.data(as: T.self)
    }
    
    func set(_ document: T, id: String, in transaction: Transaction) throws {
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
    
    func update(_ id: String, fields: [AnyHashable: Any], in transaction: Transaction) {
        let documentRef = collectionRef.document(id)
        transaction.updateData(fields, forDocument: documentRef)
    }
}
