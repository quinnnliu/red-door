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
        let roomRepo = RoomRepository<PullListV2>(listId: listId)
        let list = try await get(id: listId)
        return try await roomRepo.get(ids: list.roomIds)
    }
    
}

// MARK: - Delete

extension PullListRepository {

    /// Deletes an empty pull list and its image.
    ///
    /// Deleting is not a relocation: callers must empty the list first, since
    /// there is nowhere for leftover rooms or items to go. See
    /// `PullListDetailsViewModelV2.canDelete`.
    func delete(_ listId: String) async throws {
        let list = try await get(id: listId)
        try await delete(id: listId)

        // Cleans by folder rather than by the stored image reference: a list
        // copied from an installed list inherits that list's reference, whose
        // files live in another folder and must survive this delete. The
        // document is already gone, so a failure here only orphans files and
        // isn't worth reporting as a failed delete.
        do {
            try await FirebaseImageManager.shared.deleteDocumentImages(document: list, imageType: .listV2)
        } catch {
            print("[WARN]: Deleted pull list \(listId) but failed to clean up its images: \(error.localizedDescription)")
        }
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
