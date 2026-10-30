//
//  MoveItemV2RoomSheetViewModel.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/5/26.
//

import Foundation

@Observable
final class MoveItemV2RoomSheetViewModel {

    let itemRepo: ItemRepository

    let room: RoomV2
    let item: ItemV2
    let listType: RDListType
    var rooms: [RoomV2] = []

    var showAlert: Bool = false
    var alertMessage: String = ""
    /// A write found the list or room gone, uninstalled or changed; the view presents it.
    var staleWriteError: StaleWriteError? = nil

    init(item: ItemV2, room: RoomV2, listType: RDListType) {
        self.itemRepo = ItemRepository()
        self.room = room
        self.item = item
        self.listType = listType
    }

    @MainActor
    func moveItemToNewRoom(newRoom: RoomV2) async {
        do {
            switch listType {
            case .pullList:
                try await RoomRepository<PullListV2>(room: room)
                    .moveItem(item.id, fromRoomId: room.id, toRoomId: newRoom.id, itemRepo: itemRepo)
            case .installedList:
                try await RoomRepository<InstalledListV2>(room: room)
                    .moveItem(item.id, fromRoomId: room.id, toRoomId: newRoom.id, itemRepo: itemRepo)
            }

            alertMessage = "Added \(item.displayName) to \(newRoom.displayName)"
            showAlert = true
        } catch {
            if let stale = StaleWriteError(error) {
                staleWriteError = stale
                return
            }
            alertMessage = "Failed to add \(item.displayName) to \(newRoom.displayName)"
            showAlert = true
            print("[ERROR]: Failed to move \(item.displayName) to \(newRoom.displayName): \(error.localizedDescription)")
        }
    }

    /// Reads siblings straight out of the room's own subcollection. Going
    /// through the parent list's `roomIds` would mean knowing which list
    /// repository to ask; the scoped room repository already knows.
    @MainActor
    func fetchRoomsForMove() async {
        guard rooms.isEmpty else { return }
        do {
            switch listType {
            case .pullList:
                rooms = try await RoomRepository<PullListV2>(room: room).getAll()
            case .installedList:
                rooms = try await RoomRepository<InstalledListV2>(room: room).getAll()
            }
        } catch {
            alertMessage = "[ERROR] Unable to fetch other rooms: \(error.localizedDescription)"
            showAlert = true
        }
    }
}
