//
//  RoomRepository+PullList.swift
//  RedDoor
//
//  Created by Quinn Liu on 10/29/26.
//

import Foundation
import Firebase

// MARK: - Pull list only
extension RoomRepository where Parent == PullListV2 {

    /// Creates a room and adds it to the list's `roomIds` in one transaction.
    func createRoom(_ room: RoomV2) async throws {
        _ = try await db.runTransaction { transaction, errorPointer -> Any? in
            do {
                let list = try self.openParent(in: transaction)
                let existing = try self.get(ids: list.roomIds, transaction: transaction)
                guard !RoomV2.roomExists(newRoomName: room.displayName, rooms: existing) else {
                    throw StaleWriteError.stateChanged
                }

                try self.set(document: room, id: room.id, transaction: transaction)
                transaction.updateData(
                    [PullListV2.CodingKeys.roomIds.stringValue: FieldValue.arrayUnion([room.id])],
                    forDocument: self.parentRef
                )
                return nil
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
    }

    /// Places items already in the list's unassigned pool into a room.
    func assignUnassignedItems(
        _ itemIds: [String],
        toRoomId roomId: String,
        itemRepo: ItemRepository,
        pullListRepo: PullListRepository
    ) async throws {
        guard !itemIds.isEmpty else { return }

        _ = try await db.runTransaction { transaction, errorPointer -> Any? in
            do {
                let list = try self.openParent(in: transaction)
                _ = try self.get(id: roomId, transaction: transaction)

                let pending = itemIds.filter { list.unassignedItemIds.contains($0) }
                guard !pending.isEmpty else { throw StaleWriteError.stateChanged }

                self.update(
                    id: roomId,
                    fields: [RoomV2.CodingKeys.itemIds.stringValue: FieldValue.arrayUnion(pending)],
                    transaction: transaction
                )

                let location = DocumentLocation(status: .inPullList, locationId: self.listId).firebaseUpdateFields
                for itemId in pending {
                    itemRepo.update(id: itemId, fields: location, transaction: transaction)
                }

                pullListRepo.update(
                    id: self.listId,
                    fields: [PullListV2.CodingKeys.unassignedItemIds.stringValue: FieldValue.arrayRemove(pending)],
                    transaction: transaction
                )
                return nil
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
    }

    /// Moves an item out of a room and back into the list's unassigned pool.
    func unassignItem(
        _ itemId: String,
        fromRoomId roomId: String,
        pullListRepo: PullListRepository
    ) async throws {
        _ = try await db.runTransaction { transaction, errorPointer -> Any? in
            do {
                _ = try self.openParent(in: transaction)
                let room = try self.get(id: roomId, transaction: transaction)
                guard room.itemIds.contains(itemId) else { throw StaleWriteError.stateChanged }

                self.update(
                    id: roomId,
                    fields: [RoomV2.CodingKeys.itemIds.stringValue: FieldValue.arrayRemove([itemId])],
                    transaction: transaction
                )
                pullListRepo.update(
                    id: self.listId,
                    fields: [PullListV2.CodingKeys.unassignedItemIds.stringValue: FieldValue.arrayUnion([itemId])],
                    transaction: transaction
                )
                return nil
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
    }
}

// MARK: - Delete room

enum RoomDeleteError: LocalizedError {
    case notEmpty

    var errorDescription: String? {
        switch self {
        case .notEmpty: "Remove all items from this room before deleting it."
        }
    }
}

/// Only a pull list's rooms are deletable — an installed list's rooms are the
/// record of where things physically went.
extension RoomRepository where Parent == PullListV2 {

    /// Deletes an empty room, drops it from the list's `roomIds`, and removes
    /// its before/after images.
    func deleteRoom(id roomId: String) async throws {
        let deleted = try await db.runTransaction { transaction, errorPointer -> Any? in
            do {
                _ = try self.openParent(in: transaction)
                let room = try self.get(id: roomId, transaction: transaction)
                guard room.canDelete else { throw RoomDeleteError.notEmpty }

                self.delete(id: roomId, transaction: transaction)
                transaction.updateData(
                    [PullListV2.CodingKeys.roomIds.stringValue: FieldValue.arrayRemove([roomId])],
                    forDocument: self.parentRef
                )
                return room
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
        guard let room = deleted as? RoomV2 else { return }

        // Cleans by folder: before and after images share
        // `rooms_images/{listId}_{roomId}`. The key includes the list because a
        // copied room keeps its id, so the folder is never shared with another
        // list's room. The document is already gone, so a failure only orphans
        // files and isn't a failed delete.
        do {
            try await FirebaseImageManager.shared.deleteDocumentImages(
                ownerId: room.imageOwnerId,
                imageType: .roomBefore
            )
        } catch {
            print("[WARN]: Deleted room \(roomId) but failed to clean up its images: \(error.localizedDescription)")
        }
    }
}
