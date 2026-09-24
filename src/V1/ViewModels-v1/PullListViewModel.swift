//
//  PullListViewModel.swift
//  RedDoor
//
//  Created by Quinn Liu on 8/6/24.
//

import Foundation
import FirebaseFirestore

@Observable
class PullListViewModel: RDListViewModel {
    // MARK: Create Installed List from Pull List

    func createInstalledFromPull() async throws -> RDList {
        let installedList = RDList(list: selectedList, status: .installed, listType: .installed_list)
        let installedListRef = db.collection("installed_lists").document(installedList.id)
        let roomsRef = installedListRef.collection("rooms")

        try await validatePullList() // will throw PullListValidationErrors

        let result = try await db.runTransaction { transaction, _ in
            // 1. Create installed list
            do {
                try transaction.setData(from: installedList, forDocument: installedListRef)
            } catch {
                print("Error creating installedList document: (\(error.localizedDescription))")
                return nil
            }

            // 2. Copy rooms and update items + collect model counts
            var modelItemRemovalCounts: [String: Int] = [:]

            for var room in self.rooms {
                let roomRef = roomsRef.document(room.id)
                print("room.itemModelIdMap: \(room.itemModelIdMap.keys)")
                print("room.selectedItemIdSet: \(room.selectedItemIdSet)")
                room.itemModelIdMap = room.itemModelIdMap.filter { room.selectedItemIdSet.contains($0.key) }
                
                room.selectedItemIdSet = []

                // Update Item isAvailable to false
                for (itemId, modelId) in room.itemModelIdMap {
                    let itemRef = self.db.collection("items").document(itemId)
                    transaction.updateData([
                        "listId": installedList.id,
                        "isAvailable": false,
                    ], forDocument: itemRef)

                    modelItemRemovalCounts[modelId, default: 0] += 1
                }
                // Copy room with updated items
                do {
                    try transaction.setData(from: room, forDocument: roomRef)
                } catch {
                    print("Error creating installedList rooms documents: (\(error.localizedDescription))")
                    return nil
                }
            }

            // 4. Update models with increments
            for (modelId, installedItemCount) in modelItemRemovalCounts {
                let modelRef = self.db.collection("models").document(modelId)

                transaction.updateData([
                    "availableItemCount": FieldValue.increment(Int64(-installedItemCount)),
                ], forDocument: modelRef)
            }

            return installedList
        }

        guard let installedList = result as? RDList else {
            throw InstalledFromPullError.creationFailed
        }

        return installedList
    }

    // MARK: Validate PL

    func validatePullList() async throws { // throws PullListValidationError
        var modelItemCounts: [String: Int] = [:] // modelId -> number of those Items that exist in PL

        // validate item availability
        for room in rooms {
            for (itemId, modelId) in room.itemModelIdMap {
                modelItemCounts[modelId, default: 0] += 1

                let itemRef = db.collection("items").document(itemId)
                let itemSnap = try await itemRef.getDocument() // only throws network, permission, or serialization errors

                guard itemSnap.exists else {
                    throw PullListValidationError.itemDoesNotExist(id: itemId)
                }

                if let isAvailable = itemSnap["isAvailable"] as? Bool {
                    guard isAvailable else {
                        throw PullListValidationError.itemNotAvailable(id: itemId)
                    }
                }

                // TODO: add code to validate location = warehouse when Location type is implemented
            }
        }

        // validate model availability
        for (modelId, listItemCount) in modelItemCounts {
            let modelRef = db.collection("models").document(modelId)
            let modelSnap = try await modelRef.getDocument()

            guard modelSnap.exists else {
                throw PullListValidationError.modelDoesNotExist(id: modelId)
            }

            if let availableItemCount = modelSnap["availableItemCount"] as? Int {
                if availableItemCount - listItemCount < 0 {
                    throw PullListValidationError.modelAvailableCountInvalid(id: modelId)
                }
            }
        }
    }

    // MARK: Create Pull List

    func createPullList() {
        do {
            try selectedListReference.setData(from: selectedList)

            // creating empty rooms
            let batch = db.batch()
            for room in rooms {
                let roomRef = selectedListReference.collection("rooms").document(room.id)
                do {
                    try batch.setData(from: room, forDocument: roomRef)
                } catch {
                    print("Error adding room: \(room.id): \(error)")
                }
            }
            batch.commit()
        } catch {
            print("Error creating pull list: \(selectedList.id): \(error)")
        }
    }

    // MARK: Create Empty Room (exists in Firebase)

    // TODO: currently duplicated with RDListViewModel.createEmptyRoom

    @MainActor
    func createEmptyRoomExists(roomName: String) async -> Bool {
        do {
            let newRoom = Room(roomName: roomName, listId: selectedList.id)
            let roomRef = selectedListReference.collection("rooms").document(newRoom.id)
            
            let result = try await db.runTransaction { transaction, _ in
                transaction.updateData(["roomIds": FieldValue.arrayUnion([newRoom.id])], forDocument: self.listRef)
                
                do {
                    try transaction.setData(from: newRoom, forDocument: roomRef)
                } catch {
                    print("Error setting room data in transaction: \(error)")
                    return false
                }
                
                return true
            }
            
            guard let success = result as? Bool, success else {
                return false
            }
            
            // Only update local state if transaction succeeded
            selectedList.roomIds.append(newRoom.id)
            rooms.append(newRoom)
            return true
        } catch {
            print("Error creating empty room: \(error)")
            return false
        }
    }
}