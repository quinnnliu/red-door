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

        // Cleans by folder rather than by the stored image reference, so only
        // files this list owns are removed. The document is already gone, so a
        // failure here only orphans files and isn't worth reporting as a
        // failed delete.
        do {
            try await FirebaseImageManager.shared.deleteDocumentImages(ownerId: list.id, imageType: .listV2)
        } catch {
            print("[WARN]: Deleted pull list \(listId) but failed to clean up its images: \(error.localizedDescription)")
        }
    }
}

// MARK: - Unassigned items

extension PullListRepository {
    /// Moves items out of the list's unassigned pool into storage.
    func storeUnassignedItems(
        _ itemIds: [String],
        fromListId listId: String,
        toStorageId storageLocationId: String,
        itemRepo: ItemRepository
    ) async throws {
        guard !itemIds.isEmpty else { return }

        _ = try await db.runTransaction { transaction, errorPointer -> Any? in
            do {
                let list = try self.get(id: listId, transaction: transaction)
                let pending = itemIds.filter { list.unassignedItemIds.contains($0) }
                guard !pending.isEmpty else { throw StaleWriteError.stateChanged }

                let location = DocumentLocation(status: .inStorage, locationId: storageLocationId).firebaseUpdateFields
                for itemId in pending {
                    itemRepo.update(id: itemId, fields: location, transaction: transaction)
                }

                self.update(
                    id: listId,
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
}

// MARK: - Remove essentials group

extension PullListRepository {
    /// Sends the list's essentials group, its items and its accessories to
    /// storage, and clears the group from the list and from any room holding
    /// its items.
    func removeEssentialsGroup(
        listId: String,
        expectedGroupId: String,
        toStorageId storageLocationId: String,
        essentialsRepo: EssentialsRepository,
        accessoriesRepo: AccessoriesRepository,
        itemRepo: ItemRepository
    ) async throws -> EssentialsGroup {
        let roomRepo = RoomRepository<PullListV2>(listId: listId)

        let result = try await db.runTransaction { transaction, errorPointer -> Any? in
            do {
                let list = try self.get(id: listId, transaction: transaction)
                guard list.essentialGroupId == expectedGroupId else { throw StaleWriteError.stateChanged }
                let group = try essentialsRepo.get(id: expectedGroupId, transaction: transaction)
                let rooms = try roomRepo.get(ids: list.roomIds, transaction: transaction)

                let storageFields = DocumentLocation(
                    status: .inStorage,
                    locationId: storageLocationId
                ).firebaseUpdateFields

                for itemId in group.itemIds {
                    itemRepo.update(id: itemId, fields: storageFields, transaction: transaction)
                }
                if let accessoriesId = group.accessoriesId {
                    accessoriesRepo.update(id: accessoriesId, fields: storageFields, transaction: transaction)
                }
                essentialsRepo.update(id: group.id, fields: storageFields, transaction: transaction)

                self.update(
                    id: listId,
                    fields: [
                        PullListV2.CodingKeys.essentialGroupId.stringValue: NSNull(),
                        PullListV2.CodingKeys.unassignedItemIds.stringValue: FieldValue.arrayRemove(Array(group.itemIds))
                    ],
                    transaction: transaction
                )

                for room in rooms {
                    let overlap = room.itemIds.intersection(group.itemIds)
                    if !overlap.isEmpty {
                        roomRepo.update(
                            id: room.id,
                            fields: [RoomV2.CodingKeys.itemIds.stringValue: FieldValue.arrayRemove(Array(overlap))],
                            transaction: transaction
                        )
                    }
                }
                return group
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }

        guard let group = result as? EssentialsGroup else { throw RepositoryError.decodeFailure }
        return group
    }
}
