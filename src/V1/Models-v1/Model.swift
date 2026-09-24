//
//  Model.swift
//  RedDoor
//
//  Created by Quinn Liu on 8/13/24.
//

import Foundation
import SwiftUI
import FirebaseFirestore

struct ItemWithModel: Identifiable, Codable, Hashable {
    var id: String
    var item: Item
    var model: Model

    init(item: Item, model: Model) {
        self.id = item.id
        self.item = item
        self.model = model
    }
}

struct Model: Identifiable, Codable, Hashable {
    // ID
    var id: String
    var name: String
    var nameLowercased: String

    // Attributes
    var type: String

    var primaryColor: String
    var secondaryColor: String

    var primaryMaterial: String
    var secondaryMaterial: String

    // Items
    var itemIds: [String]
    var availableItemCount: Int

    // Images
    var primaryImage: RDImage
    var secondaryImages: [RDImage]

    // Description
    var description: String
    var descriptionLowercased: String
    var isEssential: Bool

    init(
        id: String = UUID().uuidString,
        name: String = "",

        itemIds: [String] = [],
        availableItemCount: Int = 0,

        type: String = "N/A",
        primaryColor: String = "N/A",
        secondaryColor: String = "N/A",

        primaryMaterial: String = "N/A",
        secondaryMaterial: String = "N/A",

        primaryImage: RDImage = RDImage(),
        secondaryImages: [RDImage] = [],

        description: String = "",
        isEssential: Bool = false
    ) {
        self.id = id
        self.name = name
        nameLowercased = name.lowercased()

        self.type = type

        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor

        self.primaryMaterial = primaryMaterial
        self.secondaryMaterial = secondaryMaterial

        self.itemIds = itemIds
        self.availableItemCount = availableItemCount

        self.primaryImage = primaryImage
        self.secondaryImages = secondaryImages

        self.description = description
        self.descriptionLowercased = description.lowercased()
        self.isEssential = isEssential
    }
}

// MARK: primaryImageExists

extension Model {
    var primaryImageExists: Bool {
        return !(primaryImage.imageURL == nil && primaryImage.uiImage == nil)
    }
}

extension Model {
    static func getModel(modelId: String) async throws -> Model {
        let documentSnapshot = try await Firestore.firestore().collection("models").document(modelId).getDocument()
        return try documentSnapshot.data(as: Model.self)
    }
}


// MARK: - Model Options

extension Model {
    static var colorMap: [String: Color] = [
        "N/A": .primary.opacity(0.5),
        "Black": .black,
        "White": .white,
        "Brown": .brown,
        "Gray": .gray,
        "Pink": .pink,
        "Red": .red,
        "Orange": .orange,
        "Yellow": .yellow,
        "Green": .green,
        "Mint": .mint,
        "Teal": .teal,
        "Cyan": .cyan,
        "Blue": .blue,
        "Purple": .purple,
        "Indigo": .indigo,
    ]

    static var typeOptions: [String] = [
        "Chair",
        "Desk",
        "Table",
        "Couch",
        "Lamp",
        "Art",
        "Decor",
        "Miscellaneous",
        "N/A",
    ]

    static var typeMap: [String: String] = [
        "Chair": "chair.fill",
        "Desk": "table.furniture.fill",
        "Table": "table.furniture.fill",
        "Couch": "sofa.fill",
        "Lamp": "lamp.floor.fill",
        "Art": "photo.artframe",
        "Misc": "ellipsis.circle",
        "N/A": "nosign",
    ]
    
    static var materialOptions: [String] = [
        "Acrylic",
        "Bamboo",
        "Cane",
        "Concrete",
        "Engineered Wood",
        "Fabric",
        "Glass",
        "Laminates",
        "Leather",
        "Marble",
        "Metal",
        "None",
        "Plastic",
        "Rattan",
        "Resin",
        "Stainless Steel",
        "Stone",
        "Veneer",
        "Vinyl",
        "Wicker",
        "Wood",
        "Other",
    ]
}
