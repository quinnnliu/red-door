//
//  MoveItemV2RoomSheetViewModel.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/5/26.
//

import Foundation

@Observable
final class MoveItemV2RoomSheetViewModel {
    
    let roomRepo: RoomRepository
    let itemRepo: ItemRepository
    let listRepo: PullListRepository
    
    let room: RoomV2
    let item: ItemV2
    var rooms: [RoomV2] = []
    
    var showAlert: Bool = false
    var alertMessage: String = ""
    
    init(item: ItemV2, room: RoomV2) {
        self.roomRepo = RoomRepository(room: room)
        self.itemRepo = ItemRepository()
        self.listRepo = PullListRepository()
        self.room = room
        self.item = item
    }
    
    @MainActor
    func moveItemToNewRoom(newRoom: RoomV2) async {
        do {
            let outcome = try await roomRepo.moveItem(
                item.id,
                fromRoomId: room.id,
                toRoomId: newRoom.id,
                itemRepo: itemRepo
            )
            switch outcome {
            case .moved:
                alertMessage = "Added \(item.displayName) to \(newRoom.displayName)"
            case .stale:
                alertMessage = "Couldn't move \(item.displayName) — it already moved. Reopen the room and try again."
            }
            showAlert = true
        } catch {
            alertMessage = "Failed to add \(item.displayName) to \(newRoom.displayName)"
            showAlert = true
            print("[ERROR]: Failed to move \(item.displayName) to \(newRoom.displayName): \(error.localizedDescription)")
        }
    }

    @MainActor
    func fetchRoomsForMove() async {
        if rooms.isEmpty {
            do {
                async let fetchedRooms = listRepo.getRooms(listId: room.listId)
                rooms = try await fetchedRooms
            } catch {
                alertMessage = "[ERROR] Unable to fetch other rooms in pull list: \(error.localizedDescription)"
                showAlert = true
            }
        } else {
           return
        }
    }
}
