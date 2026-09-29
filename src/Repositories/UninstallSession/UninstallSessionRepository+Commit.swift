//
//  UninstallSessionRepository+Commit.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/27/26.
//

import Firebase

extension UninstallSessionRepository {

    /// Applies an entire uninstall plan in one transaction, then retires the
    /// session document into a permanent record of what it did.
    ///
    /// Throws if the session was already committed, which is how a second
    /// caller racing the same commit is rejected.
    func commit(
        installedList: InstalledListV2,
        rooms: [RoomV2],
        essentialsGroup: EssentialsGroup?,
        itemRepo: ItemRepository,
        installedListRepo: InstalledListRepository,
        pullListRepo: PullListRepository,
        essentialsRepo: EssentialsRepository,
        accessoriesRepo: AccessoriesRepository
    ) async throws {
        let installedListId = installedList.id

        let uninstalledDate = ISO8601DateFormatter().string(from: Date())

        _ = try await db.runTransaction { transaction, errorPointer -> Any? in
            do {
                let session = try self.get(id: installedListId, transaction: transaction)

                guard !session.uninstalled else { throw RepositoryError.sessionComplete }

                // 1. Move every individually assigned item.
                for (itemId, destination) in session.itemDestinations {
                    itemRepo.update(
                        id: itemId,
                        fields: destination.documentLocation.firebaseUpdateFields,
                        transaction: transaction
                    )
                }

                // 2. Move the essentials group as one unit: the group document,
                //    every item in it, and its accessories.
                if let group = essentialsGroup, let destination = session.essentialsDestination {
                    let fields = destination.documentLocation.firebaseUpdateFields
                    for itemId in group.itemIds {
                        itemRepo.update(id: itemId, fields: fields, transaction: transaction)
                    }
                    essentialsRepo.update(id: group.id, fields: fields, transaction: transaction)
                    if let accessoriesId = group.accessoriesId {
                        accessoriesRepo.update(id: accessoriesId, fields: fields, transaction: transaction)
                    }
                }

                // 3. Create the copy pull list, if anything is headed there.
                //    Deferred to commit so an abandoned session leaves no
                //    orphaned list behind.
                if let copyId = session.copyPullListId, session.targetsCopy {
                    try self.createCopyPullList(
                        copyId: copyId,
                        session: session,
                        installedList: installedList,
                        rooms: rooms,
                        essentialsGroup: essentialsGroup,
                        pullListRepo: pullListRepo,
                        transaction: transaction
                    )
                }

                // 4. Hand anything routed to an existing list over to it. Items
                //    arrive unassigned; whoever works that list places them.
                if let existingId = session.existingPullListId {
                    var itemIds = session.itemIds(for: .existingList)
                    var fields: [String: Any] = [:]

                    // Group members go into the unassigned pool too — linking
                    // the group alone leaves them unreachable, since a pull
                    // list renders essentials as a name, not as its items.
                    if session.essentialsDestination?.type == .existingList, let group = essentialsGroup {
                        itemIds += group.itemIds
                        fields[PullListV2.CodingKeys.essentialGroupId.stringValue] = group.id
                    }
                    if !itemIds.isEmpty {
                        fields[PullListV2.CodingKeys.unassignedItemIds.stringValue] =
                            FieldValue.arrayUnion(itemIds)
                    }
                    if !fields.isEmpty {
                        pullListRepo.update(id: existingId, fields: fields, transaction: transaction)
                    }
                }

                // 5. Mark the list uninstalled. Rooms and their itemIds are
                //    deliberately left intact as the historical record of what
                //    was installed where.
                installedListRepo.update(
                    id: installedListId,
                    fields: [InstalledListV2.CodingKeys.uninstalled.stringValue: true],
                    transaction: transaction
                )

                // 6. Retire the session in place: it stops being a plan and
                //    becomes the permanent record of where everything went.
                var sessionFields: [String: Any] = [
                    UninstallSession.CodingKeys.uninstalled.stringValue: true,
                    UninstallSession.CodingKeys.uninstalledDate.stringValue: uninstalledDate
                ]
                if let group = essentialsGroup {
                    sessionFields[UninstallSession.CodingKeys.essentialsGroupId.stringValue] = group.id
                    sessionFields[UninstallSession.CodingKeys.essentialsItemIds.stringValue] = Array(group.itemIds)
                }
                self.update(id: installedListId, fields: sessionFields, transaction: transaction)

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
        essentialsGroup: EssentialsGroup?,
        pullListRepo: PullListRepository,
        transaction: Transaction
    ) throws {
        let essentialsHeadedHere = session.essentialsDestination?.type == .copy

        // Assigned items land in their original rooms, but group members have
        // no per-item destination, so they arrive unassigned for re-placing.
        let copyList = PullListV2(
            from: installedList,
            id: copyId,
            roomIds: rooms.map(\.id),
            unassignedItemIds: essentialsHeadedHere ? Array(essentialsGroup?.itemIds ?? []) : [],
            essentialGroupId: essentialsHeadedHere ? essentialsGroup?.id : nil
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
