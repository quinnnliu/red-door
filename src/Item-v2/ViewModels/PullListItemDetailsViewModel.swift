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
                            ItemV2.CodingKeys.isAvailable.stringValue: true,
                            ItemV2.CodingKeys.listId.stringValue: NSNull()
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

	// MARK: - Data Fetching

	func fetchPullListForLocation() async {
		guard let listId = itemState.listId else { return }
        guard pullList == nil else { return }

		do {
			pullList = try await listRepo.get(id: listId)
		} catch {
			alertMessage = "Failed to load item location: \(error.localizedDescription)"
			showAlert = true
		}
	}
}
