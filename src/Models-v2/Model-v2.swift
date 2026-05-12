////
////  Model-v2.swift
////  RedDoor
////
////  Created by Quinn Liu on 4/25/26.
////
//import SwiftUI
//
//struct ModelV2: AnyRDDocument{
//    static let collectionName: String = "models_V2"
//    static let orderByField: String = "name_lowercased"
//    
//    // Attributes
//    var id: String
//    var name: String
//    var nameLowercased: String // for search
//    var type: ModelTypeV2
//    var color: ModelColor
//    var material: ModelMaterial
//    var value: Double?
//    var brand: String?
//    var purchaseLocation: String?
//    var datePurchased: String?
//    
//    // Items
//    var itemIds: [String]
//    var availableItemCount: Int
//    
//    // Images
//    var image: RDImage
//    
//    // Description
//    var description: String
//    var isEssential: Bool
//    
//    init(id: String,
//         name: String,
//         nameLowercased: String,
//         type: ModelTypeV2,
//         color: ModelColor,
//         material: ModelMaterial,
//         value: Double? = nil,
//         brand: String? = nil,
//         purchaseLocation: String? = nil,
//         datePurchased: String? = nil,
//         itemIds: [String],
//         availableItemCount: Int,
//         image: RDImage,
//         description: String = "",
//         isEssential: Bool
//    ) {
//        self.id = id
//        self.name = name
//        self.nameLowercased = nameLowercased
//        self.type = type
//        self.color = color
//        self.material = material
//        self.value = value
//        self.brand = brand
//        self.purchaseLocation = purchaseLocation
//        self.datePurchased = datePurchased
//        self.itemIds = itemIds
//        self.availableItemCount = availableItemCount
//        self.image = image
//        self.description = description
//        self.isEssential = isEssential
//    }
//    
//    enum CodingKeys: String, CodingKey {
//        case id, name, type, color, material, value, brand, description
//        case nameLowercased = "name_lowercased"
//        case purchaseLocation = "purchase_location"
//        case datePurchased = "date_purchased"
//        case itemIds = "item_ids"
//        case availableItemCount = "available_item_count"
//        case image = "primary_image"
//        case isEssential = "is_essential"
//    }
//}
//
//
