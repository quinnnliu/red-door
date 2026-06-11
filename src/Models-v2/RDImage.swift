//
//  RDImage.swift
//  RedDoor
//
//  Created by Quinn Liu on 8/14/25.
//

import Foundation
import PhotosUI
import SwiftUI

// MARK: RDImageTypeEnum

enum RDImageTypeEnum: String, Codable {
    case model_primary, model_secondary, item, rd_list, dirty, misc, delete
    case roomBefore, roomAfter, listV2

    var objectPath: String? {
        switch self {
        case .roomAfter, .roomBefore:
            "rooms"
        case .listV2:
            "list_v2"
        case .model_primary, .model_secondary:
            "model_images"
        case .item:
            "item_images"
        case .rd_list:
            "rd_lists"
        case .misc:
            "misc"
        case .dirty, .delete:
            nil // no path for dirty or delete
        }
    }
}

// MARK: RDImage

struct RDImage: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var imageType: RDImageTypeEnum = .dirty
    var objectId: String? = nil
    var imageURL: URL? = nil
    var uiImage: UIImage? = nil

    enum CodingKeys: String, CodingKey {
        case id, objectId, imageURL, imageType
    }
}

extension RDImage {
    var imageExists: Bool {
        return !(imageURL == nil && uiImage == nil)
    }
}
