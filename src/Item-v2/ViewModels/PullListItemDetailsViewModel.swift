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

	var itemToMove: ItemV2?

	// MARK: - Properties

	let itemState: ItemV2
    let room: RoomV2
	let rooms: [RoomV2]
    let list: PullListV2

	// MARK: - Initialization

	init(
        item: ItemV2,
        room: RoomV2,
        rooms: [RoomV2],
        list: PullListV2
	) {
		self.itemState = item
        self.room = room
		self.rooms = rooms
        self.list = list
	}


	// MARK: - Actions

	func initiateMove() {
		itemToMove = itemState
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
}
