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

    private init() {}

    // MARK: - Update Images

    // MARK: updateImage()

    func updateImage(_ rdImage: RDImage, resultImageType: RDImageType) async throws -> RDImage? {
        switch rdImage.imageType {
        case .dirty:
            return try await uploadImage(rdImage, uploadImageType: resultImageType)
        case .delete:
            try await deleteImage(rdImage, deletedImageType: resultImageType)
            return nil
        default:
            return rdImage
        }
    }

    // MARK: updateImages()

    func updateImages(_ images: [RDImage], resultImageType: RDImageType) async throws -> [RDImage] {
        let clean = images.filter { $0.imageType != .dirty && $0.imageType != .delete }

        let updated = try await withThrowingTaskGroup(of: RDImage?.self) { group in
            for image in images where image.imageType == .dirty || image.imageType == .delete {
                group.addTask {
                    try await self.updateImage(image, resultImageType: resultImageType)
                }
            }

            var updated: [RDImage] = []
            for try await result in group {
                if let image = result {
                    updated.append(image)
                }
            }

            return updated
        }

        return clean + updated
    }

    // MARK: - Uploading

    enum ImageUploadError: Error {
        case notDirty, invalidType, noUIImage, cannotCompress, missingDocumentId
    }

    private func validateUploadRDImage(_ rdImage: RDImage, uploadImageType: RDImageType) throws -> (uiImage: UIImage, storagePath: String, documentId: String) {
        guard rdImage.imageType == .dirty else { throw ImageUploadError.notDirty }
        guard let storagePath = uploadImageType.storagePath else { throw ImageUploadError.invalidType }
        guard let uiImage = rdImage.uiImage else { throw ImageUploadError.noUIImage }
        guard let documentId = rdImage.documentId else { throw ImageUploadError.missingDocumentId }

        return (uiImage, storagePath, documentId)
    }

    private static let fullMaxDimension: CGFloat = 1000
    private static let thumbMaxDimension: CGFloat = 250
    private static let jpegCompressionQuality: CGFloat = 0.55

    // MARK: uploadImage()

    func uploadImage(_ rdImage: RDImage, uploadImageType: RDImageType) async throws -> RDImage {
        let (uiImage, storagePath, documentId): (UIImage, String, String)

        do {
            (uiImage, storagePath, documentId) = try validateUploadRDImage(rdImage, uploadImageType: uploadImageType)
        } catch {
            print("Upload skipped: \(error)")
            return rdImage
        }

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
        updated.imageType = uploadImageType
        updated.uiImage = nil
        return updated
    }

    // MARK: - Delete Images

    enum ImageDeleteError: Error {
        case getStoragePathError, missingDocumentId
    }

    private func validateDeleteRDImage(_ rdImage: RDImage, deletedImageType: RDImageType) throws -> (documentId: String, storagePath: String) {
        guard let documentId = rdImage.documentId else { throw ImageDeleteError.missingDocumentId }
        guard let storagePath = deletedImageType.storagePath else { throw ImageDeleteError.getStoragePathError }

        return (documentId, storagePath)
    }

    // MARK: deleteImage()

    func deleteImage(_ rdImage: RDImage, deletedImageType: RDImageType) async throws {
        let (documentId, storagePath): (String, String)

        do {
            (documentId, storagePath) = try validateDeleteRDImage(rdImage, deletedImageType: deletedImageType)
        } catch {
            print("Delete skipped: \(error)")
            throw error
        }

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

    func deleteDocumentImages(document: any RDDocument, imageType: RDImageType) async throws {
        guard let storagePath = imageType.storagePath else { throw ImageDeleteError.getStoragePathError }
        let folderRef = FirebaseImageManager.storageRef.child(storagePath).child(document.id)
        let result = try await folderRef.listAll()
        try await withThrowingTaskGroup(of: Void.self) { group in
            for item in result.items {
                group.addTask { try await item.delete() }
            }
            try await group.waitForAll()
        }
    }
}
