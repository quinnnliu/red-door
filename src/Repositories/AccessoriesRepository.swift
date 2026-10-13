//
//  AccessoriesRepository.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/13/26.
//

import Firebase

final class AccessoriesTypeRepository: GenericRepository<AccessoriesType> {}

enum AccessoriesDeleteError: LocalizedError {
    case inEssentialsGroup
    case assignedToList

    var errorDescription: String? {
        switch self {
        case .inEssentialsGroup: "Remove these accessories from their essentials group before deleting them."
        case .assignedToList: "Return these accessories to storage before deleting them."
        }
    }
}

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

// MARK: - Delete
extension AccessoriesRepository {

    /// Deletes unassigned accessories and their image.
    ///
    /// Re-reads the accessories inside the transaction so a change made from
    /// another device after the caller last looked still blocks the delete.
    /// Throws `AccessoriesDeleteError` when they are in an essentials group or
    /// out of storage.
    func deleteAccessories(id accessoriesId: String) async throws {
        let deleted = try await db.runTransaction { transaction, errorPointer -> Any? in
            do {
                let accessories = try self.get(id: accessoriesId, transaction: transaction)
                if let blocker = accessories.deleteBlocker { throw blocker }

                self.delete(id: accessoriesId, transaction: transaction)
                return accessories
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
        guard let accessories = deleted as? Accessories else { return }

        // The document is already gone, so a failure here only orphans files
        // and isn't a failed delete.
        do {
            try await FirebaseImageManager.shared.deleteDocumentImages(document: accessories, imageType: .accessory)
        } catch {
            print("[WARN]: Deleted accessories \(accessoriesId) but failed to clean up its images: \(error.localizedDescription)")
        }
    }
}

// MARK: - Batch
extension AccessoriesRepository {}

// MARK: - Transaction
extension AccessoriesRepository {}
