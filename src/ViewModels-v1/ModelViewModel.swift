//
//  ModelViewModel.swift
//  RedDoor
//
//  Created by Quinn Liu on 8/22/24.
//

import FirebaseCore
import FirebaseFirestore
import FirebaseStorage
import Foundation
import PhotosUI
import SwiftUI

@Observable
final class ModelViewModel {
    var selectedModel: Model
    var itemCount: Int
    var items: [Item] = []

    let db = Firestore.firestore()
    let modelDocumentRef: DocumentReference
    let storageRef: StorageReference
    private let imageManager: FirebaseImageManager

    init(model: Model = Model(), imageManager: FirebaseImageManager = FirebaseImageManager.shared) {
        selectedModel = model
        if model.itemIds.isEmpty {
            itemCount = 1
        } else {
            itemCount = model.itemIds.count
        }

        modelDocumentRef = db.collection("models").document(model.id)
        storageRef = Storage.storage().reference().child("model_images").child(model.id)

        self.imageManager = imageManager
    }

    // MARK: Create Single Model Item

    func createSingleModelItem() async throws {
        let item = Item(modelId: selectedModel.id)
        selectedModel.itemIds.append(item.id)
        selectedModel.availableItemCount += 1

        try await modelDocumentRef.updateData([
            "availableItemCount": selectedModel.availableItemCount,
            "itemIds": selectedModel.itemIds,
        ])

        let itemRef = db.collection("items").document(item.id)
        try itemRef.setData(from: item)
    }

    // MARK: Get Model Items

    func getModelItems() async throws -> [Item] {
        let query: Query = db.collection("items")
            .whereField("modelId", isEqualTo: selectedModel.id)

        // `getDocuments()` now has an async version
        let snapshot = try await query.getDocuments()

        let items: [Item] = try snapshot.documents.map { document in
            try document.data(as: Item.self)
        }

        return items
    }

    // MARK: Create Items

    private func createModelItems() async throws {
        let batch = db.batch()
        let collectionRef = db.collection("items")

        var itemToCreate = 0
        if itemCount > selectedModel.itemIds.count {
            itemToCreate = itemCount - selectedModel.itemIds.count
        } else {
            itemToCreate = 0
        }

        for _ in 0 ..< itemToCreate {
            let item = Item(modelId: selectedModel.id)
            selectedModel.itemIds.append(item.id)
            selectedModel.availableItemCount += 1

            let itemRef = collectionRef.document(item.id)
            try batch.setData(from: item, forDocument: itemRef)
        }

        try await batch.commit()
    }

    // MARK: Update Priamry Image

    func updatePrimaryImage(image: RDImage) async {
        if let uiImage = image.uiImage {
            let imageRef = storageRef.child(image.id)
            guard let imageData = uiImage.jpegData(compressionQuality: 0.3) else {
                print("Error converting UIImage to jpegData")
                return
            }

            let metaData = StorageMetadata()
            metaData.contentType = "image/jpeg"

            do {
                _ = try await imageRef.putDataAsync(imageData, metadata: metaData)
                let imageURL = try await imageRef.downloadURL()
                selectedModel.primaryImage.imageURL = imageURL
                if selectedModel.primaryImage.imageType == .dirty {
                    selectedModel.primaryImage.imageType = .model_primary
                }

            } catch {
                print("Error occurred when uploading image \(error.localizedDescription)")
            }

        } else {
            print("Error occurred when uploading image: no RDImage.uiImage = nil")
        }
    }

    // MARK: Update Model

    @MainActor
    func updateModel() async {
        do {
            // update primary image
            selectedModel.primaryImage.objectId = selectedModel.id
            let newPrimaryImage = try await imageManager.updateImage(
                selectedModel.primaryImage,
                resultImageType: .model_primary
            )

            // update secondary images
            for index in selectedModel.secondaryImages.indices {
                selectedModel.secondaryImages[index].objectId = selectedModel.id
            }
            let newSecondaryImages = try await imageManager.updateImages(
                selectedModel.secondaryImages,
                resultImageType: .model_secondary
            )

            // create items
            let itemIdCount = selectedModel.itemIds.count
            if itemCount != itemIdCount && itemIdCount == 0 { // create items if none exist
                try await createModelItems()
            }

            // fetch updated models
            items = try await getModelItems()
            selectedModel.itemIds = items.map(\.id)

            // update model data
            selectedModel.nameLowercased = selectedModel.name.lowercased()
            if let newPrimaryImage {
                selectedModel.primaryImage = newPrimaryImage
            } else {
                selectedModel.primaryImage = RDImage()
            }
            selectedModel.secondaryImages = newSecondaryImages

            // Firestore update
            try modelDocumentRef.setData(from: selectedModel)
        } catch {
            print("Error updating model: \(error)")
        }
    }

    // MARK: Delete Model

    func deleteModel() async {
        do {
            // delete primary image
            selectedModel.primaryImage.objectId = selectedModel.id
            selectedModel.primaryImage.imageType = .delete
            _ = try await imageManager.updateImage(
                selectedModel.primaryImage,
                resultImageType: .model_primary
            )

            // delete secondary images
            for index in selectedModel.secondaryImages.indices {
                selectedModel.secondaryImages[index].objectId = selectedModel.id
                selectedModel.secondaryImages[index].imageType = .delete
            }
            _ = try await imageManager.updateImages(
                selectedModel.secondaryImages,
                resultImageType: .model_secondary
            )

            // delete items
            for itemId in selectedModel.itemIds {
                try await db.collection("items").document(itemId).delete()
            }

            // Firestore update
            try await modelDocumentRef.delete()

        } catch {
            print("Error deleting model: \(error)")
        }
    }
}
