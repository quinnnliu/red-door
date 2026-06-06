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
    
    func moveItemToNewRoom() async -> Bool {
        return true
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
