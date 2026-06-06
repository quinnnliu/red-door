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
    
    init(room: RoomV2) {
        guard let roomRepo = RoomRepository(room: room) else {
            fatalError("[ERROR] Unable to create RoomRepository with room: \(room.displayName)")
        }
        self.roomRepo = roomRepo
        self.itemRepo = ItemRepository()
    }
    
    func moveItemToNewRoom(item: ItemV2) async -> Bool {
        return true
    }
}
