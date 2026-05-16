//
//  Group.swift
//  RedDoor
//
//  Created by Quinn Liu on 5/9/26.
//

protocol AnyGroup: AnyRDDocument {
    var name: String { get set }
    var items: [ItemV2] { get set }
    var groupType: GroupType { get }
}

enum GroupType: String, Codable {
    case essentials = "essentials"
    case accessories = "accessories"
}
