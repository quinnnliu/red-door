//
//  Accessories.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/13/26.
//

import Foundation

struct AccessoriesType: AnyRDDocument{
    static let collectionName: String = "accessories_types"
    static let orderByField: String = AccessoriesType.CodingKeys.displayName.stringValue
    static let searchField: String = AccessoriesType.CodingKeys.displayName.stringValue
    
    let id: String
    let displayName: String
    
    init(displayName: String) {
        self.id = displayName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: " ", with: "-")
        self.displayName = displayName
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
    }
}

struct Accessories: AnyRDDocument {
    static let collectionName: String = "accessories"
    static let orderByField: String = Accessories.CodingKeys.displayName.stringValue
    static let searchField: String = Accessories.CodingKeys.displayNameLowercased.stringValue
    
    let id: String
    let displayName: String
    let displayNameLowercased: String
    
    let accessoriesTypeId: String
    let status: LocationStatus
    let locationId: String
    let description: String
    
    let primaryImage: RDImage
    let secondaryImages: [RDImage]?

    init(
        id: String = UUID().uuidString,
        displayName: String,
        accessoriesTypeId: String,
        primaryImage: RDImage,
        secondaryImages: [RDImage]? = nil,
        status: LocationStatus = .inStorage,
        locationId: String = Warehouse.warehouse1.id, // TODO: non-default warehouse (select where they should be stored)
        description: String,
    ) {
        self.id = id
        self.displayName = displayName
        self.displayNameLowercased = displayName.lowercased()
        self.accessoriesTypeId = accessoriesTypeId
        self.primaryImage = primaryImage
        self.secondaryImages = secondaryImages
        self.status = status
        self.locationId = locationId
        self.description = description
    }
    
    enum CodingKeys: String, CodingKey {
        case id, status, description
        case displayName = "display_name"
        case displayNameLowercased = "display_name_lowercased"
        case accessoriesTypeId = "accessories_type_id"
        case primaryImage = "primary_image"
        case secondaryImages = "secondary_images"
        case locationId = "location_id"
    }
}
