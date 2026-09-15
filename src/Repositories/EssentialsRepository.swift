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

    func maxGroupNumber(forTypeId typeId: String) async -> Int {
        do {
            let snapshot = try await collectionRef
                .whereField(EssentialsGroup.CodingKeys.essentialsTypeId.stringValue, isEqualTo: typeId)
                .order(by: EssentialsGroup.CodingKeys.groupNumber.stringValue, descending: true)
                .limit(to: 1)
                .getDocuments()
            return snapshot.documents.first
                .flatMap {
                    $0.data()[EssentialsGroup.CodingKeys.groupNumber.stringValue] as? Int
                } ?? 0
        } catch {
            print("error getting max number: \(error)")
            return 0
        }
    }
}
