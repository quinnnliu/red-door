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

    func updateImage(_ rdImage: RDImage, resultImageType: RDImageTypeEnum) async throws -> RDImage? {
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

    func updateImages(_ images: [RDImage], resultImageType: RDImageTypeEnum) async throws -> [RDImage] {
        let clean = images.filter { $0.imageType != .dirty }

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
        case notDirty, invalidType, noUIImage, cannotCompress, missingObjectId
    }

    private func validateUploadRDImage(_ rdImage: RDImage, uploadImageType: RDImageTypeEnum) throws -> (uiImage: UIImage, objectPath: String, objectId: String) {
        guard rdImage.imageType == .dirty else { throw ImageUploadError.notDirty }
        guard let objectPath = uploadImageType.objectPath else { throw ImageUploadError.invalidType }
        guard let uiImage = rdImage.uiImage else { throw ImageUploadError.noUIImage }
        guard let objectId = rdImage.objectId else { throw ImageUploadError.missingObjectId }

        return (uiImage, objectPath, objectId)
    }

    // MARK: uploadImage()

    func uploadImage(_ rdImage: RDImage, uploadImageType: RDImageTypeEnum) async throws -> RDImage {
        let (uiImage, objectPath, objectId): (UIImage, String, String)

        do {
            (uiImage, objectPath, objectId) = try validateUploadRDImage(rdImage, uploadImageType: uploadImageType)
        } catch {
            print("Upload skipped: \(error)")
            return rdImage
        }

        let storageRef = FirebaseImageManager.storageRef.child(objectPath).child(objectId).child(rdImage.id)

        let metaData = StorageMetadata()
        metaData.contentType = "image/jpeg"

        guard let imageData = uiImage.jpegData(compressionQuality: 0.5) else { throw ImageUploadError.cannotCompress }

        _ = try await storageRef.putDataAsync(imageData, metadata: metaData)
        let url = try await storageRef.downloadURL()

        var updated = rdImage
        updated.imageURL = url
        updated.imageType = uploadImageType
        updated.uiImage = nil
        return updated
    }

    // MARK: - Delete Images

    enum ImageDeleteError: Error {
        case getObjectPathError, missingObjectId
    }

    private func validateDeleteRDImage(_ rdImage: RDImage, deletedImageType: RDImageTypeEnum) throws -> (objectId: String, objectPath: String) {
        guard let objectId = rdImage.objectId else { throw ImageDeleteError.missingObjectId }
        guard let objectPath = deletedImageType.objectPath else { throw ImageDeleteError.getObjectPathError }

        return (objectId, objectPath)
    }

    // MARK: Delete Image

    func deleteImage(_ rdImage: RDImage, deletedImageType: RDImageTypeEnum) async throws {
        // delete image from storage
        let (objectId, objectPath): (String, String)

        do {
            (objectId, objectPath) = try validateDeleteRDImage(rdImage, deletedImageType: deletedImageType)
        } catch {
            print("Delete skipped: \(error)")
            throw error
        }

        var storageRef = FirebaseImageManager.storageRef.child(objectPath)
        storageRef = storageRef.child(objectId).child(rdImage.id)

        do {
            try await storageRef.delete()
        } catch {
            print("Error deleting imageID: \(error)")
        }
    }
}
