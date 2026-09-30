//
//  InstalledList-v2.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/8/26.
//

import Foundation

struct InstalledListV2: RDDocument {
    static let collectionName: String = "installed_list_v2"
    static let orderByField: String = "uninstall_date"
    static let searchField: String = "address_id"

    static func normalizeSearchText(_ text: String) -> String {
        Address.normalize(text)
    }

    var id: String
    var address: Address
    var addressId: String
    var baseName: String {
        address.getStreetAddress() ?? address.formattedAddress
    }
    @DayGranular var createdDate: Date
    @DayGranular var installDate: Date
    @DayGranular var uninstallDate: Date
    var clientId: String
    var roomIds: [String]
    var essentialGroupId: String?
    var uninstalled: Bool
    var image: RDImage?

    init(from pullList: PullListV2) {
        self.id = pullList.id
        self.address = pullList.address
        self.addressId = pullList.addressId
        self.createdDate = pullList.createdDate
        self.installDate = pullList.installDate
        self.uninstallDate = pullList.uninstallDate
        self.clientId = pullList.clientId
        self.roomIds = pullList.roomIds
        self.essentialGroupId = pullList.essentialGroupId
        self.uninstalled = false
        self.image = pullList.image
    }

    enum CodingKeys: String, CodingKey {
        case id, address
        case addressId = "address_id"
        case createdDate = "created_date"
        case installDate = "install_date"
        case uninstallDate = "uninstall_date"
        case clientId = "client_id"
        case roomIds = "room_ids"
        case essentialGroupId = "essential_group_id"
        case uninstalled
        case image
    }
}

// MARK: - RDListDocument

extension InstalledListV2: RDListDocument {
    static let listKind: RDListKind = .installedList

    /// An uninstalled list is a record of what was there, not a live placement.
    var acceptsNewItems: Bool { !uninstalled }
}
