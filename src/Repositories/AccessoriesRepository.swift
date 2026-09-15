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
            return try await maxNumber(
                filteredBy: Accessories.CodingKeys.accessoriesTypeId.stringValue,
                equalTo: typeId,
                numberField: Accessories.CodingKeys.accessoriesNumber.stringValue
            )
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
