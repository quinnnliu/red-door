//
//  Room-v2.swift
//  RedDoor
//
//  Created by Quinn Liu on 5/16/26.
//

import Foundation

struct RoomV2: AnyRDDocument {
    static let collectionName: String = "rooms"
    static let orderByField: String = "name"
    
    var id: String
    var displayName: String
    var listId: String
    var items: Set<String>
    
    init(
        displayName: String,
        listId: String,
        items: Set<String> = []
    ) {
        self.id = RoomV2.nameToId(displayName)
        self.displayName = displayName
        self.listId = listId
        self.items = items
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, items
        case listId = "list_id"
    }
}

extension RoomV2 {
    // MARK: nameToId
    /// lowercased and "-" separated string of the room name
    static func nameToId(_ roomName: String) -> String {
        return roomName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: " ", with: "-")
    }
    
    // MARK: roomExists
    /// checks whether a new room name exists in a list of rooms
    static func roomExists(newRoomName: String, rooms: [RoomV2]) -> Bool {
        let normalizedNewRoomName = RoomV2.nameToId(newRoomName)
        
        return rooms.contains { $0.id == normalizedNewRoomName }
    }
}
