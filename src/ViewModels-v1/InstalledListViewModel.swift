//
//  InstalledListViewModel.swift
//  RedDoor
//
//  Created by Quinn Liu on 8/6/24.
//

import Foundation
import FirebaseFirestore

@Observable
class InstalledListViewModel: RDListViewModel {

    // MARK: Create Pull List from Installed List

    func createPullFromInstalled() async throws -> RDList {
        // Empty Pull List Copy
        var copyPullList = RDList(address: Address(street: "Copy of \(selectedList.address.getStreetAddress() ?? "")"), listType: .pull_list)
        copyPullList.createdDate = selectedList.createdDate
        copyPullList.installDate = selectedList.installDate
        copyPullList.uninstallDate = selectedList.uninstallDate
        copyPullList.status = .planning
        copyPullList.client = selectedList.client

        copyPullList.roomIds = selectedList.roomIds

        let copyPullListRef = db.collection("pull_lists").document(copyPullList.id)
        let roomsRef = copyPullListRef.collection("rooms")

        let result = try await db.runTransaction { transaction, _ in
            // 1. Create pull list
            do {
                try transaction.setData(from: copyPullList, forDocument: copyPullListRef)
            } catch {
                print("Error creating pullList document: (\(error.localizedDescription))")
                return nil
            }

            // 2. Copy rooms
            for room in self.rooms {
                let roomRef = roomsRef.document(room.id)
                do {
                    try transaction.setData(from: room, forDocument: roomRef)
                } catch {
                    print("Error creating pullList rooms documents: (\(error.localizedDescription))")
                    return nil
                }
            }
            return copyPullList
        }

        guard let pullList: RDList = result as? RDList else {
            throw InstalledFromPullError.creationFailed
        }
        print("pullList copy from installed: \(pullList)")
        return pullList
    }

    // MARK: Restore Item to Storage
    func restoreItemToStorage(item: Item, storageLocation: Address) async throws {
        let itemRef = db.collection("items").document(item.id)
        try await itemRef.updateData([
            "listId": storageLocation.id,
            "isAvailable": true,
        ])

        let modelRef = db.collection("models").document(item.modelId)
        try await modelRef.updateData([
            "availableItemCount": FieldValue.increment(Int64(1)),
        ])
    }

    // MARK: Set List as Unstaged
    func setListAsUnstaged() async {
        selectedList.status = .unstaged
        do {
            try await listRef.updateData([
                "status": InstallationStatus.unstaged.rawValue,
            ])
        } catch {
            print("Error setting list as unstaged: \(error.localizedDescription)")
        }
    }
}