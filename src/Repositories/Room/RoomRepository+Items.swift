//
//  RoomRepository+Items.swift
//  RedDoor
//
//  Created by Quinn Liu on 10/29/26.
//

import Foundation
import Firebase

// MARK: - Move item

extension RoomRepository {

    /// Moves an item between two rooms of the same list.
    func moveItem(
        _ itemId: String,
        fromRoomId: String,
        toRoomId: String,
        itemRepo: ItemRepository
    ) async throws {
        _ = try await db.runTransaction { transaction, errorPointer -> Any? in
            do {
                _ = try self.openParent(in: transaction)
                let item = try itemRepo.get(id: itemId, transaction: transaction)
                let fromRoom = try self.get(id: fromRoomId, transaction: transaction)
                let toRoom = try self.get(id: toRoomId, transaction: transaction)

                guard fromRoom.itemIds.contains(itemId),
                      !toRoom.itemIds.contains(itemId),
                      item.location.locationId == fromRoom.listId else {
                    throw StaleWriteError.stateChanged
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
                return nil
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
    }
}

// MARK: - Add items

extension RoomRepository {

    /// Adds in-storage items to a room and points their location at this list.
    func addItems(
        _ itemIds: [String],
        toRoomId roomId: String,
        itemRepo: ItemRepository
    ) async throws {
        guard !itemIds.isEmpty else { return }

        _ = try await db.runTransaction { transaction, errorPointer -> Any? in
            do {
                // Reads first — Firestore requires every read to precede every write.
                _ = try self.openParent(in: transaction)

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
        _ = try await db.runTransaction { transaction, errorPointer -> Any? in
            do {
                _ = try self.openParent(in: transaction)
                let room = try self.get(id: roomId, transaction: transaction)
                let item = try itemRepo.get(id: itemId, transaction: transaction)

                guard room.itemIds.contains(itemId),
                      item.location.locationId == self.listId else {
                    throw StaleWriteError.stateChanged
                }

                itemRepo.update(
                    id: itemId,
                    fields: DocumentLocation(status: .inStorage, locationId: storageLocationId).firebaseUpdateFields,
                    transaction: transaction
                )
                self.update(
                    id: roomId,
                    fields: [RoomV2.CodingKeys.itemIds.stringValue: FieldValue.arrayRemove([itemId])],
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
