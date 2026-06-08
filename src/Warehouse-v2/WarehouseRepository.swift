//
//  WarehouseRepository.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/7/26.
//

import FirebaseFirestore

final class WarehouseRepository {
    
    var collectionRef: CollectionReference
    var db: Firestore
    
    init(db: Firestore = Firestore.firestore()) {
        self.db = db
        self.collectionRef = db.collection(WarehouseV2.collectionName)
    }
    
    func getWarehouses() async -> [WarehouseV2] {
        do {
            let snapshot = try await collectionRef.getDocuments()
            let warehouses = snapshot.documents.compactMap { document in
                try? document.data(as: WarehouseV2.self)
            }
            return warehouses
        } catch {
            print("Error fetching warehouses: \(error.localizedDescription)")
            return []
        }
    }
}
