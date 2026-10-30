//
//  EssentialsRepository.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/13/26.
//

import Firebase

final class EssentialsGroupTypeRepository: GenericRepository<EssentialsGroupType> {}

enum EssentialsGroupDeleteError: LocalizedError {
    case hasItems
    case hasAccessories
    case assignedToList

    var errorDescription: String? {
        switch self {
        case .hasItems: "Remove all items from this group before deleting it."
        case .hasAccessories: "Remove the accessories from this group before deleting it."
        case .assignedToList: "Remove this group from its list before deleting it."
        }
    }
}

enum EssentialsAssignError: LocalizedError {
    case notInStorage(names: [String])

    var errorDescription: String? {
        switch self {
        case .notInStorage(let names):
            "The following are not in storage and cannot be assigned:\n\n"
                + names.map { "• \($0)" }.joined(separator: "\n")
        }
    }
}

final class EssentialsRepository: GenericRepository<EssentialsGroup> {
    func addItem(_ itemId: String, toGroup groupId: String) async throws {
        try await update(id: groupId, fields: [
            EssentialsGroup.CodingKeys.itemIds.stringValue: FieldValue.arrayUnion([itemId])
        ])
    }

    func removeItem(_ itemId: String, fromGroup groupId: String) async throws {
        try await update(id: groupId, fields: [
            EssentialsGroup.CodingKeys.itemIds.stringValue: FieldValue.arrayRemove([itemId])
        ])
    }

    func addItem(_ itemId: String, toGroup groupId: String, inBatch batch: WriteBatch) {
        update(id: groupId, fields: [
            EssentialsGroup.CodingKeys.itemIds.stringValue: FieldValue.arrayUnion([itemId])
        ], inBatch: batch)
    }

    func removeItem(_ itemId: String, fromGroup groupId: String, inBatch batch: WriteBatch) {
        update(id: groupId, fields: [
            EssentialsGroup.CodingKeys.itemIds.stringValue: FieldValue.arrayRemove([itemId])
        ], inBatch: batch)
    }

    func updateEmoji(_ newEmoji: String, forTypeId typeId: String) async throws {
        let snapshot = try await collectionRef
            .whereField(EssentialsGroup.CodingKeys.essentialsTypeId.stringValue, isEqualTo: typeId)
            .getDocuments()
        let batch = db.batch()
        for doc in snapshot.documents {
            batch.updateData([EssentialsGroup.CodingKeys.emoji.stringValue: newEmoji], forDocument: doc.reference)
        }
        try await batch.commit()
    }

    func maxGroupNumber(forTypeId typeId: String) async -> Int {
        do {
            return try await maxNumber(
                filteredBy: EssentialsGroup.CodingKeys.essentialsTypeId.stringValue,
                equalTo: typeId,
                numberField: EssentialsGroup.CodingKeys.groupNumber.stringValue
            )
        } catch {
            print("error getting max number: \(error)")
            return 0
        }
    }
}

// MARK: - Add items

extension EssentialsRepository {

    /// Adds in-storage items to a group and tags them with the group.
    ///
    /// Re-reads the group and the items inside the transaction. Throws
    /// `ItemAssignmentError.noEligibleItems` when none of them can be added.
    func addItems(
        _ itemIds: [String],
        toGroupId groupId: String,
        itemRepo: ItemRepository
    ) async throws {
        guard !itemIds.isEmpty else { return }

        _ = try await db.runTransaction { transaction, errorPointer -> Any? in
            do {
                let group = try self.get(id: groupId, transaction: transaction)
                let items = try itemRepo.get(ids: itemIds, transaction: transaction)
                let eligible = try ItemAssignmentError.eligibleItems(from: items, alreadyIn: group.itemIds)

                self.update(
                    id: groupId,
                    fields: [EssentialsGroup.CodingKeys.itemIds.stringValue: Array(group.itemIds.union(eligible.map(\.id)))],
                    transaction: transaction
                )

                for item in eligible {
                    itemRepo.update(
                        id: item.id,
                        fields: [ItemV2.CodingKeys.essentialGroupId.stringValue: groupId],
                        transaction: transaction
                    )
                }

                return nil
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
    }

    // MARK: - Assign to pull list

    /// Places a group, its items and its accessories into a pull list.
    ///
    /// Re-reads the list, the group, every item and the accessories inside the
    /// transaction, so the "everything is in storage" check is made against
    /// current locations, not the ones the screen loaded. Throws
    /// `EssentialsAssignError.notInStorage` naming whatever is unavailable,
    /// `StaleWriteError.stateChanged` when the group or the list was assigned
    /// first, and `.documentGone` when the list was installed or deleted.
    func assign(
        groupId: String,
        toPullListId listId: String,
        itemRepo: ItemRepository,
        accessoriesRepo: AccessoriesRepository,
        pullListRepo: PullListRepository
    ) async throws {
        _ = try await db.runTransaction { transaction, errorPointer -> Any? in
            do {
                let list = try pullListRepo.get(id: listId, transaction: transaction)
                let group = try self.get(id: groupId, transaction: transaction)
                guard list.essentialGroupId == nil, group.location.status == .inStorage else {
                    throw StaleWriteError.stateChanged
                }

                let items = try itemRepo.get(ids: Array(group.itemIds), transaction: transaction)
                var accessories: Accessories? = nil
                if let accessoriesId = group.accessoriesId {
                    accessories = try accessoriesRepo.get(id: accessoriesId, transaction: transaction)
                }

                var unavailable = items
                    .filter { $0.location.status != .inStorage }
                    .map(\.displayName)
                if let accessories, accessories.location.status != .inStorage {
                    unavailable.append(accessories.displayName)
                }
                guard unavailable.isEmpty else { throw EssentialsAssignError.notInStorage(names: unavailable) }

                let location = DocumentLocation(status: .inPullList, locationId: listId).firebaseUpdateFields
                for item in items {
                    itemRepo.update(id: item.id, fields: location, transaction: transaction)
                }
                if let accessories {
                    accessoriesRepo.update(id: accessories.id, fields: location, transaction: transaction)
                }
                self.update(id: groupId, fields: location, transaction: transaction)

                pullListRepo.update(
                    id: listId,
                    fields: [
                        PullListV2.CodingKeys.essentialGroupId.stringValue: groupId,
                        PullListV2.CodingKeys.unassignedItemIds.stringValue: FieldValue.arrayUnion(Array(group.itemIds))
                    ],
                    transaction: transaction
                )
                return nil
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
    }

    // MARK: - Delete
    func deleteGroup(id groupId: String) async throws {
        _ = try await db.runTransaction { transaction, errorPointer -> Any? in
            do {
                let group = try self.get(id: groupId, transaction: transaction)
                if let blocker = group.deleteErrorReason { throw blocker }

                self.delete(id: groupId, transaction: transaction)
                return nil
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
    }
}
