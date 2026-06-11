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
    static let searchField: String = "display_name"
    
    var id: String
    var nameId: String
    var displayName: String
    var listId: String
    var itemIds: Set<String>
    var beforeImage: RDImage?
    var afterImage: RDImage?
    
    init(
        displayName: String,
        listId: String,
        itemIds: Set<String> = [],
        beforeImage: RDImage? = nil,
        afterimage: RDImage? = nil
    ) {
        self.id = UUID().uuidString
        self.nameId = RoomV2.nameToId(displayName)
        self.displayName = displayName
        self.listId = listId
        self.itemIds = itemIds
        self.beforeImage = beforeImage
        self.afterImage = afterimage
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case itemIds = "item_ids"
        case listId = "list_id"
        case displayName = "display_name"
        case nameId = "name_id"
        case beforeImage = "before_image"
        case afterImage = "after_image"
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
