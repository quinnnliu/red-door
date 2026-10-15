//
//  InstallSessionRepository+Commit.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/27/26.
//

import Firebase

extension InstallSessionRepository {

    /// Turns the pull list into an installed list in one transaction, then
    /// consumes the session document.
    ///
    /// Everything the commit acts on is re-read inside the transaction — the
    /// session, the pull list, its rooms and its essentials group — so a list
    /// edited while the sheet was open can't be installed from a stale copy.
    /// Firestore also retries the transaction if any of those change mid-flight.
    ///
    /// Throws if the session no longer exists, which is how a second caller
    /// racing the same commit is rejected. That guard matters more here than in
    /// an uninstall: this deletes the pull list and its rooms.
    ///
    /// Throws a `ListCommitError`, with nothing written, when the fresh state
    /// differs from what the user reviewed in a way that changes what moves:
    /// the lock was taken over, the pull list has unassigned items, the
    /// essentials group changed, or rooms hold items the user never saw.
    /// Items removed since review need nothing — they just aren't moved.
    func commit(
        pullListId: String,
        expectedGeneration: Int,
        reviewedItemIds: Set<String>,
        reviewedEssentialsGroupId: String?,
        itemRepo: ItemRepository,
        roomRepo: RoomRepository<PullListV2>,
        pullListRepo: PullListRepository,
        installedListRepo: InstalledListRepository,
        installedRoomRepo: RoomRepository<InstalledListV2>,
        essentialsRepo: EssentialsRepository,
        accessoriesRepo: AccessoriesRepository
    ) async throws -> InstalledListV2 {
        let result = try await db.runTransaction { transaction, errorPointer -> Any? in
            do {
                // --- Reads. Firestore requires every read to precede every write.

                let session = try self.ownedSession(
                    id: pullListId,
                    generation: expectedGeneration,
                    transaction: transaction
                )
                let pullList = try pullListRepo.get(id: pullListId, transaction: transaction)
                let rooms = try roomRepo.get(ids: pullList.roomIds, transaction: transaction)

                var group: EssentialsGroup? = nil
                if let groupId = pullList.essentialGroupId {
                    group = try essentialsRepo.get(id: groupId, transaction: transaction)
                }

                // --- Validation. Throws before anything is written.

                guard pullList.unassignedItemIds.isEmpty else {
                    throw ListCommitError.unassignedItems(count: pullList.unassignedItemIds.count)
                }
                guard pullList.essentialGroupId == reviewedEssentialsGroupId else {
                    throw ListCommitError.essentialsChanged
                }
                let unreviewed = Set(rooms.flatMap(\.itemIds)).subtracting(reviewedItemIds)
                guard unreviewed.isEmpty else {
                    throw ListCommitError.unreviewedItems(count: unreviewed.count)
                }

                // --- Writes.

                let installedList = InstalledListV2(from: pullList)

                // 1. Move every item. Anything absent from the session installs
                //    into the list, which is the default.
                var installedItemIds: Set<String> = []
                for itemId in rooms.flatMap(\.itemIds) {
                    let destination = session.destination(for: itemId, installedListId: installedList.id)
                    if destination.status == .inInstalledList {
                        installedItemIds.insert(itemId)
                    }
                    itemRepo.update(
                        id: itemId,
                        fields: destination.firebaseUpdateFields,
                        transaction: transaction
                    )
                }

                // 2. Create the installed list and copy every room across,
                //    dropping items that were diverted to storage — otherwise a
                //    stored item stays in its old room's membership while its
                //    own location says it's in storage.
                //
                //    Room IDs and `listId` carry over unchanged because the
                //    installed list reuses the pull list's ID.
                try installedListRepo.set(document: installedList, id: installedList.id, transaction: transaction)
                for room in rooms {
                    var installedRoom = room
                    installedRoom.itemIds = room.itemIds.intersection(installedItemIds)
                    try installedRoomRepo.set(document: installedRoom, id: room.id, transaction: transaction)
                }

                // 3. The essentials group follows the list it belongs to.
                if let group {
                    let location = DocumentLocation(status: .inInstalledList, locationId: installedList.id)
                    essentialsRepo.update(id: group.id, fields: location.firebaseUpdateFields, transaction: transaction)
                    if let accessoriesId = group.accessoriesId {
                        accessoriesRepo.update(id: accessoriesId, fields: location.firebaseUpdateFields, transaction: transaction)
                    }
                }

                // 4. Retire the pull list and its rooms.
                for room in rooms {
                    roomRepo.delete(id: room.id, transaction: transaction)
                }
                pullListRepo.delete(id: pullListId, transaction: transaction)

                // 5. Consume the claim token.
                self.delete(id: pullListId, transaction: transaction)

                return installedList
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }

        guard let installedList = result as? InstalledListV2 else {
            throw RepositoryError.decodeFailure
        }
        return installedList
    }
}
