//
//  InstalledListItemDetailsViewModel.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/25/26.
//

import Foundation

@Observable
final class InstalledListItemDetailsViewModel {
    // MARK: - State

    var showAlert = false
    var alertMessage = ""
    var showQRCode = false
    var showMoveItemSheet: Bool = false

    var installedList: InstalledListV2?
    var rooms: [RoomV2] = []
    var availableWarehouses: [WarehouseV2] = []
    
    var uninstalled: Bool

    // MARK: - Properties

    let itemState: ItemV2
    let room: RoomV2

    private let installedListRepo: InstalledListRepository = InstalledListRepository()
    private let roomRepo: RoomRepository
    private let itemRepo: ItemRepository = ItemRepository()

    // MARK: - Initialization

    init(
        item: ItemV2,
        room: RoomV2,
        uninstalled: Bool = false,
        roomRepo: RoomRepository
    ) {
        self.itemState = item
        self.room = room
        self.uninstalled = uninstalled
        self.roomRepo = roomRepo
    }

    // MARK: - fetchAvailableWarehouses

    func fetchAvailableWarehouses() async {
        do {
            availableWarehouses = try await ConfigurationService.shared.getAll(using: WarehouseRepository())
        } catch {
            alertMessage = "Failed to load storage locations: \(error.localizedDescription)"
            showAlert = true
        }
    }

    // MARK: - removeItemToWarehouse

    @MainActor
    func removeItemToWarehouse(warehouse: WarehouseV2) async -> Bool {
        do {
            try await roomRepo.removeItem(
                itemState.id,
                fromRoomId: room.id,
                toWarehouseId: warehouse.id,
                itemRepo: itemRepo
            )
            return true
        } catch {
            alertMessage = "Failed to remove item from room: \(error.localizedDescription)"
            showAlert = true
            return false
        }
    }

    // MARK: - fetchRoomsForMove

    func fetchRoomsForMove() async {
        guard rooms.isEmpty else { return }
        do {
            let list = try await installedListRepo.get(id: room.listId)
            rooms = try await roomRepo.get(ids: Array(list.roomIds))
        } catch {
            alertMessage = "Unable to fetch other rooms: \(error.localizedDescription)"
            showAlert = true
        }
    }

    // MARK: - moveItemToNewRoom

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

    // MARK: - fetchInstalledListForLocation

    func fetchInstalledListForLocation() async {
        guard itemState.location.status == .inInstalledList, installedList == nil else { return }
        do {
            installedList = try await installedListRepo.get(id: itemState.location.locationId)
        } catch {
            alertMessage = "Failed to load item location: \(error.localizedDescription)"
            showAlert = true
        }
    }
}
