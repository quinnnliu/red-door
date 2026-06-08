//
//  WarehouseV2ViewModel.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/7/26.
//

// TODO: update this to be v2

import Foundation
import FirebaseFirestore

@Observable
class WarehouseV2ViewModel {
    var warehouses: [WarehouseV2] = []
    
    let db: Firestore
    let warehousesCollectionRef: CollectionReference
    
    init(db: Firestore = Firestore.firestore()) {
        self.db = db
        self.warehousesCollectionRef = db.collection(WarehouseV2.collectionName)
    }
    
    func fetchWarehouses() async {
        do {
            let snapshot = try await warehousesCollectionRef.getDocuments()
            warehouses = snapshot.documents.compactMap { document in
                try? document.data(as: WarehouseV2.self)
            }
        } catch {
            print("Error fetching warehouses: \(error.localizedDescription)")
        }
    }
    
    func addWarehouse(warehouse: WarehouseV2) {
        do {
            try warehousesCollectionRef.addDocument(from: warehouse)
            warehouses.append(warehouse)
        } catch {
            print("Error adding warehouse: \(error.localizedDescription)")
        }
    }
}
