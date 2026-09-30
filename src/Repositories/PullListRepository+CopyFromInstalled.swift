//
//  PullListRepository+CopyFromInstalled.swift
//  RedDoor
//
//  Created by Quinn Liu on 09/29/26.
//

import Firebase

/// What actually made it into the copy, versus what the caller expected.
struct CopyFromInstalledOutcome {
    let pullList: PullListV2
    let droppedItemCount: Int
    let droppedEssentialsGroup: Bool
}

extension PullListRepository {

    /// Stands up a new pull list from an already-uninstalled installed list,
    /// claiming whichever of its items are still in storage.
    func createCopy(
        from installedList: InstalledListV2,
        newListId: String,
        address: Address,
        installDate: Date,
        uninstallDate: Date,
        clientId: String,
        sourceRooms: [RoomV2],
        candidateItemIds: Set<String>,
        essentialsGroup: EssentialsGroup?,
        itemRepo: ItemRepository,
        essentialsRepo: EssentialsRepository,
        accessoriesRepo: AccessoriesRepository
    ) async throws -> CopyFromInstalledOutcome {
        let candidates = Array(candidateItemIds)

        let result = try await db.runTransaction { transaction, errorPointer -> Any? in
            do {
                // --- Reads. Firestore requires every read to precede every write.

                let freshItems = try itemRepo.get(ids: candidates, transaction: transaction)
                let eligibleItemIds = Set(
                    freshItems.filter { $0.location.status.isAvailable }.map(\.id)
                )

                // The group moves as one unit or not at all, matching how
                // `EssentialsGroupDetailViewModel.assignToPullList` gates it: the
                // group document, every member, and the accessories must all be
                // in storage.
                var qualifyingGroup: EssentialsGroup? = nil
                if let group = essentialsGroup {
                    let freshGroup = try essentialsRepo.get(id: group.id, transaction: transaction)
                    let members = try itemRepo.get(ids: Array(freshGroup.itemIds), transaction: transaction)

                    var accessoriesAvailable = true
                    if let accessoriesId = freshGroup.accessoriesId {
                        let accessories = try accessoriesRepo.get(id: accessoriesId, transaction: transaction)
                        accessoriesAvailable = accessories.location.status.isAvailable
                    }

                    if freshGroup.location.status.isAvailable,
                       accessoriesAvailable,
                       members.allSatisfy({ $0.location.status.isAvailable }) {
                        qualifyingGroup = freshGroup
                    }
                }

                let groupItemIds = qualifyingGroup?.itemIds ?? []
                let claimedItemIds = eligibleItemIds.union(groupItemIds)

                // A claimed item that no source room lists would be invisible on
                // the new list, so it goes to the unassigned pool instead. Install
                // blocks on unassigned items, so this should stay empty in
                // practice — it's here so a stale room can't silently eat one.
                let roomedItemIds = Set(sourceRooms.flatMap(\.itemIds))
                let unplacedItemIds = claimedItemIds.subtracting(roomedItemIds)

                // --- Writes.

                var copyList = PullListV2(
                    from: installedList,
                    id: newListId,
                    address: address,
                    roomIds: sourceRooms.map(\.id),
                    unassignedItemIds: Array(unplacedItemIds),
                    essentialGroupId: qualifyingGroup?.id
                )
                // The `from:` init inherits the source's dates; a standalone copy
                // is scheduling new work, so the picked dates win.
                copyList.installDate = installDate
                copyList.uninstallDate = uninstallDate
                copyList.clientId = clientId

                try self.set(document: copyList, id: newListId, transaction: transaction)

                let copyRoomRepo = RoomRepository<PullListV2>(listId: newListId)

                for room in sourceRooms {
                    var copyRoom = room
                    // `RoomRepository(room:)` resolves its collection path from
                    // `listId`; leaving the old value points the copy's rooms back
                    // at the installed list.
                    copyRoom.listId = newListId
                    copyRoom.itemIds = room.itemIds.intersection(claimedItemIds)
                    // These document the finished install, not a plan. Carrying the
                    // references would also leave two room documents pointing at one
                    // Storage object, where replacing either dangles the other.
                    copyRoom.beforeImage = nil
                    copyRoom.afterImage = nil

                    try copyRoomRepo.set(document: copyRoom, id: copyRoom.id, transaction: transaction)
                }

                let location = DocumentLocation(status: .inPullList, locationId: newListId)
                for itemId in claimedItemIds {
                    itemRepo.update(id: itemId, fields: location.firebaseUpdateFields, transaction: transaction)
                }

                if let group = qualifyingGroup {
                    essentialsRepo.update(id: group.id, fields: location.firebaseUpdateFields, transaction: transaction)
                    if let accessoriesId = group.accessoriesId {
                        accessoriesRepo.update(id: accessoriesId, fields: location.firebaseUpdateFields, transaction: transaction)
                    }
                }

                return CopyFromInstalledOutcome(
                    pullList: copyList,
                    droppedItemCount: candidateItemIds.count - eligibleItemIds.count,
                    droppedEssentialsGroup: essentialsGroup != nil && qualifyingGroup == nil
                )
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }

        guard let outcome = result as? CopyFromInstalledOutcome else {
            throw RepositoryError.decodeFailure
        }
        return outcome
    }
}
