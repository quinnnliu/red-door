//
//  StorageLocation.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/7/26.
//

import Foundation

struct StorageLocation: ConfigurationOption {
    static let configurationType: String = "storage_locations"
    static let collectionName: String = "storage_locations"
    static let orderByField: String = CodingKeys.baseName.stringValue
    static let searchField: String = CodingKeys.baseName.stringValue

    var id: String
    var baseName: String
    var address: Address

    init(baseName: String, address: Address) {
        self.id = FirestoreDocumentID.slug(from: baseName) ?? UUID().uuidString
        self.baseName = baseName
        self.address = address
    }

    enum CodingKeys: String, CodingKey {
        case id
        case baseName = "base_name"
        case address
    }
}

// MARK: - Metadata

extension StorageLocation {
    var metadata: String? { address.getStreetAddress() }
}
