//
//  EssentialsGroup.swift
//  RedDoor
//
//  Created by Quinn Liu on 5/10/26.
//

import Foundation

// MARK: - EssentialsGroupType
struct EssentialsGroupType: ConfigurationOption {
    static let configurationType: String = EssentialsGroup.collectionName
    static let collectionName = "essentials_group_types"
    static let orderByField = EssentialsGroupType.CodingKeys.baseName.stringValue
    static let searchField = EssentialsGroupType.CodingKeys.baseName.stringValue

    let id: String
    let baseName: String
    let emoji: String

    init(baseName: String, emoji: String = "⭐️") {
        self.id = baseName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: " ", with: "-")
        self.baseName = baseName
        self.emoji = emoji
    }

    enum CodingKeys: String, CodingKey {
        case id
        case baseName = "base_name"
        case emoji
    }
}

// MARK: - EssentialsGroup

struct EssentialsGroup: RDDocument {
    static let collectionName: String = "essentials"
    static let orderByField: String = EssentialsGroup.CodingKeys.baseName.stringValue
    static let searchField: String = EssentialsGroup.CodingKeys.baseNameLowercased.stringValue

    var id: String
    var baseName: String
    var baseNameLowercased: String
    var essentialsTypeId: String // maps to EssentialsGroupType

    var location: DocumentLocation
    var itemIds: [String]
    var accessoriesId: String?
    var groupNumber: Int
    var nickname: String?

    enum CodingKeys: String, CodingKey {
        case id, nickname
        case accessoriesId = "accessories_id"
        case itemIds = "item_ids"
        case baseName = "base_name"
        case baseNameLowercased = "base_name_lowercased"
        case essentialsTypeId = "essentials_type_id"
        case location
        case groupNumber = "group_number"
    }

    init(
        id: String = UUID().uuidString,
        baseName: String,
        location: DocumentLocation = DocumentLocation(status: .inStorage, locationId: Warehouse.warehouse1.id),
        essentialsTypeId: String,
        itemIds: [String] = [],
        accessoriesId: String? = nil,
        groupNumber: Int = 0,
        nickname: String? = nil
    ) {
        self.id = id
        self.baseName = baseName
        self.baseNameLowercased = baseName.lowercased()
        self.location = location
        self.essentialsTypeId = essentialsTypeId
        self.itemIds = itemIds
        self.accessoriesId = accessoriesId
        self.groupNumber = groupNumber
        self.nickname = nickname
    }
}
