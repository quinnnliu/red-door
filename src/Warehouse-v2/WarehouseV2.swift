//
//  WarehouseV2.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/7/26.
//

import Foundation

struct WarehouseV2: RDDocument {
    static var collectionName: String = "warehouses"
    static var orderByField: String = "id"
    static var searchField: String = "id"
    
    var id: String
    var baseName: String
    var address: Address
    
    init(baseName: String, address: Address) {
        self.id = baseName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: " ", with: "-")
        self.baseName = baseName
        self.address = address
    }
    
}

extension WarehouseV2 {
    static let warehouse1 = WarehouseV2(baseName: "Warehouse 1", address: Address(street: "123 Main St", city: "Anytown", state: "CA", zipcode: "12345", isWarehouse: true))
    static let warehouse2 = WarehouseV2(baseName: "Warehouse 2", address: Address(street: "456 Main St", city: "Anytown", state: "CA", zipcode: "12345", isWarehouse: true))
}
