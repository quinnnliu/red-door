//
//  EssentialsRepository.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/13/26.
//

import Firebase

final class EssentialsGroupTypeRepository: GenericRepository<EssentialsGroupType> {}

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
}
