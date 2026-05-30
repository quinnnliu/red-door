//
//  Room.swift
//  RedDoor
//
//  Created by Quinn Liu on 2/17/25.
//

import Foundation

struct Room: Codable, Identifiable, Hashable {
    var id: String // normalized room name (lowercased, spaces replaced by "-")
    var roomName: String
    var listId: String
    var itemModelIdMap: [String: String] = [:]
    var selectedItemIdSet: Set<String> = []

    init(roomName: String, listId: String, itemModelIdMap: [String: String] = [:], selectedItemIdSet: Set<String> = []) {
        id = roomName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: " ", with: "-")
        self.roomName = roomName
        self.listId = listId
        self.itemModelIdMap = itemModelIdMap
        self.selectedItemIdSet = selectedItemIdSet
    }
}

extension Room {
    static func nameToId(roomName: String) -> String {
        return roomName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: " ", with: "-")
    }
}
