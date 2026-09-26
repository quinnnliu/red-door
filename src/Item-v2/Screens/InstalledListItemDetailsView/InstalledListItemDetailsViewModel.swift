//
//  InstalledListItemDetailsViewModel.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/25/26.
//

import Foundation
import Firebase

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

    // MARK: - Properties

    let itemState: ItemV2
    let room: RoomV2

    private let installedListRepo: InstalledListRepository = InstalledListRepository()
    private let roomRepo: RoomRepository
    private let itemRepo: ItemRepository = ItemRepository()

    // MARK: - Initialization

    init(item: ItemV2, room: RoomV2, roomRepo: RoomRepository) {
        self.itemState = item
        self.room = room
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
        let itemRepo = self.itemRepo
        let roomRepo = self.roomRepo
        let itemId = itemState.id
        let roomId = room.id

        do {
            let result = try await itemRepo.db.runTransaction { (transaction, errorPointer) -> Any? in
                do {
                    var currentRoom = try roomRepo.get(id: roomId, transaction: transaction)
                    currentRoom.itemIds.remove(itemId)

                    guard let storageLocationData = try? Firestore.Encoder().encode(
                        DocumentLocation(status: .inStorage, locationId: warehouse.id)
                    ) else { return false }

                    itemRepo.update(
                        id: itemId,
                        fields: [ItemV2.CodingKeys.location.stringValue: storageLocationData],
                        transaction: transaction
                    )
                    roomRepo.update(
                        id: roomId,
                        fields: [RoomV2.CodingKeys.itemIds.stringValue: Array(currentRoom.itemIds)],
                        transaction: transaction
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

    func moveItemToNewRoom(newRoom: RoomV2) async {
        let itemRepo = self.itemRepo
        let roomRepo = self.roomRepo
        let item = self.itemState
        let currentRoom = self.room

        do {
            let _ = try await roomRepo.db.runTransaction { (transaction, errorPointer) -> Any? in
                do {
                    let fetchedItem = try itemRepo.get(id: item.id, transaction: transaction)
                    let fetchedNewRoom = try roomRepo.get(id: newRoom.id, transaction: transaction)
                    let fetchedCurrentRoom = try roomRepo.get(id: currentRoom.id, transaction: transaction)

                    guard !fetchedNewRoom.itemIds.contains(fetchedItem.id),
                          fetchedCurrentRoom.itemIds.contains(fetchedItem.id) else {
                        return nil
                    }

                    var updatedCurrentIds = fetchedCurrentRoom.itemIds
                    updatedCurrentIds.remove(fetchedItem.id)
                    var updatedNewIds = fetchedNewRoom.itemIds
                    updatedNewIds.insert(fetchedItem.id)

                    roomRepo.update(id: fetchedCurrentRoom.id, fields: [RoomV2.CodingKeys.itemIds.stringValue: Array(updatedCurrentIds)], transaction: transaction)
                    roomRepo.update(id: fetchedNewRoom.id, fields: [RoomV2.CodingKeys.itemIds.stringValue: Array(updatedNewIds)], transaction: transaction)
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
