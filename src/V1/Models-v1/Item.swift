//
//  Item.swift
//  RedDoor
//
//  Created by Quinn Liu on 1/1/25.
//

import Foundation
import FirebaseFirestore

struct Item: Identifiable, Codable, Hashable {
    var modelId: String // comes from the "parent" model
    var id: String // the item's id (a variation of the modelId
    var listId: String // listId -> RDList ID the item is currently at (1 or 2 signify corresponding warehouse)
    var attention: Bool // whether the item needs attention (like repairs)
    var attentionReason: String // the reason the item needs attention
    var isAvailable: Bool // whether item is available to be added to a list (in storage)

    var image: RDImage?

    init(modelId: String, id: String = UUID().uuidString, attention: Bool = false, listId: String = Warehouse.warehouse1.name, isAvailable: Bool = true, image: RDImage? = nil, attentionReason: String = "") {
        self.modelId = modelId
        self.id = id
        self.attention = attention
        self.attentionReason = attentionReason
        self.listId = listId
        self.isAvailable = isAvailable
        self.image = image
    }

    static func getItemModel(modelId: String) async -> Model {
        do {
            let documentSnapshot = try await Firestore.firestore().collection("models").document(modelId).getDocument()
            return try documentSnapshot.data(as: Model.self)
        } catch {
            print("Error getting model: \(error)")
            return Model()
        }
    }

    static func getItem(itemId: String) async throws -> Item {
        let documentSnapshot = try await Firestore.firestore().collection("items").document(itemId).getDocument()
        return try documentSnapshot.data(as: Item.self)
    }
}
