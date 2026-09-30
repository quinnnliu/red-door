//
//  PullListRepository.swift
//  RedDoor
//
//  Created by Quinn Liu on 5/16/26.
//

import Firebase
import Foundation

final class PullListRepository: GenericRepository<PullListV2> {
    
    func getRooms(listId: String) async throws -> [RoomV2] {
        let roomRepo = RoomRepository(listId: listId)
        let list = try await get(id: listId)
        return try await roomRepo.get(ids: list.roomIds)
    }
    
}

// MARK: - Delete

extension PullListRepository {

    /// Deletes a pull list and its rooms.
    ///
    /// Deleting is not a relocation: callers must empty the list first, since
    /// there is nowhere for leftover items to go. See
    /// `PullListDetailsViewModelV2.isEmptyOfItems`.
    ///
    /// `rooms` is passed in because the write can't discover them itself:
    /// neither a batch nor a transaction can run a subcollection query.
    func delete(
        _ listId: String,
        rooms: [RoomV2],
        roomRepo: RoomRepository
    ) async throws {
        let batch = newBatch()

        for room in rooms {
            roomRepo.delete(id: room.id, inBatch: batch)
        }

        delete(id: listId, inBatch: batch)

        try await batch.commit()
    }
}

// MARK: - Unassigned items

extension PullListRepository {

    /// Moves items out of a list's unassigned pool and into storage.
    /// Mirrors `RoomRepository.removeItem`, minus the room membership write:
    /// unassigned items belong to no room.
    func storeUnassignedItems(
        _ itemIds: [String],
        fromListId listId: String,
        toStorageId storageLocationId: String,
        itemRepo: ItemRepository
    ) async throws {
        guard !itemIds.isEmpty else { return }

        let batch = newBatch()

        let location = DocumentLocation(status: .inStorage, locationId: storageLocationId).firebaseUpdateFields
        for itemId in itemIds {
            itemRepo.update(id: itemId, fields: location, inBatch: batch)
        }

        update(
            id: listId,
            fields: [PullListV2.CodingKeys.unassignedItemIds.stringValue: FieldValue.arrayRemove(itemIds)],
            inBatch: batch
        )

        try await batch.commit()
    }
}
