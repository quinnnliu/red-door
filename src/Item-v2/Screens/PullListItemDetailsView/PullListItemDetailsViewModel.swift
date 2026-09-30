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

	var showAlert = false
	var alertMessage = ""
    var showQRCode = false
    var showMoveItemSheet: Bool = false

	var pullList: PullListV2?
	var rooms: [RoomV2] = []
	var availableStorageLocations: [StorageLocation] = []
	var isLoadingMoveData = false

	// MARK: - Properties

	let itemState: ItemV2
    let room: RoomV2

    private let listRepo: PullListRepository = PullListRepository()
	private let roomRepo: RoomRepository<PullListV2>
    private let itemRepo: ItemRepository = ItemRepository()

	// MARK: - Initialization

	init(
        item: ItemV2,
        room: RoomV2
	) {
		self.itemState = item
        self.room = room
		self.roomRepo = RoomRepository<PullListV2>(room: room)
	}


	// MARK: - Actions

    func fetchAvailableStorageLocations() async {
        do {
            availableStorageLocations = try await ConfigurationService.shared.getAll(using: StorageLocationRepository())
        } catch {
            alertMessage = "Failed to load storage locations: \(error.localizedDescription)"
            showAlert = true
        }
    }

    // MARK: - removeItemToStorage

    @MainActor
    func removeItemToStorage(storageLocation: StorageLocation) async -> Bool {
        do {
            try await roomRepo.removeItem(
                itemState.id,
                fromRoomId: room.id,
                toStorageLocationId: storageLocation.id,
                itemRepo: itemRepo
            )
            return true
        } catch {
            alertMessage = "Failed to remove item from room: \(error.localizedDescription)"
            showAlert = true
            return false
        }
    }

    // MARK: - moveItemToUnassigned

    @MainActor
    func moveItemToUnassigned() async -> Bool {
        do {
            try await roomRepo.unassignItem(
                itemState.id,
                fromRoomId: room.id,
                pullListRepo: listRepo
            )
            return true
        } catch {
            alertMessage = "Failed to unassign item: \(error.localizedDescription)"
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

    @MainActor
    func moveItemToNewRoom(newRoom: RoomV2) async {
        do {
            let outcome = try await roomRepo.moveItem(
                itemState.id,
                fromRoomId: room.id,
                toRoomId: newRoom.id,
                itemRepo: itemRepo
            )
            switch outcome {
            case .moved:
                alertMessage = "Moved \(itemState.displayName) to \(newRoom.displayName)"
            case .stale:
                alertMessage = "Couldn't move \(itemState.displayName) — it already moved. Reopen the room and try again."
            }
            showAlert = true
        } catch {
            alertMessage = "Failed to move item: \(error.localizedDescription)"
            showAlert = true
        }
    }

	// MARK: - Data Fetching

	func fetchPullListForLocation() async {
        guard itemState.location.status != .inStorage, itemState.location.status == .inPullList, pullList == nil else { return }

		do {
			pullList = try await listRepo.get(id: itemState.location.locationId)
		} catch {
			alertMessage = "Failed to load item location: \(error.localizedDescription)"
			showAlert = true
		}
	}
}
