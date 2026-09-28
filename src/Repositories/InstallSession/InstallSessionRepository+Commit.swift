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
    /// Throws if the session no longer exists, which is how a second caller
    /// racing the same commit is rejected. That guard matters more here than in
    /// an uninstall: this deletes the pull list and its rooms.
    ///
    /// `rooms` is passed in rather than read here because Firestore
    /// transactions can only read documents by reference — they cannot run the
    /// subcollection query needed to discover them.
    func commit(
        pullList: PullListV2,
        rooms: [RoomV2],
        essentialsGroup: EssentialsGroup?,
        itemRepo: ItemRepository,
        roomRepo: RoomRepository,
        pullListRepo: PullListRepository,
        installedListRepo: InstalledListRepository,
        installedRoomRepo: RoomRepository,
        essentialsRepo: EssentialsRepository,
        accessoriesRepo: AccessoriesRepository
    ) async throws -> InstalledListV2 {
        let installedList = InstalledListV2(from: pullList)

        _ = try await db.runTransaction { transaction, errorPointer -> Any? in
            do {
                let session = try self.get(id: pullList.id, transaction: transaction)

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
                //    own location says it's in a warehouse.
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
                if let group = essentialsGroup {
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
                pullListRepo.delete(id: pullList.id, transaction: transaction)

                // 5. Consume the claim token.
                self.delete(id: pullList.id, transaction: transaction)

                return nil
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }

        return installedList
    }
}
