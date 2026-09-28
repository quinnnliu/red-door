//
//  RoomRepository.swift
//  RedDoor
//
//  Created by Quinn Liu on 5/16/26.
//

import Foundation
import Firebase

final class RoomRepository: GenericRepository<RoomV2> {
    // MARK: PullList init
    convenience init(
        db: Firestore = Firestore.firestore(),
        list: PullListV2
    ) {
        self.init(db: db, parentCollectionName: PullListV2.collectionName, listId: list.id)
    }

    // MARK: ListId init
    convenience init(
        db: Firestore = Firestore.firestore(),
        listId: String
    ) {
        self.init(db: db, parentCollectionName: PullListV2.collectionName, listId: listId)
    }

    // MARK: Room init

    convenience init(
        db: Firestore = Firestore.firestore(),
        room: RoomV2
    ) {
        self.init(db: db, parentCollectionName: PullListV2.collectionName, listId: room.listId)
    }

    // MARK: Generic parent collection init

    init(
        db: Firestore = Firestore.firestore(),
        parentCollectionName: String,
        listId: String
    ) {
        super.init(
            db: db,
            collectionRef: db
                .collection(parentCollectionName)
                .document(listId)
                .collection(RoomV2.collectionName)
        )
    }
}

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

// MARK: - Move item

extension RoomRepository {

    enum MoveItemOutcome: Equatable {
        case moved
        /// Someone else changed the item or either room first. A normal outcome
        /// of two people working one list, not an error.
        case stale
    }

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

    /// Adds in-storage items to a room and points their location at the list.
    ///
    /// Re-reads the room and the items inside the transaction, so two people
    /// adding from stale inventory lists can't double-assign one item. Throws
    /// `ItemAssignmentError.noEligibleItems` when none of them can be added.
    func addItems(
        _ itemIds: [String],
        toRoomId roomId: String,
        listId: String,
        itemRepo: ItemRepository
    ) async throws {
        guard !itemIds.isEmpty else { return }

        _ = try await db.runTransaction { transaction, errorPointer -> Any? in
            do {
                let room = try self.get(id: roomId, transaction: transaction)
                let items = try itemRepo.get(ids: itemIds, transaction: transaction)
                let eligible = try ItemAssignmentError.eligibleItems(from: items, alreadyIn: room.itemIds)

                self.update(
                    id: roomId,
                    fields: [RoomV2.CodingKeys.itemIds.stringValue: Array(room.itemIds.union(eligible.map(\.id)))],
                    transaction: transaction
                )

                let location = DocumentLocation(status: .inPullList, locationId: listId).firebaseUpdateFields
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

    /// Places items already in the list's unassigned pool into a room.
    ///
    /// Separate from `addItems` on purpose: these items are already
    /// `.inPullList`, so the in-storage eligibility check doesn't apply.
    func assignUnassignedItems(
        _ itemIds: [String],
        toRoomId roomId: String,
        listId: String,
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
}

// MARK: - Remove item

extension RoomRepository {

    /// Moves an item out of a room and into storage.
    ///
    /// A batch with `arrayRemove` rather than a transaction: nothing here is
    /// conditional, so reading the room back to rewrite its whole `itemIds`
    /// array would only add a round trip and a window to erase whatever
    /// someone else added in the meantime.
    func removeItem(
        _ itemId: String,
        fromRoomId roomId: String,
        toWarehouseId warehouseId: String,
        itemRepo: ItemRepository
    ) async throws {
        let batch = newBatch()

        itemRepo.update(
            id: itemId,
            fields: DocumentLocation(status: .inStorage, locationId: warehouseId).firebaseUpdateFields,
            inBatch: batch
        )
        update(
            id: roomId,
            fields: [RoomV2.CodingKeys.itemIds.stringValue: FieldValue.arrayRemove([itemId])],
            inBatch: batch
        )

        try await batch.commit()
    }

    /// Moves an item out of a room and back into the list's unassigned pool.
    /// Its location still points at the list, so only membership changes.
    func unassignItem(
        _ itemId: String,
        fromRoomId roomId: String,
        listId: String,
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
