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
    
    func moveItemToNewRoom(newRoom: RoomV2) async {
        do {
            let _ = try await roomRepo.db.runTransaction({ (transaction, errorPointer) -> Any? in
                do {
                    let fetchedItem = try self.itemRepo.get(id: self.item.id, in: transaction)
                    let fetchedNewRoom = try self.roomRepo.get(id: newRoom.id, in: transaction)
                    let fetchedCurrentRoom = try self.roomRepo.get(id: self.room.id, in: transaction)
                    
                    // TODO: better error handling
                    guard !fetchedNewRoom.itemIds.contains(fetchedItem.id),
                          fetchedCurrentRoom.itemIds.contains(fetchedItem.id),
                          fetchedItem.locationId == fetchedCurrentRoom.listId else {
                        self.alertMessage = "Failed to add \(self.item.displayName) to \(self.room.displayName)"
                        self.showAlert = true
                        print("[ERROR]: Failed to add \(self.item.displayName) to \(self.room.displayName): validation error, item is in stale state")
                        return
                    }
                    
                    var updatedCurrentRoomItemIds = fetchedCurrentRoom.itemIds
                    updatedCurrentRoomItemIds.remove(fetchedItem.id)
                    
                    var updatedNewRoomItemIds = fetchedNewRoom.itemIds
                    updatedNewRoomItemIds.insert(fetchedItem.id)
                    
                    self.roomRepo.update(
                        id: fetchedCurrentRoom.id,
                        fields: [RoomV2.CodingKeys.itemIds.stringValue: updatedCurrentRoomItemIds],
                        in: transaction
                    )
                    self.roomRepo.update(
                        id: fetchedNewRoom.id,
                        fields: [RoomV2.CodingKeys.itemIds.stringValue: updatedNewRoomItemIds],
                        in: transaction
                    )
                    return true
                } catch {
                    errorPointer?.pointee = error as NSError
                    return false
                }
            })
            
        } catch {
            alertMessage = "Failed to add \(item.displayName) to \(room.displayName)"
            showAlert = true
            print("[ERROR]: Failed to add \(item.displayName) to \(room.displayName): \(error.localizedDescription)")
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
