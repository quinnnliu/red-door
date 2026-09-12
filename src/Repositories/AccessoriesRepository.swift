//
//  AccessoriesRepository.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/13/26.
//

import Firebase

final class AccessoriesTypeRepository: GenericRepository<AccessoriesType> {}

final class AccessoriesRepository: GenericRepository<Accessories> {
    func maxAccessoriesNumber(forTypeId typeId: String) async -> Int {
        do {
            let snapshot = try await collectionRef
                .whereField(Accessories.CodingKeys.accessoriesTypeId.stringValue, isEqualTo: typeId)
                .order(by: Accessories.CodingKeys.accessoriesNumber.stringValue, descending: true)
                .limit(to: 1)
                .getDocuments()
            return snapshot.documents.first
                .flatMap { $0.data()[Accessories.CodingKeys.accessoriesNumber.stringValue] as? Int } ?? 0
        } catch {
            print("error getting max accessories number: \(error)")
            return 0
        }
    }
}

// MARK: - Batch
extension AccessoriesRepository {}

// MARK: - Transaction
extension AccessoriesRepository {}
