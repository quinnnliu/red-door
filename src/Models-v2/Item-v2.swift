//
//  Item-v2.swift
//  RedDoor
//
//  Created by Quinn Liu on 4/25/26.
//
import SwiftUI

enum ItemStatus: String, Codable {
    case inPullList      = "in_pull_list"
    case inStorage       = "in_storage"
    case inInstalledList = "in_installed_list"

    var displayTitle: String {
        switch self {
        case .inPullList:      return "On Pull List"
        case .inStorage:       return "In Storage"
        case .inInstalledList: return "Installed"
        }
    }
}

struct ItemV2: AnyRDDocument {
    static let collectionName: String = "items_v2"
    static let orderByField: String = "name_lowercased"
    static let searchField: String = "name_lowercased"

    var id: String
    var modelId: String
    var groupId: String?

    var name: String
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
    var status: ItemStatus
    var locationId: String
    var attention: Bool
    var attentionDescription: String?
    var description: String
    var isEssential: Bool

    init(
        id: String,
        modelId: String,
        groupId: String? = nil,
        name: String,
        primaryImage: RDImage,
        secondaryImages: [RDImage]? = nil,
        type: ItemType,
        color: ItemColor,
        material: ItemMaterial,
        value: Double? = nil,
        brand: String? = nil,
        purchaseLocation: String? = nil,
        datePurchased: String? = nil,
        status: ItemStatus = .inStorage,
        locationId: String = Warehouse.warehouse1.id,
        attention: Bool,
        attentionDescription: String? = nil,
        description: String,
        isEssential: Bool
    ) {
        self.id = id
        self.modelId = modelId
        self.groupId = groupId
        self.name = name
        self.nameLowercased = name.lowercased()
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
        self.isEssential = isEssential
    }

    init(item: ItemV2) {
        self.id = UUID().uuidString
        self.modelId = item.modelId
        self.groupId = item.groupId
        self.name = item.name
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
        self.isEssential = item.isEssential
    }

    enum CodingKeys: String, CodingKey {
        case modelId = "model_id"
        case status = "status"
        case locationId = "location_id"
        case id, attention, type, color, material, value, brand, description, name
        case attentionDescription = "attention_description"
        case nameLowercased = "name_lowercased"
        case purchaseLocation = "purchase_location"
        case datePurchased = "date_purchased"
        case isEssential = "is_essential"
        case primaryImage = "primary_image"
        case secondaryImages = "secondary_images"
    }

    // Backwards compatibility: old Firestore documents have `is_available` + `list_id` instead of `status` + `location_id`.
    private enum LegacyCodingKeys: String, CodingKey {
        case listId = "list_id"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        id                = try c.decode(String.self,    forKey: .id)
        modelId           = try c.decode(String.self,    forKey: .modelId)
        groupId           = nil
        name              = try c.decode(String.self,    forKey: .name)
        nameLowercased    = try c.decode(String.self,    forKey: .nameLowercased)
        primaryImage      = try c.decode(RDImage.self,   forKey: .primaryImage)
        secondaryImages   = try c.decodeIfPresent([RDImage].self, forKey: .secondaryImages)
        type              = try c.decode(ItemType.self,  forKey: .type)
        color             = try c.decode(ItemColor.self, forKey: .color)
        material          = try c.decode(ItemMaterial.self, forKey: .material)
        value             = try c.decodeIfPresent(Double.self,  forKey: .value)
        brand             = try c.decodeIfPresent(String.self,  forKey: .brand)
        purchaseLocation  = try c.decodeIfPresent(String.self,  forKey: .purchaseLocation)
        datePurchased     = try c.decodeIfPresent(String.self,  forKey: .datePurchased)
        attention         = try c.decode(Bool.self, forKey: .attention)
        attentionDescription = try c.decodeIfPresent(String.self, forKey: .attentionDescription)
        description       = try c.decode(String.self, forKey: .description)
        isEssential       = try c.decode(Bool.self, forKey: .isEssential)

        status = try c.decodeIfPresent(ItemStatus.self, forKey: .status) ?? .inStorage

        if let locationId = try c.decodeIfPresent(String.self, forKey: .locationId) {
            self.locationId = locationId
        } else {
            let legacy = try decoder.container(keyedBy: LegacyCodingKeys.self)
            self.locationId = try legacy.decodeIfPresent(String.self, forKey: .listId) ?? Warehouse.warehouse1.id
        }
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
