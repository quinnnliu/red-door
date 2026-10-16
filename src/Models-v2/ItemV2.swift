//
//  Item-v2.swift
//  RedDoor
//
//  Created by Quinn Liu on 4/25/26.
//
import SwiftUI


struct ItemV2: RDDocument {
    static let collectionName: String = "items_v2"
    static let orderByField: String = "base_name_lowercased"
    static let searchField: String = "base_name_lowercased"

    var id: String
    var modelId: String
    var groupId: String?

    var baseName: String
    var baseNameLowercased: String // for search
    var primaryImage: RDImage
    var secondaryImages: [RDImage]?
    var type: ItemType
    var color: ItemColor
    var material: ItemMaterial
    var value: Double?
    var brand: String?
    var purchaseLocation: String?
    var datePurchased: String?
    var location: DocumentLocation
    var attention: Bool
    var attentionDescription: String?
    var description: String
    @NullEncodable var essentialGroupId: String?
    var itemNumber: Int
    var nickname: String?
    var dimensions: ItemDimensions?

    init(
        id: String,
        modelId: String,
        groupId: String? = nil,
        baseName: String,
        primaryImage: RDImage,
        secondaryImages: [RDImage]? = nil,
        type: ItemType,
        color: ItemColor,
        material: ItemMaterial,
        value: Double? = nil,
        brand: String? = nil,
        purchaseLocation: String? = nil,
        datePurchased: String? = nil,
        location: DocumentLocation,
        attention: Bool,
        attentionDescription: String? = nil,
        description: String,
        essentialGroupId: String? = nil,
        itemNumber: Int = 0,
        nickname: String? = nil,
        dimensions: ItemDimensions? = nil
    ) {
        self.id = id
        self.modelId = modelId
        self.groupId = groupId
        self.baseName = baseName
        self.baseNameLowercased = baseName.lowercased()
        self.primaryImage = primaryImage
        self.secondaryImages = secondaryImages
        self.type = type
        self.color = color
        self.material = material
        self.value = value
        self.brand = brand
        self.purchaseLocation = purchaseLocation
        self.datePurchased = datePurchased
        self.location = location
        self.attention = attention
        self.attentionDescription = attentionDescription
        self.description = description
        self.essentialGroupId = essentialGroupId
        self.itemNumber = itemNumber
        self.nickname = nickname
        self.dimensions = dimensions
    }

    // Init for copying an item from another
    init(item: ItemV2) {
        let newId = UUID().uuidString
        self.id = newId
        self.modelId = item.modelId
        self.groupId = item.groupId
        self.baseName = item.baseName
        self.baseNameLowercased = item.baseNameLowercased
        self.primaryImage = item.primaryImage.copy(to: newId) ?? .empty(for: newId)
        self.secondaryImages = item.secondaryImages?.compactMap { $0.copy(to: newId) }
        self.type = item.type
        self.color = item.color
        self.material = item.material
        self.value = item.value
        self.brand = item.brand
        self.purchaseLocation = item.purchaseLocation
        self.datePurchased = item.datePurchased
        self.location = item.location
        self.attention = item.attention
        self.attentionDescription = item.attentionDescription
        self.description = item.description
        self.essentialGroupId = item.essentialGroupId
        self.itemNumber = item.itemNumber
        self.nickname = item.nickname
        self.dimensions = item.dimensions
    }

    enum CodingKeys: String, CodingKey {
        case modelId = "model_id"
        case location
        case id, attention, type, color, material, value, brand, description
        case attentionDescription = "attention_description"
        case baseNameLowercased = "base_name_lowercased"
        case purchaseLocation = "purchase_location"
        case datePurchased = "date_purchased"
        case essentialGroupId = "essential_group_id"
        case itemNumber = "item_number"
        case nickname
        case primaryImage = "primary_image"
        case secondaryImages = "secondary_images"
        case baseName = "base_name"
    }
}

// MARK: - Delete

