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
