//
//  RoomRepository.swift
//  RedDoor
//
//  Created by Quinn Liu on 5/16/26.
//

import Foundation
import Firebase

/// Rooms of a single list, generic over which kind of list that is.
///
/// `RoomV2` documents are identical in `pull_list_v2` and `installed_list_v2`,
/// so nothing on the room itself says which collection it came from. Carrying
/// the parent as a type parameter means the collection path and the
/// `LocationStatus` an added item receives are both derived from one source,
/// and a room can't be read from one list's subcollection and written to the
/// other's.
final class RoomRepository<Parent: RDListDocument>: GenericRepository<RoomV2> {

    /// Retained so writes that touch the parent list don't have to be handed
    /// the ID they already implied by constructing this repository.
    let listId: String

    // MARK: ListId init

    init(db: Firestore = Firestore.firestore(), listId: String) {
        self.listId = listId
        super.init(
            db: db,
            collectionRef: db
                .collection(Parent.collectionPath)
                .document(listId)
                .collection(RoomV2.collectionName)
        )
    }

    // MARK: List init

    convenience init(db: Firestore = Firestore.firestore(), list: Parent) {
        self.init(db: db, listId: list.id)
    }

    // MARK: Room init

    convenience init(db: Firestore = Firestore.firestore(), room: RoomV2) {
        self.init(db: db, listId: room.listId)
    }

    /// The parent list document, for guards that need its live state.
    fileprivate var parentRef: DocumentReference {
        db.collection(Parent.collectionPath).document(listId)
    }
}

// MARK: - Listeners

extension RoomRepository {
    func addRoomListener(
        roomId: String,
        onChange: @escaping (Result<RoomV2, Error>) -> Void
    ) -> ListenerRegistration {
        addDocumentListener(id: roomId, onChange: onChange)
    }

    func addRoomsListener(
        onChange: @escaping (Result<[RoomV2], Error>) -> Void
    ) -> ListenerRegistration {
        addCollectionListener(onChange: onChange)
    }
}

// MARK: - MoveItemOutcome

/// File-scope rather than nested in `RoomRepository`, so callers that switch on
/// it don't have to name a generic parameter they don't otherwise care about.
enum MoveItemOutcome: Equatable {
    case moved
    /// Someone else changed the item or either room first. A normal outcome
    /// of two people working one list, not an error.
    case stale
}

// MARK: - Move item

extension RoomRepository {

    /// Moves an item between two rooms of the same list.
    ///
    /// Re-reads the item and both rooms inside the transaction rather than
    /// trusting the caller's copies, so a sheet left open while someone else
    /// moved the same item can't corrupt either room's membership.
    func moveItem(
        _ itemId: String,
        fromRoomId: String,
        toRoomId: String,
        itemRepo: ItemRepository
    ) async throws -> MoveItemOutcome {
        let result = try await db.runTransaction { transaction, errorPointer -> Any? in
            do {
                let item = try itemRepo.get(id: itemId, transaction: transaction)
                let fromRoom = try self.get(id: fromRoomId, transaction: transaction)
                let toRoom = try self.get(id: toRoomId, transaction: transaction)

                guard fromRoom.itemIds.contains(itemId),
                      !toRoom.itemIds.contains(itemId),
                      item.location.locationId == fromRoom.listId else {
                    return false
                }

                self.update(
                    id: fromRoom.id,
                    fields: [RoomV2.CodingKeys.itemIds.stringValue: Array(fromRoom.itemIds.subtracting([itemId]))],
                    transaction: transaction
                )
                self.update(
                    id: toRoom.id,
                    fields: [RoomV2.CodingKeys.itemIds.stringValue: Array(toRoom.itemIds.union([itemId]))],
                    transaction: transaction
                )
                return true
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }

        return result as? Bool == true ? .moved : .stale
    }
}

// MARK: - Add items

extension RoomRepository {

