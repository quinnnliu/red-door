//
//  FirebaseImageManager.swift
//  RedDoor
//
//  Created by Quinn Liu on 8/31/25.
//

import Firebase
import FirebaseStorage
import Foundation

final class FirebaseImageManager {
    static let shared = FirebaseImageManager()
    static let storageRef = Storage.storage().reference()

    /// Source images downloaded for `.copy` uploads, so creating N copies of one
    /// image downloads it once.
    private let copySourceCache = NSCache<NSURL, UIImage>()

    private init() {}

    // MARK: - Resolve

    /// Brings an image up to date for a save.
    ///
    /// - `persist` is what the document should store: `updated`, uploaded first if it's dirty.
    /// - `cleanup` is the original's stored file when `updated` no longer points at it
    ///   (replaced or cleared). Delete it with `delete(_:type:)` only *after* the
    ///   document write commits, so a failed write never leaves the document pointing
    ///   at a deleted file.
    func resolve(
        original: RDImage?,
        updated: RDImage?,
        type: RDImageType
    ) async throws -> (persist: RDImage?, cleanup: RDImage?) {
        let persist: RDImage?
        if let updated, updated.isDirty {
            persist = try await upload(updated, type: type)
        } else {
            persist = updated
        }

        var cleanup: RDImage?
        if let original, original.hasStoredFile, original.id != updated?.id {
            cleanup = original
        }

        return (persist, cleanup)
    }

    // MARK: - Uploading

    enum ImageUploadError: Error {
        case cannotCompress, cannotLoadSource
    }

    private static let fullMaxDimension: CGFloat = 800
    private static let thumbMaxDimension: CGFloat = 200
    private static let jpegCompressionQuality: CGFloat = 0.50

    // MARK: upload()

    /// Uploads a dirty image's content into `rdImage.documentId`'s folder under
    /// `type`'s storage path. Returns the image with its URLs filled in and no longer dirty.
    func upload(_ rdImage: RDImage, type: RDImageType) async throws -> RDImage {
        guard let source = rdImage.dirtyContentSource else { return rdImage }
        guard let storagePath = type.storagePath else {
            print("Upload skipped: \(type) has no storage path")
            return rdImage
        }

        let uiImage = try await loadUIImage(from: source)

        let documentId = rdImage.documentId
        let fullRef = FirebaseImageManager.storageRef.child(storagePath).child(documentId).child(rdImage.id)
        let thumbRef = FirebaseImageManager.storageRef.child(storagePath).child(documentId).child("\(rdImage.id)_thumb")

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        guard let fullData = uiImage.resized(toMaxDimension: Self.fullMaxDimension).jpegData(compressionQuality: Self.jpegCompressionQuality) else { throw ImageUploadError.cannotCompress }
        guard let thumbData = uiImage.resized(toMaxDimension: Self.thumbMaxDimension).jpegData(compressionQuality: Self.jpegCompressionQuality) else { throw ImageUploadError.cannotCompress }

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask { _ = try await fullRef.putDataAsync(fullData, metadata: metadata) }
            group.addTask { _ = try await thumbRef.putDataAsync(thumbData, metadata: metadata) }
            try await group.waitForAll()
        }

        async let fullURL = fullRef.downloadURL()
        async let thumbURL = thumbRef.downloadURL()
        let (resolvedFullURL, resolvedThumbURL) = try await (fullURL, thumbURL)

        var updated = rdImage
        updated.imageURL = resolvedFullURL
        updated.thumbnailURL = resolvedThumbURL
        updated.imageType = type
        updated.dirtyContentSource = nil
        return updated
    }

    private func loadUIImage(from source: RDImage.DirtyContentSource) async throws -> UIImage {
        switch source {
        case .picked(let uiImage):
            return uiImage
        case .copy(let url):
            if let cached = copySourceCache.object(forKey: url as NSURL) { return cached }

            let (data, response) = try await URLSession.shared.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200,
                  let uiImage = UIImage(data: data) else {
                throw ImageUploadError.cannotLoadSource
            }
            copySourceCache.setObject(uiImage, forKey: url as NSURL)
            return uiImage
        }
    }

    // MARK: - Delete Images

    enum ImageDeleteError: Error {
        case getStoragePathError
    }

    // MARK: delete()

    func delete(_ rdImage: RDImage, type: RDImageType) async throws {
        guard let storagePath = type.storagePath else {
            print("Delete skipped: \(type) has no storage path")
            throw ImageDeleteError.getStoragePathError
        }

        let documentId = rdImage.documentId
        let fullRef = FirebaseImageManager.storageRef.child(storagePath).child(documentId).child(rdImage.id)
        let thumbRef = FirebaseImageManager.storageRef.child(storagePath).child(documentId).child("\(rdImage.id)_thumb")

        do {
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask { try await fullRef.delete() }
                group.addTask { try await thumbRef.delete() }
                try await group.waitForAll()
            }
        } catch {
            print("Error deleting imageID: \(error)")
        }
    }

    // MARK: deleteDocumentImages()

    /// Deletes every file in an owner's folder. `ownerId` is the same value images
    /// carry as `documentId` (for rooms, `RoomV2.imageOwnerId`).
    func deleteDocumentImages(ownerId: String, imageType: RDImageType) async throws {
        guard let storagePath = imageType.storagePath else { throw ImageDeleteError.getStoragePathError }
        let folderRef = FirebaseImageManager.storageRef.child(storagePath).child(ownerId)
        let result = try await folderRef.listAll()
        try await withThrowingTaskGroup(of: Void.self) { group in
            for item in result.items {
                group.addTask { try await item.delete() }
            }
            try await group.waitForAll()
        }
    }
}
