//
//  RDList.swift
//  RedDoor
//
//  Created by Quinn Liu on 8/26/24.
//

import Foundation
import MapKit
import FirebaseFirestore

enum InstallationStatus: String, Codable {
    case planning = "planning"
    case staging = "staging"
    case installed = "installed"
    case unstaged = "unstaged"
}

struct RDList: Codable, Identifiable, Hashable {
    var id: String
    var listType: DocumentType

    var address: Address
    var addressId: String

    var createdDate: String
    var installDate: String
    var uninstallDate: String
    var status: InstallationStatus
    var client: String

    var roomIds: [String]

    // MARK: - Init from Address (might not be needed)

    init(
        address: Address,
        installDate: String = "",
        uninstallDate: String = "",
        client: String = "",
        status: InstallationStatus = .planning,
        roomNames: [String] = [],
        listType: DocumentType
    ) {
        id = UUID().uuidString
        self.listType = listType

        self.address = address
        self.addressId = address.id

        self.createdDate = ISO8601DateFormatter().string(from: Date())
        self.installDate = installDate
        self.uninstallDate = uninstallDate
        self.installDate = installDate
        self.status = status
        self.client = client
        self.roomIds = roomNames
    }

    // MARK: - Init from Existing List

    init(
        list: RDList,
        status: InstallationStatus,
        listType: DocumentType
    ) {
        id = list.id
        self.listType = listType

        self.address = list.address
        self.addressId = list.address.id

        self.createdDate = list.createdDate
        self.installDate = list.installDate
        self.uninstallDate = list.uninstallDate

        self.status = status
        self.client = list.client
        self.roomIds = list.roomIds
    }

    // MARK: - Init from blank

    init(
        listType: DocumentType = .pull_list
    ) {
        self.id = UUID().uuidString
        self.listType = listType

        self.address = Address()
        self.addressId = address.id

        self.createdDate = ISO8601DateFormatter().string(from: Date())
        self.installDate = ""
        self.uninstallDate = ""

        status = .planning
        self.client = ""
        self.roomIds = []
    }

    // TODO: Eventually move to RDListDataStore
    static func getList(listId: String, listType: DocumentType = .installed_list) async -> RDList {
        do {
            let documentSnapshot = try await Firestore.firestore().collection(listType.collectionString).document(listId).getDocument()
            return try documentSnapshot.data(as: RDList.self)
        } catch {
            print("Error getting list: \(error)")
            return RDList()
        }
    }
}
