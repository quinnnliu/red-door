//
//  Accessories.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/13/26.
//

import Foundation

struct AccessoriesType: ConfigurationOption {
    static let collectionName: String = "accessories_types"
    static var configurationType: String = Accessories.collectionName
    static let orderByField: String = AccessoriesType.CodingKeys.baseName.stringValue
    static let searchField: String = AccessoriesType.CodingKeys.baseName.stringValue

    let id: String
    let baseName: String

    init(baseName: String) {
        self.id = FirestoreDocumentID.slug(from: baseName) ?? UUID().uuidString
        self.baseName = baseName
    }

    enum CodingKeys: String, CodingKey {
        case id
        case baseName = "base_name"
    }
}

struct Accessories: RDDocument {
    static let collectionName: String = "accessories"
    static let orderByField: String = Accessories.CodingKeys.baseNameLowercased.stringValue
    static let searchField: String = Accessories.CodingKeys.baseNameLowercased.stringValue

    let id: String
    var baseName: String
    var baseNameLowercased: String

    var accessoriesTypeId: String
    let location: DocumentLocation
    var description: String

    var primaryImage: RDImage
    let secondaryImages: [RDImage]?
    var accessoriesNumber: Int
    var nickname: String?

    @NullEncodable var essentialsGroupId: String?

    init(
        id: String = UUID().uuidString,
        baseName: String,
        accessoriesTypeId: String,
        primaryImage: RDImage,
        secondaryImages: [RDImage]? = nil,
        location: DocumentLocation,
        description: String,
        accessoriesNumber: Int = 0,
        nickname: String? = nil,
        essentialsGroupId: String? = nil
    ) {
        self.id = id
        self.baseName = baseName
        self.baseNameLowercased = baseName.lowercased()
        self.accessoriesTypeId = accessoriesTypeId
        self.primaryImage = primaryImage
        self.secondaryImages = secondaryImages
        self.location = location
        self.description = description
        self.accessoriesNumber = accessoriesNumber
        self.nickname = nickname
        self.essentialsGroupId = essentialsGroupId
    }

    enum CodingKeys: String, CodingKey {
        case id, description, nickname
        case baseName = "base_name"
        case baseNameLowercased = "base_name_lowercased"
        case accessoriesTypeId = "accessories_type_id"
        case primaryImage = "primary_image"
        case secondaryImages = "secondary_images"
        case location
        case accessoriesNumber = "accessories_number"
        case essentialsGroupId = "essentials_group_id"
    }
}
