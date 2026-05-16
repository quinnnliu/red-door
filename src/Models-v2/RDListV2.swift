//
//  RDListV2.swift
//  RedDoor
//
//  Created by Quinn Liu on 5/16/26.
//

import Foundation

struct RDListV2: AnyRDDocument {
    static let collectionName: String = "pull_list_V2"
    static let orderByField: String = "created_date"

    var id: String
    var listType: DocumentType
    
    var address: Address
    var addressId: String
    
    var createdDate: String
    var installDate: String
    var uninstallDate: String
    var clientId: String // TODO: make a "job" object?
    
    var roomIds: [String]
    
    init(
        id: String = UUID().uuidString,
        listType: DocumentType = .pullListV2,
    
        address: Address,
        addressId: String,
    
        createdDate: String,
        installDate: String,
        uninstallDate: String,
        clientId: String,
    
        roomIds: [String] = []
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
    }
    
    // MARK: - Init from Existing List
    
    init(
        list: RDListV2,
        listType: DocumentType
    ) {
        self.id = list.id
        self.listType = listType
        
        self.address = list.address
        self.addressId = list.address.id
        
        self.createdDate = list.createdDate
        self.installDate = list.installDate
        self.uninstallDate = list.uninstallDate
        
        self.clientId = list.clientId
        self.roomIds = list.roomIds
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
