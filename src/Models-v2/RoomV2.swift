//
//  Room-v2.swift
//  RedDoor
//
//  Created by Quinn Liu on 5/16/26.
//

import Foundation

struct RoomV2: ItemsListableDocument {
    static let collectionName: String = "rooms"
    static let orderByField: String = RoomV2.CodingKeys.baseName.stringValue
    static let searchField: String = "base_name"

    var id: String
    var nameId: String
    var baseName: String
    var listId: String
    var itemIds: Set<String>
    var squareFootage: String?
    var beforeImage: RDImage?
    var afterImage: RDImage?
    
    init(
        baseName: String,
        listId: String,
        itemIds: Set<String> = [],
        squareFootage: String? = nil,
        beforeImage: RDImage? = nil,
        afterimage: RDImage? = nil
    ) {
        self.id = UUID().uuidString
        self.nameId = RoomV2.nameToId(baseName)
        self.baseName = baseName
        self.listId = listId
        self.itemIds = itemIds
        self.squareFootage = squareFootage
        self.beforeImage = beforeImage
        self.afterImage = afterimage
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case itemIds = "item_ids"
        case squareFootage = "square_footage"
        case listId = "list_id"
        case baseName = "base_name"
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
    
    // MARK: normalizeRoomName
    /// trimmed and lowercased form of a room name, used for equality comparison
    static func normalizeRoomName(_ roomName: String) -> String {
        roomName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    // MARK: roomExists
    /// checks whether a new room name exists in a list of rooms, comparing display names
    static func roomExists(newRoomName: String, rooms: [RoomV2]) -> Bool {
        let normalizedNewRoomName = normalizeRoomName(newRoomName)

        return rooms.contains { normalizeRoomName($0.displayName) == normalizedNewRoomName }
    }
}

// MARK: - Square footage helpers

extension String {
    /// trimmed form of a free-text field, or nil when nothing was entered
    var trimmedOrNil: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

// MARK: - Metadata

extension RoomV2 {
    var metadata: String? { "\(itemIds.count) \(itemIds.count == 1 ? "item" : "items")" }
}
