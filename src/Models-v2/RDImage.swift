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

/// The storage category an uploaded image belongs to. Says nothing about whether
/// the image still needs uploading; see `RDImage.dirtyContentSource`.
enum RDImageType: String, Codable {
    case model_primary, model_secondary, item, rd_list, misc
    case roomBefore, roomAfter, listV2
    case accessory
    /// No storage category yet: a placeholder with no image, or a picked image
    /// that hasn't been uploaded.
    case empty

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
        case .empty:
            nil // no path until the image is uploaded
        }
    }
}

// MARK: RDImage

/// An image owned by exactly one document. `documentId` is that document's id
/// (for rooms, `RoomV2.imageOwnerId`) and names the storage folder holding the
/// file. Images are never shared between documents; creating a document from
/// another one goes through `copy(to:)`.
struct RDImage: Identifiable, Codable, Hashable {
    let id: String
    let documentId: String
    var imageType: RDImageType
    var imageURL: URL?
    var thumbnailURL: URL?

    /// Where the bytes for a pending upload come from. Never persisted. `nil`
    /// means there is nothing to upload.
    var dirtyContentSource: DirtyContentSource?

    enum DirtyContentSource: Hashable {
        case picked(UIImage)
        case copy(from: URL)
    }

    enum CodingKeys: String, CodingKey {
        case id, imageURL, imageType
        case documentId = "document_id"
        case thumbnailURL = "thumbnail_url"
    }

    // MARK: Initializers

    /// A freshly picked image, uploaded into `documentId`'s folder on save.
    init(uiImage: UIImage, documentId: String) {
        self.init(
            id: UUID().uuidString,
            documentId: documentId,
            imageType: .empty,
            dirtyContentSource: .picked(uiImage)
        )
    }

    /// No image yet, for models whose image isn't optional.
    static func empty(for documentId: String) -> RDImage {
        RDImage(id: UUID().uuidString, documentId: documentId, imageType: .empty)
    }

    private init(
        id: String,
        documentId: String,
        imageType: RDImageType,
        imageURL: URL? = nil,
        thumbnailURL: URL? = nil,
        dirtyContentSource: DirtyContentSource? = nil
    ) {
        self.id = id
        self.documentId = documentId
        self.imageType = imageType
        self.imageURL = imageURL
        self.thumbnailURL = thumbnailURL
        self.dirtyContentSource = dirtyContentSource
    }
}

// MARK: - Derived State

extension RDImage {
    var isDirty: Bool { dirtyContentSource != nil }

    /// The picked image, if this one hasn't been uploaded yet.
    var uiImage: UIImage? {
        if case .picked(let uiImage) = dirtyContentSource { return uiImage }
        return nil
    }

    /// A file for this image exists in Storage.
    var hasStoredFile: Bool { imageURL != nil && !isDirty }

    var imageExists: Bool { imageURL != nil || isDirty }
}

// MARK: - Copy

extension RDImage {
    /// A new image, owned by `documentId`, that uploads its own file on save.
    /// Use whenever a document is created from another one. Returns `nil` when
    /// there is nothing to copy.
    ///
    /// The source's URLs are kept so the copy displays until it's uploaded.
    func copy(to documentId: String) -> RDImage? {
        let source: DirtyContentSource
        if let uiImage {
            source = .picked(uiImage)
        } else if let imageURL {
            source = .copy(from: imageURL)
        } else {
            return nil
        }

        return RDImage(
            id: UUID().uuidString,
            documentId: documentId,
            imageType: imageType,
            imageURL: imageURL,
            thumbnailURL: thumbnailURL,
            dirtyContentSource: source
        )
    }
}
