//
//  UninstallSessionRepository+Commit.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/27/26.
//

import Firebase

extension UninstallSessionRepository {

    /// Applies an entire uninstall plan in one transaction, then consumes the
    /// session document.
    ///
    /// Throws if the session no longer exists, which is how a second caller
    /// racing the same commit is rejected.
    func commit(
        installedListId: String,
        itemRepo: ItemRepository,
        installedListRepo: InstalledListRepository
    ) async throws {
        _ = try await db.runTransaction { transaction, errorPointer -> Any? in
            do {
                let session = try self.get(id: installedListId, transaction: transaction)

                // 1. Move every item to its assigned destination.
                for (itemId, destination) in session.itemDestinations {
                    itemRepo.update(
                        id: itemId,
                        fields: destination.documentLocation.firebaseUpdateFields,
                        transaction: transaction
                    )
                }

                // 2. Mark the list uninstalled. Rooms and their itemIds are
                //    deliberately left intact as the historical record of what
                //    was installed where.
                installedListRepo.update(
                    id: installedListId,
                    fields: [InstalledListV2.CodingKeys.uninstalled.stringValue: true],
                    transaction: transaction
                )

                // 3. Consume the claim token.
                self.delete(id: installedListId, transaction: transaction)

                return nil
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
    }
}