    /// Adds in-storage items to a room and points their location at this list.
    ///
    /// Re-reads the parent list, the room, and the items inside the transaction,
    /// so two people adding from stale inventory lists can't double-assign one
    /// item and a list that closed mid-flow can't still be written to. Throws
    /// `ItemAssignmentError.noEligibleItems` when none of them can be added, or
    /// `.destinationClosed` when the list no longer accepts items.
    func addItems(
        _ itemIds: [String],
        toRoomId roomId: String,
        itemRepo: ItemRepository
    ) async throws {
        guard !itemIds.isEmpty else { return }

        _ = try await db.runTransaction { transaction, errorPointer -> Any? in
            do {
                // Reads first — Firestore requires every read to precede every write.
                let parent = try transaction.getDocument(self.parentRef).data(as: Parent.self)
                guard parent.acceptsNewItems else {
                    throw ItemAssignmentError.destinationClosed(name: parent.displayName)
                }

                let room = try self.get(id: roomId, transaction: transaction)
                let items = try itemRepo.get(ids: itemIds, transaction: transaction)
                let eligible = try ItemAssignmentError.eligibleItems(from: items, alreadyIn: room.itemIds)

                self.update(
                    id: roomId,
                    fields: [RoomV2.CodingKeys.itemIds.stringValue: Array(room.itemIds.union(eligible.map(\.id)))],
                    transaction: transaction
                )

                let location = DocumentLocation(
                    status: Parent.itemLocationStatus,
                    locationId: self.listId
                ).firebaseUpdateFields
                for item in eligible {
                    itemRepo.update(id: item.id, fields: location, transaction: transaction)
                }

                return nil
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
    }
}

// MARK: - Remove item

extension RoomRepository {

    /// Moves an item out of a room and into storage.
    func removeItem(
        _ itemId: String,
        fromRoomId roomId: String,
        toStorageLocationId storageLocationId: String,
        itemRepo: ItemRepository
    ) async throws {
        let batch = newBatch()

        itemRepo.update(
            id: itemId,
            fields: DocumentLocation(status: .inStorage, locationId: storageLocationId).firebaseUpdateFields,
            inBatch: batch
        )
        update(
            id: roomId,
            fields: [RoomV2.CodingKeys.itemIds.stringValue: FieldValue.arrayRemove([itemId])],
            inBatch: batch
        )

        try await batch.commit()
    }
}

// MARK: - Unassigned pool

/// Only a pull list has an unassigned pool — an installed list's rooms are the
/// record of where things physically went, so there is nowhere for an
/// unplaced item to sit. Constraining these to `PullListV2` keeps them from
/// being reachable on the installed side at all.
extension RoomRepository where Parent == PullListV2 {

    /// Places items already in the list's unassigned pool into a room.
    ///
    /// Separate from `addItems` on purpose: these items are already
    /// `.inPullList`, so the in-storage eligibility check doesn't apply.
    func assignUnassignedItems(
        _ itemIds: [String],
        toRoomId roomId: String,
        itemRepo: ItemRepository,
        pullListRepo: PullListRepository
    ) async throws {
        guard !itemIds.isEmpty else { return }

        let batch = newBatch()

        update(
            id: roomId,
            fields: [RoomV2.CodingKeys.itemIds.stringValue: FieldValue.arrayUnion(itemIds)],
            inBatch: batch
        )

        let location = DocumentLocation(status: .inPullList, locationId: listId).firebaseUpdateFields
        for itemId in itemIds {
            itemRepo.update(id: itemId, fields: location, inBatch: batch)
        }

        pullListRepo.update(
            id: listId,
            fields: [PullListV2.CodingKeys.unassignedItemIds.stringValue: FieldValue.arrayRemove(itemIds)],
            inBatch: batch
        )

        try await batch.commit()
    }

    /// Moves an item out of a room and back into the list's unassigned pool.
    /// Its location still points at the list, so only membership changes.
    func unassignItem(
        _ itemId: String,
        fromRoomId roomId: String,
        pullListRepo: PullListRepository
    ) async throws {
        let batch = newBatch()

        update(
            id: roomId,
            fields: [RoomV2.CodingKeys.itemIds.stringValue: FieldValue.arrayRemove([itemId])],
            inBatch: batch
        )
        pullListRepo.update(
            id: listId,
            fields: [PullListV2.CodingKeys.unassignedItemIds.stringValue: FieldValue.arrayUnion([itemId])],
            inBatch: batch
        )

        try await batch.commit()
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
    ///
    /// Re-reads the room inside the transaction so an item added from another
    /// device after the caller last looked still blocks the delete. Throws
    /// `RoomDeleteError.notEmpty` in that case.
    func deleteRoom(id roomId: String) async throws {
        let deleted = try await db.runTransaction { transaction, errorPointer -> Any? in
            do {
                let room = try self.get(id: roomId, transaction: transaction)
                guard room.itemIds.isEmpty else { throw RoomDeleteError.notEmpty }

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

        // Cleans by folder: before and after images share `rooms_images/{roomId}`,
        // and a room copied from an installed list starts with no images, so
        // nothing here is shared with another room. The document is already
        // gone, so a failure only orphans files and isn't a failed delete.
        do {
            try await FirebaseImageManager.shared.deleteDocumentImages(
                document: room,
                imageType: .roomBefore
            )
        } catch {
            print("[WARN]: Deleted room \(roomId) but failed to clean up its images: \(error.localizedDescription)")
        }
    }
}
