//
//  RDImage.swift
//  RedDoor
//
//  Created by Quinn Liu on 8/14/25.
//

import Foundation
import PhotosUI
import SwiftUI

// MARK: RDImageType

enum RDImageType: String, Codable {
    case model_primary, model_secondary, item, rd_list, dirty, misc, delete
    case roomBefore, roomAfter, listV2
    case accessory

    var storagePath: String? {
        switch self {
        case .roomAfter, .roomBefore:
            "rooms_images"
        case .listV2:
            "list_v2_images"
        case .model_primary, .model_secondary:
            "model_images"
        case .item:
            "item_images"
        case .rd_list:
            "rd_lists"
        case .misc:
            "misc"
        case .accessory:
            "accessory_images"
        case .dirty, .delete:
            nil // no path for dirty or delete
        }
    }
}

// MARK: RDImage

struct RDImage: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var imageType: RDImageType = .dirty
    var documentId: String? = nil
    var imageURL: URL? = nil
    var thumbnailURL: URL? = nil
    var uiImage: UIImage? = nil

    enum CodingKeys: String, CodingKey {
        case id, imageURL, imageType
        case documentId = "document_id"
        case thumbnailURL = "thumbnail_url"
    }
}

extension RDImage {
    var imageExists: Bool {
        return !(imageURL == nil && uiImage == nil)
    }
}
