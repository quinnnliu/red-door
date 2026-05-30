//
//  DocumentType.swift
//  RedDoor
//
//  Created by Quinn Liu on 3/29/25.
//

import Foundation

enum DocumentType: String, Codable {
    case model, item, pull_list, installed_list
//    case modelV2 = "model_V2"
    case itemV2 = "item_V2"
    case pullListV2 = "pull_list_V2"
    case installedListV2 = "installed_list_V2"

    var collectionString: String {
        switch self {
        case .model:
            return "models"
        case .item:
            return "items"
        case .pull_list:
            return "pull_lists"
        case .installed_list:
            return "installed_lists"
//        case .modelV2:
//            return "models_V2"
        case .itemV2:
            return "items_V2"
        case .pullListV2:
            return "pull_list_V2"
        case .installedListV2:
            return "installed_list_V2"
        }
    }

    var documentDataType: Codable.Type {
        switch self {
        case .model:
            return Model.self
        case .item:
            return Item.self
        case .pull_list, .installed_list:
            return RDList.self
//        case .modelV2:
//            return ModelV2.self
        case .itemV2:
            return ItemV2.self
        case .pullListV2, .installedListV2:
            return RDList.self
        }
    }

    var orderByField: String {
        switch self {
        case .model:
            return "nameLowercased"
        case .item:
            return "id"
        case .pull_list:
            return "createdDate"
        case .installed_list:
            return "installDate"
        case .pullListV2:
            return "created_date"
        case .installedListV2:
            return "install_date"
//        case .modelV2:
//            return "models_v2"
        case .itemV2:
            return "items_v2"
        }
    }
}
