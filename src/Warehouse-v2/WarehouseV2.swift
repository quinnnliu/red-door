//
//  WarehouseV2.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/7/26.
//

// TODO: Rename WarehouseV2 to StorageLocation (and update all references)

import Foundation

struct WarehouseV2: ConfigurationOption {
    static let configurationType: String = "warehouses"
    static let collectionName: String = "warehouse_types"
    static let orderByField: String = CodingKeys.baseName.stringValue
    static let searchField: String = CodingKeys.baseName.stringValue

    var id: String
    var baseName: String
    var address: Address

    init(baseName: String, address: Address) {
        self.id = baseName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: " ", with: "-")
        self.baseName = baseName
        self.address = address
    }

    enum CodingKeys: String, CodingKey {
        case id
        case baseName = "base_name"
        case address
    }
}
