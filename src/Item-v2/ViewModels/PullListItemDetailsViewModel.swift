//
//  PullListItemDetailsViewModel.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/5/26.
//

import Foundation

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

	private let listRepo = PullListRepository()
	private let roomRepo: RoomRepository?

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

	func initiateMove() {
        showMoveItemSheet = true
	}

	func initiateRemoval() {
		showRemoveConfirmationAlert = true
	}

	func showRemovalSuccess() {
        alertMessage = "Item has been removed from \(room.displayName)."
		showAlert = true
	}

    func removeItemFromRoom() async -> Bool {
        return true
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
