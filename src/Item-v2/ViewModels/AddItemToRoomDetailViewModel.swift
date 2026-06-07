//
//  AddItemToRoomDetailViewModel.swift
//  RedDoor
//
//  Created by Quinn Liu on 5/30/26.
//

import Foundation
import FirebaseFirestore
import SwiftUI

@Observable
final class AddItemToRoomDetailViewModel {
    let roomRepo: RoomRepository
    let itemRepo: ItemRepository = .init()
    var room: RoomV2
    let item: ItemV2
    
    var isLoading: Bool = false
    
    var selectedRDImage: RDImage?
    var isImageSelected: Bool = false
    var alertMessage: String = ""
    var showAlert: Bool = false
    
    init(
        item: ItemV2,
        room: RoomV2
    ) {
        self.roomRepo = RoomRepository(room: room)
        self.room = room
        self.item = item
    }
}

extension AddItemToRoomDetailViewModel {
    func addItemToRoom() async {
        do {
            let _ = try await roomRepo.db.runTransaction({ (transaction, errorPointer) -> Any? in
                do {
                    let currentRoom = try self.roomRepo.get(id: self.room.id, in: transaction)
                    let newItemIds: [String] = Array(currentRoom.itemIds.union([self.item.id]))
                    
                    self.roomRepo.update(
                        id: self.room.id,
                        fields: [RoomV2.CodingKeys.itemIds.stringValue: newItemIds],
                        in: transaction
                    )
                    self.itemRepo.update(
                        id: self.item.id,
                        fields: [
                            ItemV2.CodingKeys.status.stringValue: ItemStatus.inPullList.rawValue,
                            ItemV2.CodingKeys.locationId.stringValue: self.room.listId
                        ],
                        in: transaction
                    )
                    return nil
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }
            })
            alertMessage = "Added \(item.name) to \(room.displayName)"
            showAlert = true
        } catch {
            alertMessage = "Failed to add \(item.name) to \(room.displayName)"
            showAlert = true
            print("[ERROR]: Failed to add \(item.name) to \(room.displayName): \(error.localizedDescription)")
        }
    }
}
