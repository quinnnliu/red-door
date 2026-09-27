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
        installedList: InstalledListV2,
        rooms: [RoomV2],
        itemRepo: ItemRepository,
        installedListRepo: InstalledListRepository,
        pullListRepo: PullListRepository
    ) async throws {
        let installedListId = installedList.id

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

                // 2. Create the copy pull list, if anything is headed there.
                //    Deferred to commit so an abandoned session leaves no
                //    orphaned list behind.
                if let copyId = session.copyPullListId, session.targetsCopy {
                    try self.createCopyPullList(
                        copyId: copyId,
                        session: session,
                        installedList: installedList,
                        rooms: rooms,
                        pullListRepo: pullListRepo,
                        transaction: transaction
                    )
                }

                // 3. Hand copied-to-existing items over as unassigned; whoever
                //    works that pull list assigns rooms later.
                if let existingId = session.existingPullListId, session.targetsExistingList {
                    pullListRepo.update(
                        id: existingId,
                        fields: [
                            PullListV2.CodingKeys.unassignedItemIds.stringValue:
                                FieldValue.arrayUnion(session.itemIds(for: .existingList))
                        ],
                        transaction: transaction
                    )
                }

                // 4. Mark the list uninstalled. Rooms and their itemIds are
                //    deliberately left intact as the historical record of what
                //    was installed where.
                installedListRepo.update(
                    id: installedListId,
                    fields: [InstalledListV2.CodingKeys.uninstalled.stringValue: true],
                    transaction: transaction
                )

                // 5. Consume the claim token.
                self.delete(id: installedListId, transaction: transaction)

                return nil
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
    }

    // MARK: - createCopyPullList

    private func createCopyPullList(
        copyId: String,
        session: UninstallSession,
        installedList: InstalledListV2,
        rooms: [RoomV2],
        pullListRepo: PullListRepository,
        transaction: Transaction
    ) throws {
        let copyList = PullListV2(
            from: installedList,
            id: copyId,
            roomIds: rooms.map(\.id)
        )
        try pullListRepo.set(document: copyList, id: copyId, transaction: transaction)

        let copyRoomRepo = RoomRepository(
            parentCollectionName: PullListV2.collectionName,
            listId: copyId
        )

        for room in rooms {
            var copyRoom = room

            // Required: the copy is a new list ID, and `RoomRepository(room:)`
            // resolves its collection path from `listId`. Leaving the old value
            // would point every copied room back at the installed list.
            copyRoom.listId = copyId

            // Only items actually routed to the copy come along.
            copyRoom.itemIds = room.itemIds.filter {
                session.itemDestinations[$0]?.type == .copy
            }

            // Before/after photos document the finished install, not a plan.
            // Carrying the references over would also leave two room documents
            // pointing at one Storage object, where replacing either one
            // dangles the other.
            copyRoom.beforeImage = nil
            copyRoom.afterImage = nil

            try copyRoomRepo.set(document: copyRoom, id: copyRoom.id, transaction: transaction)
        }
    }
}
