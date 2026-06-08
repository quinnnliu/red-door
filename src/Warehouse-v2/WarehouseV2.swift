//
//  WarehouseV2.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/7/26.
//

import Foundation

struct WarehouseV2: AnyRDDocument {
    static var collectionName: String = "warehouses"
    static var orderByField: String = "id"
    static var searchField: String = "id"
    
    var id: String
    var displayName: String
    var address: Address
    
    init(displayName: String, address: Address) {
        self.id = displayName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: " ", with: "-")
        self.displayName = displayName
        self.address = address
    }
    
}

extension WarehouseV2 {
    static let warehouse1 = WarehouseV2(displayName: "Warehouse 1", address: Address(street: "123 Main St", city: "Anytown", state: "CA", zipcode: "12345", isWarehouse: true))
    static let warehouse2 = WarehouseV2(displayName: "Warehouse 2", address: Address(street: "456 Main St", city: "Anytown", state: "CA", zipcode: "12345", isWarehouse: true))
}
