//
//  AddItemToRoomDetailViewModel.swift
//  RedDoor
//
//  Created by Quinn Liu on 5/30/26.
//

import Foundation
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
    @MainActor
    func addItemToRoom() async -> Bool {
        do {
            try await roomRepo.addItems(
                [item.id],
                toRoomId: room.id,
                listId: room.listId,
                itemRepo: itemRepo
            )
            alertMessage = "Added \(item.displayName) to \(room.displayName)"
            showAlert = true
            return true
        } catch {
            alertMessage = "Failed to add \(item.displayName) to \(room.displayName)"
            showAlert = true
            print("[ERROR]: Failed to add \(item.displayName) to \(room.displayName): \(error.localizedDescription)")
            return false
        }
    }
}
