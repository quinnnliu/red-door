//
//  PullListV2.swift
//  RedDoor
//
//  Created by Quinn Liu on 5/16/26.
//

import Foundation
import SwiftUI

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

struct InstallingSession: Codable, Hashable {
    let userId: String
    let startedAt: Date

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case startedAt = "started_at"
    }
}

struct PullListV2: RDDocument {
    static let collectionName: String = "pull_list_V2"
    static let orderByField: String = "created_date"
    static let searchField: String = "address_id"

    var id: String
    var listType: DocumentType // TODO: remove this, not used anymore

    var address: Address
    var addressId: String
    var displayName: String {
        self.address.getStreetAddress() ?? self.address.formattedAddress
    }

    var createdDate: String
    var installDate: String
    var uninstallDate: String
    var clientId: String // TODO: make a "job" object?

    var roomIds: [String]
    var installingSession: InstallingSession?
    var image: RDImage?

    init(
        id: String = UUID().uuidString,
        listType: DocumentType = .pullListV2,

        address: Address,
        addressId: String,

        createdDate: String,
        installDate: String,
        uninstallDate: String,
        clientId: String,

        roomIds: [String] = [],
        installingSession: InstallingSession? = nil,
        image: RDImage? = nil
    ) {
        self.id = id
        self.listType = listType

        self.address = address
        self.addressId = address.id

        self.createdDate = createdDate
        self.installDate = installDate
        self.uninstallDate = uninstallDate

        self.clientId = clientId
        self.roomIds = roomIds
        self.installingSession = installingSession
        self.image = image
    }
    
    // TODO: - Init from Existing List (need to re-implement for InstalledListV2
    
//    init(
//        list: PullListV2,
//        listType: DocumentType
//    ) {
//        self.id = list.id
//        self.listType = listType
//        
//        self.address = list.address
//        self.addressId = list.address.id
//        
//        self.createdDate = list.createdDate
//        self.installDate = list.installDate
//        self.uninstallDate = list.uninstallDate
//        
//        self.clientId = list.clientId
//        self.roomIds = list.roomIds
//    }
    
    enum CodingKeys: String, CodingKey {
        case id, address
        case listType = "list_type"
        case addressId = "address_id"
        case createdDate = "created_date"
        case installDate = "install_date"
        case uninstallDate = "uninstall_date"
        case clientId = "client_id"
        case roomIds = "room_ids"
        case installingSession = "installing_session"
        case image
    }
}
