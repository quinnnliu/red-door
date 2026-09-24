//
//  RDListViewModel.swift
//  RedDoor
//
//  Created by Quinn Liu on 8/6/24.
//

import FirebaseCore
import FirebaseFirestore
import FirebaseStorage
import Foundation
import PhotosUI
import SwiftUI

@Observable
class RDListViewModel {
    // current data
    var selectedList: RDList
    var rooms: [Room]

    // firebase
    let db: Firestore = Firestore.firestore()
    let listRef: DocumentReference
    let roomsRef: CollectionReference

    // MARK: init
    
    init(selectedList: RDList = RDList(), rooms: [Room] = []) {
        self.selectedList = selectedList
        self.rooms = rooms

        listRef = db.collection(selectedList.listType.collectionString).document(selectedList.id)
        roomsRef = listRef.collection("rooms")
    }

    var selectedListReference: DocumentReference {
        return db.collection(selectedList.listType.collectionString).document(selectedList.id)
    }

    // MARK: Update RDList

    func updateSelectedList(newRoomNames: [String] = []) async {
        let batch = db.batch()
        do {
            for roomName in newRoomNames {
                let newRoom = Room(roomName: roomName, listId: selectedList.id)
                rooms.append(newRoom)
                let roomRef = selectedListReference.collection("rooms").document(newRoom.id)
                try batch.setData(from: newRoom, forDocument: roomRef)
            }
            try batch.setData(from: selectedList, forDocument: selectedListReference)
            try await batch.commit()
        } catch {
            print("Error updating RDList: \(selectedList.id): \(error)")
        }
    }

    // MARK: Refresh PL

    @MainActor
    func refreshRDList() async {
        do {
            let document = try await selectedListReference.getDocument()

            if let data: [String : Any] = document.data() {
                let jsonData = try JSONSerialization.data(withJSONObject: data, options: [])
                let updatedRDList = try JSONDecoder().decode(RDList.self, from: jsonData)

                if selectedList != updatedRDList {
                    selectedList = updatedRDList
                }

                await loadRooms()
            }
        } catch {
            print("Error refreshing RDList: \(error.localizedDescription)")
        }
    }

    // MARK: Delete RDList

    // TODO: UPDATE THE LOCATIONS OF ITEMS IF THIS HAPPENS

    func deleteRDList() async {
        do {
            let roomsSnapshot = try await selectedListReference.collection("rooms").getDocuments()

            let batch = db.batch()

            for document in roomsSnapshot.documents {
                batch.deleteDocument(document.reference)
            }

            batch.deleteDocument(selectedListReference)

            try await batch.commit()

        } catch {
            print("Error deleting RDList: \(error.localizedDescription)")
        }
    }
}

// MARK: - Room

extension RDListViewModel {

    // MARK: Create Empty Room (doesn't exist in firebase)

    func createEmptyRoom(_ roomName: String) -> Bool {
        if roomExists(newRoomName: roomName, roomIds: selectedList.roomIds) {
            return false // room not added
        } else {
            let newRoom = Room(roomName: roomName, listId: selectedList.id)
            selectedList.roomIds.append(newRoom.id)
            rooms.append(newRoom)
            return true // room successfully added
        }
    }

    // MARK: (Helper) Room Exists

    func roomExists(newRoomName: String, roomIds: [String]) -> Bool {
        let normalizedNewRoomName = Room.nameToId(roomName: newRoomName)

        return roomIds.contains { roomId in
            return roomId == normalizedNewRoomName
        }
    }

    // MARK: Load Rooms

    @MainActor
    func loadRooms() async {
        let roomRef = selectedListReference.collection("rooms")

        do {
            let roomDocuments = try await roomRef.getDocuments()

            let rooms = roomDocuments.documents.compactMap { roomDocument -> Room? in
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: roomDocument.data(), options: [])
                    return try JSONDecoder().decode(Room.self, from: jsonData)
                } catch {
                    print("Error decoding document: \(error)")
                    return nil
                }
            }
            self.rooms = rooms
        } catch {
            print("Error fetching documents: \(error.localizedDescription)")
        }
    }
}
