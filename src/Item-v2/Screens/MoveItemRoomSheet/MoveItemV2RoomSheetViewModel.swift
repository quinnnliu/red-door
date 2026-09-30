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
    /// Which collection `room` lives in. Without it this screen would read and
    /// write the pull list subcollection for an installed list's rooms.
    let listKind: RDListKind
    var rooms: [RoomV2] = []

    var showAlert: Bool = false
    var alertMessage: String = ""

    init(item: ItemV2, room: RoomV2, listKind: RDListKind) {
        self.itemRepo = ItemRepository()
        self.room = room
        self.item = item
        self.listKind = listKind
    }

    @MainActor
    func moveItemToNewRoom(newRoom: RoomV2) async {
        do {
            let outcome: MoveItemOutcome
            switch listKind {
            case .pullList:
                outcome = try await RoomRepository<PullListV2>(room: room)
                    .moveItem(item.id, fromRoomId: room.id, toRoomId: newRoom.id, itemRepo: itemRepo)
            case .installedList:
                outcome = try await RoomRepository<InstalledListV2>(room: room)
                    .moveItem(item.id, fromRoomId: room.id, toRoomId: newRoom.id, itemRepo: itemRepo)
            }

            switch outcome {
            case .moved:
                alertMessage = "Added \(item.displayName) to \(newRoom.displayName)"
            case .stale:
                alertMessage = "Couldn't move \(item.displayName) — it already moved. Reopen the room and try again."
            }
            showAlert = true
        } catch {
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
            switch listKind {
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
