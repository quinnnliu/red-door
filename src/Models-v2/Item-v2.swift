//
//  Item-v2.swift
//  RedDoor
//
//  Created by Quinn Liu on 4/25/26.
//
import SwiftUI


struct ItemV2: RDDocument {
    static let collectionName: String = "items_v2"
    static let orderByField: String = "name_lowercased"
    static let searchField: String = "name_lowercased"

    var id: String
    var modelId: String
    var groupId: String?

    var displayName: String
    var nameLowercased: String // for search
    var primaryImage: RDImage
    var secondaryImages: [RDImage]?
    var type: ItemType
    var color: ItemColor
    var material: ItemMaterial
    var value: Double?
    var brand: String?
    var purchaseLocation: String?
    var datePurchased: String?
    var status: LocationStatus
    var locationId: String
    var attention: Bool
    var attentionDescription: String?
    var description: String
    var essentialGroupId: String?

    init(
        id: String,
        modelId: String,
        groupId: String? = nil,
        displayName: String,
        primaryImage: RDImage,
        secondaryImages: [RDImage]? = nil,
        type: ItemType,
        color: ItemColor,
        material: ItemMaterial,
        value: Double? = nil,
        brand: String? = nil,
        purchaseLocation: String? = nil,
        datePurchased: String? = nil,
        status: LocationStatus = .inStorage,
        locationId: String = Warehouse.warehouse1.id, // TODO: non-default warehouse (select where they should be stored)
        attention: Bool,
        attentionDescription: String? = nil,
        description: String,
        essentialGroupId: String? = nil
    ) {
        self.id = id
        self.modelId = modelId
        self.groupId = groupId
        self.displayName = displayName
        self.nameLowercased = displayName.lowercased()
        self.primaryImage = primaryImage
        self.secondaryImages = secondaryImages
        self.type = type
        self.color = color
        self.material = material
        self.value = value
        self.brand = brand
        self.purchaseLocation = purchaseLocation
        self.datePurchased = datePurchased
        self.status = status
        self.locationId = locationId
        self.attention = attention
        self.attentionDescription = attentionDescription
        self.description = description
        self.essentialGroupId = essentialGroupId
    }

    init(item: ItemV2) {
        self.id = UUID().uuidString
        self.modelId = item.modelId
        self.groupId = item.groupId
        self.displayName = item.displayName
        self.nameLowercased = item.nameLowercased
        self.primaryImage = item.primaryImage
        self.secondaryImages = item.secondaryImages
        self.type = item.type
        self.color = item.color
        self.material = item.material
        self.value = item.value
        self.brand = item.brand
        self.purchaseLocation = item.purchaseLocation
        self.datePurchased = item.datePurchased
        self.status = item.status
        self.locationId = item.locationId
        self.attention = item.attention
        self.attentionDescription = item.attentionDescription
        self.description = item.description
        self.essentialGroupId = item.essentialGroupId
    }

    enum CodingKeys: String, CodingKey {
        case modelId = "model_id"
        case status = "status"
        case locationId = "location_id"
        case id, attention, type, color, material, value, brand, description
        case attentionDescription = "attention_description"
        case nameLowercased = "name_lowercased"
        case purchaseLocation = "purchase_location"
        case datePurchased = "date_purchased"
        case essentialGroupId = "essential_group_id"
        case primaryImage = "primary_image"
        case secondaryImages = "secondary_images"
        case displayName = "display_name"
    }
}

enum ItemType: String, Codable, CaseIterable {
    case chair = "Chair"
    case desk = "Desk"
    case table = "Table"
    case lamp = "Lamp"
    case accessories = "Accessories"
    case misc = "Miscellaneous"

    var title: String { rawValue }

    var icon: String {
        switch self {
        case .chair:
            SFSymbols.chairFill
        case .desk:
            SFSymbols.deskFill
        case .table:
            SFSymbols.tableFill
        case .lamp:
            SFSymbols.lampFill
        case .accessories:
            SFSymbols.pencil // TODO: find a better icon
        case .misc:
            SFSymbols.ellipsis
        }

    }
}

enum ItemColor: String, Codable, CaseIterable {
    case black = "Black"
    case blue = "Blue"
    case brown = "Brown"
    case cyan = "Cyan"
    case gray = "Gray"
    case green = "Green"
    case indigo = "Indigo"
    case mint = "Mint"
    case orange = "Orange"
    case pink = "Pink"
    case purple = "Purple"
    case red = "Red"
    case teal = "Teal"
    case white = "White"
    case yellow = "Yellow"
    case clear = "Clear"

    var title: String { rawValue }

    var color: Color {
        switch self {
        case .black: return .black
        case .blue: return .blue
        case .brown: return .brown
        case .cyan: return .cyan
        case .gray: return .gray
        case .green: return .green
        case .indigo: return .indigo
        case .mint: return .mint
        case .orange: return .orange
        case .pink: return .pink
        case .purple: return .purple
        case .red: return .red
        case .teal: return .teal
        case .white: return .white
        case .yellow: return .yellow
        case .clear: return .clear
        }
    }
}

enum ItemMaterial: String, Codable, CaseIterable {
    case acrylic = "Acrylic"
    case bamboo = "Bamboo"
    case cane = "Cane"
    case concrete = "Concrete"
    case engineeredWood = "Engineered Wood"
    case fabric = "Fabric"
    case glass = "Glass"
    case laminates = "Laminates"
    case leather = "Leather"
    case marble = "Marble"
    case metal = "Metal"
    case none = "None"
    case plastic = "Plastic"
    case rattan = "Rattan"
    case resin = "Resin"
    case stainlessSteel = "Stainless Steel"
    case stone = "Stone"
    case veneer = "Veneer"
    case vinyl = "Vinyl"
    case wicker = "Wicker"
    case wood = "Wood"
    case other = "Other"

    var title: String { rawValue }
}
