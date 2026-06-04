//
//  EssentialsGroup.swift
//  RedDoor
//
//  Created by Quinn Liu on 5/10/26.
//

struct EssentialsGroup: AnyGroup {
    static let collectionName: String = "essentials"
    static let orderByField: String = "name"
    static let searchField: String = "name"
    
    var id: String
    var name: String
    var items: [ItemV2]
    var groupType: GroupType
    
    enum CodingKeys: String, CodingKey {
        case id, name, items
        case groupType = "group_type"
    }
}
