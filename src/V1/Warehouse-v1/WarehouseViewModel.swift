//
//  WarehouseViewModel.swift
//  RedDoor
//
//  Created by Quinn Liu on 12/14/25.
//

import Foundation
import FirebaseFirestore

@Observable
class WarehouseViewModel {
    var warehouses: [Warehouse] = []

    let db = Firestore.firestore()
    let warehousesCollectionRef: CollectionReference

    init() {
        warehousesCollectionRef = db.collection("warehouses")
    }

    func fetchWarehouses() async {
        do {
            let snapshot = try await warehousesCollectionRef.getDocuments()
            warehouses = snapshot.documents.compactMap { document in
                try? document.data(as: Warehouse.self)
            }
        } catch {
            print("Error fetching warehouses: \(error.localizedDescription)")
        }
    }

    func addWarehouse(warehouse: Warehouse) {
        do {
            try warehousesCollectionRef.addDocument(from: warehouse)
            warehouses.append(warehouse)
        } catch {
            print("Error adding warehouse: \(error.localizedDescription)")
        }
    }
}