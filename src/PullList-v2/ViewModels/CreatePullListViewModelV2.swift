//
//  CreatePullListViewModelV2.swift
//  RedDoor
//
//  Created by Quinn Liu on 5/16/26.
//

import Foundation

@Observable
final class CreatePullListViewModelV2 {
    private let pullListRepo: PullListRepository = .init()
    
    var pullListState: PullListV2
    var rooms: [RoomV2]
    
    var isLoading: Bool = false
    
    var showAlert: Bool = false
    var alertText: String = ""
    
    init() {
        self.pullListState = PullListV2(
            id: UUID().uuidString,
            listType: .pullListV2,
            address: Address(),
            addressId: "",
            createdDate: "",
            installDate: "",
            uninstallDate: "",
            clientId: "",
            roomIds: []
        )
        self.rooms = []
    }
    
    // MARK: createPullList
    func createPullList() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try pullListRepo.set(document: pullListState)
            
            guard let roomRepo = RoomRepository(list: pullListState) else {
                alertText = "[ERROR] Failed to initialize RoomRepository"
                showAlert = true
                return
            }
            
            let batch = pullListRepo.db.batch()
            for room in rooms {
                do {
                    try roomRepo.set(document: room, id: room.id, inBatch: batch)
                } catch {
                    alertText = "[ERROR] Failed creating room: \(error)"
                    showAlert = true
                    return
                }
            }
            try await batch.commit()
        } catch {
            alertText = "[ERROR] Failed creating pull list: \(error)"
            showAlert = true
            return
        }
    }
}

extension CreatePullListViewModelV2 {
    
    // MARK: createEmptyRoom
    
    // TODO: use a toast to display error (instead of sending bool)
    func createEmptyRoom(_ roomName: String) {
        guard !RoomV2.roomExists(newRoomName: roomName, rooms: rooms) else {
            alertText = "Room with same name already exists for this list" // room not added
            showAlert = true
            return
        }
        
        let newRoom = RoomV2(
            displayName: roomName,
            listId: pullListState.id
        )
        pullListState.roomIds.append(newRoom.id)
        rooms.append(newRoom)
        
//        alertText = "\(newRoom.displayName) successfully created" // room added
//        showAlert = true
    }
}