extension ItemV2 {
    var deleteErrorReason: ItemDeleteError? {
        if !location.status.isAvailable { return .assignedToList }
        if essentialGroupId != nil { return .inEssentialsGroup }
        return nil
    }

    var canDelete: Bool { deleteErrorReason == nil }
}

enum ItemType: String, Filterable, CaseIterable {
    case accentChair = "Accent Chair"
    case barCart = "Bar Cart"
    case bed = "Bed"
    case bench = "Bench"
    case boxspring = "Boxspring"
    case coffeeTable = "Coffee Table"
    case console = "Console"
    case dayBed = "Day Bed"
    case decor = "Decor"
    case desk = "Desk"
    case deskChair = "Desk Chair"
    case diningChair = "Dining Chair"
    case diningTable = "Dining Table"
    case dresser = "Dresser"
    case endTable = "End Table"
    case framedArt = "Framed Art"
    case lamp = "Lamp"
    case nightstand = "Nightstand"
    case ottoman = "Ottoman"
    case outdoorFurniture = "Outdoor Furniture"
    case rug = "Rug"
    case sofa = "Sofa"
    case stool = "Stool"
    case topper = "Topper"
    case unframedArt = "Unframed Art"
    case misc = "Miscellaneous"

    var title: String { rawValue }
    var icon: String? {
        switch self {
        case .dresser:
            SFSymbols.cabinetFill
        case .diningTable, .coffeeTable, .console, .endTable, .nightstand, .barCart, .desk:
            SFSymbols.tableFill
        case .sofa:
            SFSymbols.couchFill
        case .stool, .deskChair, .diningChair, .bench, .ottoman:
            SFSymbols.chairFill
        case .accentChair:
            SFSymbols.chairLoungeFill
        case .lamp:
            SFSymbols.lampFill
        case .framedArt:
            SFSymbols.art
        case .unframedArt:
            SFSymbols.photo
        case .decor:
            SFSymbols.sparkles
        case .bed, .boxspring, .dayBed:
            SFSymbols.bedDoubleFill
        case .outdoorFurniture:
            SFSymbols.sunLefthalfFilled
        case .rug, .topper:
            SFSymbols.rectangle
        case .misc:
            nil
        }
    }
    var color: Color? { nil }
}

enum ItemColor: String, Filterable {
    // Declaration order is the display order (CaseIterable): rainbow first, then muted/neutral tones.
    case red = "Red"
    case orange = "Orange"
    case yellow = "Yellow"
    case green = "Green"
    case mint = "Mint"
    case teal = "Teal"
    case cyan = "Cyan"
    case blue = "Blue"
    case indigo = "Indigo"
    case purple = "Purple"
    case pink = "Pink"
    case brown = "Brown"
    case brass = "Brass"
    case tan = "Tan"
    case white = "White"
    case clear = "Clear"
    case silver = "Silver"
    case gray = "Gray"
    case black = "Black"

    var title: String { rawValue }
    var color: Color? {
        switch self {
        case .black: return .black
        case .blue: return .blue
        case .brass: return Color(red: 0.71, green: 0.65, blue: 0.26)
        case .brown: return .brown
        case .clear: return .clear
        case .cyan: return .cyan
        case .gray: return .gray
        case .green: return .green
        case .indigo: return .indigo
        case .mint: return .mint
        case .orange: return .orange
        case .pink: return .pink
        case .purple: return .purple
        case .red: return .red
        case .silver: return Color(red: 0.75, green: 0.75, blue: 0.75)
        case .tan: return Color(red: 0.82, green: 0.71, blue: 0.55)
        case .teal: return .teal
        case .white: return .white
        case .yellow: return .yellow
        }
    }
    var icon: String? { nil }
}

enum ItemMaterial: String, Codable, Filterable {
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
    case velvet = "Velvet"
    case veneer = "Veneer"
    case vinyl = "Vinyl"
    case wicker = "Wicker"
    case wood = "Wood"
    case other = "Other"

    var title: String { rawValue }
    
    var icon: String? { nil }
    var color: Color? { nil }
}
