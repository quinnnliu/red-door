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
    static let orderByField: String = "install_date"
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

    @DayGranular var createdDate: Date
    @DayGranular var installDate: Date
    @DayGranular var uninstallDate: Date
    var clientId: String // TODO: make a "job" object?

    var roomIds: [String]
    var unassignedItemIds: [String]
    var essentialGroupId: String?
    var image: RDImage?

    /// Set when this list was produced by uninstalling an installed list. The
    /// display name is denormalized alongside the ID so a list row can show
    /// where the copy came from without a second read per row.
    var copiedFromInstalledListId: String?
    var copiedFromDisplayName: String?

    init(
        id: String = UUID().uuidString,

        address: Address,

        createdDate: Date,
        installDate: Date,
        uninstallDate: Date,
        clientId: String,

        roomIds: [String] = [],
        unassignedItemIds: [String] = [],
        essentialGroupId: String? = nil,
        image: RDImage? = nil,
        copiedFromInstalledListId: String? = nil,
        copiedFromDisplayName: String? = nil
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
        self.copiedFromInstalledListId = copiedFromInstalledListId
        self.copiedFromDisplayName = copiedFromDisplayName
    }
    
    // MARK: Init from an installed list

    /// Builds the copy pull list produced by uninstalling an installed list.
    /// Dates and client are inherited; they're edited afterward on the new
    /// list's own screen. The address is *not* inherited — the uninstall flow
    /// requires the user to pick where the copy is headed.
    ///
    /// `id` is supplied because it's pre-generated on the uninstall session so
    /// items can be routed here before the document exists.
    init(
        from installedList: InstalledListV2,
        id: String,
        address: Address,
        roomIds: [String],
        unassignedItemIds: [String] = [],
        essentialGroupId: String? = nil
    ) {
        self.id = id

        self.address = address
        self.addressId = address.id

        self.createdDate = .now
        self.installDate = installedList.installDate
        self.uninstallDate = installedList.uninstallDate

        self.clientId = installedList.clientId
        self.roomIds = roomIds
        self.unassignedItemIds = unassignedItemIds
        self.essentialGroupId = essentialGroupId
        self.image = installedList.image
        self.copiedFromInstalledListId = installedList.id
        self.copiedFromDisplayName = installedList.displayName
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
        case copiedFromInstalledListId = "copied_from_installed_list_id"
        case copiedFromDisplayName = "copied_from_display_name"
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
