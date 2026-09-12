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
    static let orderByField = EssentialsGroupType.CodingKeys.displayName.stringValue
    static let searchField = EssentialsGroupType.CodingKeys.displayName.stringValue

    let id: String
    let displayName: String
    let emoji: String

    init(displayName: String, emoji: String = "⭐️") {
        self.id = displayName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: " ", with: "-")
        self.displayName = displayName
        self.emoji = emoji
    }

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case emoji
    }
}

// MARK: - EssentialsGroup

struct EssentialsGroup: RDDocument {
    static let collectionName: String = "essentials"
    static let orderByField: String = EssentialsGroup.CodingKeys.displayName.stringValue
    static let searchField: String = EssentialsGroup.CodingKeys.displayNameLowercased.stringValue
    
    var id: String
    var displayName: String
    var displayNameLowercased: String
    var essentialsTypeId: String // maps to EssentialsGroupType

    var status: LocationStatus
    var locationId: String
    var itemIds: [String]
    var accessoriesId: String?
    var groupNumber: Int
    var nickname: String?

    enum CodingKeys: String, CodingKey {
        case id, status, nickname
        case accessoriesId = "accessories_id"
        case itemIds = "item_ids"
        case displayName = "display_name"
        case displayNameLowercased = "display_name_lowercased"
        case essentialsTypeId = "essentials_type_id"
        case locationId = "location_id"
        case groupNumber = "group_number"
    }

    var label: String {
        if let nickname { return "\"\(nickname)\"" }
        return displayName
    }

    init(
        id: String = UUID().uuidString,
        displayName: String,
        status: LocationStatus = .inStorage,
        locationId: String = Warehouse.warehouse1.id,
        essentialsTypeId: String,
        itemIds: [String] = [],
        accessoriesId: String? = nil,
        groupNumber: Int = 0,
        nickname: String? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.displayNameLowercased = displayName.lowercased()
        self.status = status
        self.essentialsTypeId = essentialsTypeId
        self.itemIds = itemIds
        self.accessoriesId = accessoriesId
        self.locationId = locationId
        self.groupNumber = groupNumber
        self.nickname = nickname
    }
}
