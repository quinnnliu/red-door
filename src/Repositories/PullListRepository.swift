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

enum PullListDeleteError: LocalizedError {
    case notEmpty

    var errorDescription: String? {
        switch self {
        case .notEmpty: "Remove all rooms, items and any essentials group before deleting this pull list."
        }
    }
}

extension PullListRepository {
    func delete(_ listId: String) async throws {
        let roomRepo = RoomRepository<PullListV2>(listId: listId)
        let roomRefs = try await roomRepo.collectionRef.getDocuments().documents.map(\.reference)
        let sessionRef = db.collection(InstallSession.collectionPath).document(listId)

        let deleted = try await db.runTransaction { transaction, errorPointer -> Any? in
            do {
                let list = try self.get(id: listId, transaction: transaction)
                guard list.canDelete else { throw PullListDeleteError.notEmpty }

                for ref in roomRefs {
                    transaction.deleteDocument(ref)
                }
                transaction.deleteDocument(sessionRef)
                self.delete(id: listId, transaction: transaction)
                return list
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
        guard let list = deleted as? PullListV2 else { return }

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
