//
//  EssentialsGroup.swift
//  RedDoor
//
//  Created by Quinn Liu on 5/10/26.
//

struct EssentialsGroup: AnyGroup {
    var id: String
    var name: String
    var items: [ItemV2]
    var groupType: GroupType
    
    static var collectionName: String = "essentials"
    static var orderByField: String = "name"
}
