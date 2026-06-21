//
//  InstalledList-v2.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/8/26.
//

import Foundation

struct InstalledListV2: RDDocument {
    static let collectionName: String = "installed_list_V2"
    static let orderByField: String = "uninstall_date"
    static let searchField: String = "address_id"

    var id: String
    var listType: DocumentType // TODO: get rid of this field
    var address: Address
    var addressId: String
    var displayName: String {
        address.getStreetAddress() ?? address.formattedAddress
    }
    var createdDate: String
    var installDate: String
    var uninstallDate: String
    var clientId: String
    var roomIds: [String]

    init(from pullList: PullListV2) {
        self.id = pullList.id
        self.listType = .installedListV2
        self.address = pullList.address
        self.addressId = pullList.addressId
        self.createdDate = pullList.createdDate
        self.installDate = pullList.installDate
        self.uninstallDate = pullList.uninstallDate
        self.clientId = pullList.clientId
        self.roomIds = pullList.roomIds
    }

    enum CodingKeys: String, CodingKey {
        case id, address
        case listType = "list_type"
        case addressId = "address_id"
        case createdDate = "created_date"
        case installDate = "install_date"
        case uninstallDate = "uninstall_date"
        case clientId = "client_id"
        case roomIds = "room_ids"
    }
}
