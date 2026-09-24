//
//  Warehouse.swift
//  RedDoor
//
//  Created by Quinn Liu on 10/21/25.
//

import Foundation

struct Warehouse: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var address: Address

    init(name: String, address: Address) {
        self.id = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: " ", with: "-")
        self.name = name
        self.address = address
    }

}

extension Warehouse {
    static let warehouse1 = Warehouse(name: "Warehouse 1", address: Address(street: "123 Main St", city: "Anytown", state: "CA", zipcode: "12345", isWarehouse: true))
    static let warehouse2 = Warehouse(name: "Warehouse 2", address: Address(street: "456 Main St", city: "Anytown", state: "CA", zipcode: "12345", isWarehouse: true))
}
