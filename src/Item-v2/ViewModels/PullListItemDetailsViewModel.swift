//
//  PullListItemDetailsViewModel.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/5/26.
//

import Foundation
import Firebase

@Observable
final class PullListItemDetailsViewModel {
	// MARK: - State

	var selectedRDImage: RDImage?
	var isImageSelected = false

	var showAlert = false
	var alertMessage = ""
	var showRemoveConfirmationAlert = false
    var showQRCode = false
    var showMoveItemSheet: Bool = false
    
	var pullList: PullListV2?
	var rooms: [RoomV2] = []
	var isLoadingMoveData = false

	// MARK: - Properties

	let itemState: ItemV2
    let room: RoomV2

    private let listRepo: PullListRepository = PullListRepository()
	private let roomRepo: RoomRepository
    private let itemRepo: ItemRepository = ItemRepository()

	// MARK: - Initialization

	init(
        item: ItemV2,
        room: RoomV2
	) {
		self.itemState = item
        self.room = room
		self.roomRepo = RoomRepository(room: room)
	}


	// MARK: - Actions

    @MainActor
    func removeItemFromRoom() async -> Bool {
        let itemRepo = self.itemRepo
        let roomRepo = self.roomRepo
        let itemId = itemState.id
        let roomId = room.id

        do {
            let result = try await itemRepo.db.runTransaction { (transaction, errorPointer) -> Any? in
                do {
                    var currentRoom = try roomRepo.get(id: roomId, in: transaction)
                    currentRoom.itemIds.remove(itemId)

                    itemRepo.update(
                        id: itemId,
                        fields: [
                            ItemV2.CodingKeys.status.stringValue: ItemStatus.inStorage.rawValue,
                            ItemV2.CodingKeys.locationId.stringValue: Warehouse.warehouse1.id // TODO: should select where it should be stored
                        ],
                        in: transaction
                    )
                    roomRepo.update(
                        id: roomId,
                        fields: [RoomV2.CodingKeys.itemIds.stringValue: Array(currentRoom.itemIds)],
                        in: transaction
                    )
                } catch {
                    errorPointer?.pointee = error as NSError
                    return false
                }
                return true
            }
            return result as? Bool ?? false
        } catch {
            alertMessage = "Failed to remove item from room: \(error.localizedDescription)"
            showAlert = true
            return false
        }
    }

    // MARK: - Move Item

    func fetchRoomsForMove() async {
        guard rooms.isEmpty else { return }
        do {
            rooms = try await listRepo.getRooms(listId: room.listId)
        } catch {
            alertMessage = "Unable to fetch other rooms: \(error.localizedDescription)"
            showAlert = true
        }
    }

    func moveItemToNewRoom(newRoom: RoomV2) async {
        let itemRepo = self.itemRepo
        let roomRepo = self.roomRepo
        let item = self.itemState
        let currentRoom = self.room

        do {
            let _ = try await roomRepo.db.runTransaction { (transaction, errorPointer) -> Any? in
                do {
                    let fetchedItem = try itemRepo.get(id: item.id, in: transaction)
                    let fetchedNewRoom = try roomRepo.get(id: newRoom.id, in: transaction)
                    let fetchedCurrentRoom = try roomRepo.get(id: currentRoom.id, in: transaction)

                    guard !fetchedNewRoom.itemIds.contains(fetchedItem.id),
                          fetchedCurrentRoom.itemIds.contains(fetchedItem.id),
                          fetchedItem.locationId == fetchedCurrentRoom.listId else {
                        return nil
                    }

                    var updatedCurrentIds = fetchedCurrentRoom.itemIds
                    updatedCurrentIds.remove(fetchedItem.id)
                    var updatedNewIds = fetchedNewRoom.itemIds
                    updatedNewIds.insert(fetchedItem.id)

                    roomRepo.update(id: fetchedCurrentRoom.id, fields: [RoomV2.CodingKeys.itemIds.stringValue: updatedCurrentIds], in: transaction)
                    roomRepo.update(id: fetchedNewRoom.id, fields: [RoomV2.CodingKeys.itemIds.stringValue: updatedNewIds], in: transaction)
                    return true
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }
            }
            alertMessage = "Moved \(item.displayName) to \(newRoom.displayName)"
            showAlert = true
        } catch {
            alertMessage = "Failed to move item: \(error.localizedDescription)"
            showAlert = true
        }
    }

	// MARK: - Data Fetching

	func fetchPullListForLocation() async {
        guard itemState.status != .inStorage, itemState.status == .inPullList, pullList == nil else { return }

		do {
			pullList = try await listRepo.get(id: itemState.locationId)
		} catch {
			alertMessage = "Failed to load item location: \(error.localizedDescription)"
			showAlert = true
		}
	}
}
