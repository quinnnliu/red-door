//
//  PullListV2.swift
//  RedDoor
//
//  Created by Quinn Liu on 5/16/26.
//

import Foundation
import SwiftUI

struct PullListV2: RDDocument {
    static let collectionName: String = "pull_list_v2"
    static let orderByField: String = "created_date"
    static let searchField: String = "address_id"

    static func normalizeSearchText(_ text: String) -> String {
        Address.normalize(text)
    }

    var id: String

    var address: Address
    var addressId: String
    var baseName: String {
        self.address.getStreetAddress() ?? self.address.formattedAddress
    }

    var createdDate: String
    var installDate: String
    var uninstallDate: String
    var clientId: String // TODO: make a "job" object?

    var roomIds: [String]
    var unassignedItemIds: [String]
    var essentialGroupId: String?
    var image: RDImage?

    init(
        id: String = UUID().uuidString,

        address: Address,
        addressId: String,

        createdDate: String,
        installDate: String,
        uninstallDate: String,
        clientId: String,

        roomIds: [String] = [],
        unassignedItemIds: [String] = [],
        essentialGroupId: String? = nil,
        image: RDImage? = nil
    ) {
        self.id = id

        self.address = address
        self.addressId = address.id

        self.createdDate = createdDate
        self.installDate = installDate
        self.uninstallDate = uninstallDate

        self.clientId = clientId
        self.roomIds = roomIds
        self.unassignedItemIds = unassignedItemIds
        self.essentialGroupId = essentialGroupId
        self.image = image
    }
    
    // MARK: Init from an installed list

    /// Builds the copy pull list produced by uninstalling an installed list.
    /// Address, dates, and client are inherited; they're edited afterward on
    /// the new list's own screen.
    ///
    /// `id` is supplied because it's pre-generated on the uninstall session so
    /// items can be routed here before the document exists.
    init(
        from installedList: InstalledListV2,
        id: String,
        roomIds: [String],
        unassignedItemIds: [String] = [],
        essentialGroupId: String? = nil
    ) {
        self.id = id

        self.address = installedList.address
        self.addressId = installedList.address.id

        self.createdDate = installedList.createdDate
        self.installDate = installedList.installDate
        self.uninstallDate = installedList.uninstallDate

        self.clientId = installedList.clientId
        self.roomIds = roomIds
        self.unassignedItemIds = unassignedItemIds
        self.essentialGroupId = essentialGroupId
        self.image = installedList.image
    }
    
    enum CodingKeys: String, CodingKey {
        case id, address
        case addressId = "address_id"
        case createdDate = "created_date"
        case installDate = "install_date"
        case uninstallDate = "uninstall_date"
        case clientId = "client_id"
        case roomIds = "room_ids"
        case unassignedItemIds = "unassigned_item_ids"
        case essentialGroupId = "essential_group_id"
        case image
    }
}

enum NewEnglandState: String, Filterable, CaseIterable, Codable {
    case ct = "CT"
    case ma = "MA"
    case me = "ME"
    case nh = "NH"
    case ri = "RI"
    case vt = "VT"

    var title: String { rawValue }
    var icon: String? { nil }
    var color: Color? { nil }
}
