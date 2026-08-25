//
//  EssentialsRepository.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/13/26.
//

import Firebase

final class EssentialsGroupTypeRepository: GenericRepository<EssentialsGroupType> {}

final class EssentialsRepository: GenericRepository<EssentialsGroup> {
    func maxGroupNumber(forTypeId typeId: String) async throws -> Int {
        let snapshot = try await collectionRef
            .whereField(EssentialsGroup.CodingKeys.essentialsTypeId.stringValue, isEqualTo: typeId)
            .order(by: EssentialsGroup.CodingKeys.groupNumber.stringValue, descending: true)
            .limit(to: 1)
            .getDocuments()
        return snapshot.documents.first
            .flatMap { $0.data()[EssentialsGroup.CodingKeys.groupNumber.stringValue] as? Int } ?? 0
    }
}
