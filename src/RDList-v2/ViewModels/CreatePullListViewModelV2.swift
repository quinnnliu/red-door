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
            try pullListRepo.set(pullListState, id: pullListState.id)
            
            guard let roomRepo = RoomRepository(list: pullListState) else {
                print("[ERROR] Failed to initialize RoomRepository")
                return
            }
            
            let batch = pullListRepo.db.batch()
            for room in rooms {
                do {
                    try roomRepo.set(room, id: room.id, inBatch: batch)
                } catch {
                    print("[ERROR] Failed creating room: \(error)")
                }
            }
            try await batch.commit()
        } catch {
            print("[ERROR] Failed creating pull list: \(error)")
        }
    }
}

extension CreatePullListViewModelV2 {
    
    // MARK: createEmptyRoom
    
    // TODO: use a toast to display error (instead of sending bool)
    func createEmptyRoom(_ roomName: String) -> Bool {
        guard !RoomV2.roomExists(newRoomName: roomName, rooms: rooms) else {
            return false // room not added
        }
        
        let newRoom = RoomV2(
            name: roomName,
            listId: pullListState.id
        )
        pullListState.roomIds.append(newRoom.id)
        rooms.append(newRoom)
        return true // room successfully added
    }
}
