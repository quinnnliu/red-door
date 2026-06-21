//
//  AddItemDocumentContext.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/21/26.
//

enum AddItemDocumentContext: Hashable {
    case itemToPullListRoom(item: ItemV2, room: RoomV2)
    case itemToEssentialsGroup(item: ItemV2, group: EssentialsGroup)
    // future: case itemToInstalledListRoom(item: ItemV2, room: RoomV2)

    var destination: any RDDocument {
        switch self {
        case .itemToPullListRoom(_, let room): room
        case .itemToEssentialsGroup(_, let group): group
        }
    }
    
    var item: ItemV2 {
        switch self {
        case .itemToPullListRoom(let item, _): item
        case .itemToEssentialsGroup(let item, _): item
        }
    }
}
