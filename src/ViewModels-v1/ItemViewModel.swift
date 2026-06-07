//
//  ItemViewModel.swift
//  RedDoor
//
//  Created by Quinn Liu on 1/7/25.
//

import FirebaseCore
import FirebaseFirestore
import FirebaseStorage
import Foundation

@Observable
class ItemViewModel {
    let db = Firestore.firestore()

    var selectedItem: Item
    let itemRef: DocumentReference

    init(selectedItem: Item) {
        self.selectedItem = selectedItem
        self.itemRef = db.collection("items").document(selectedItem.id)
    }

    // MARK: Get Item Model
    func getItemModel(modelId: String) async throws -> Model {
        let documentSnapshot = try await db.collection("models").document(modelId).getDocument()
        guard documentSnapshot.exists else {
            throw NSError(domain: "", code: 404, userInfo: [NSLocalizedDescriptionKey: "Model (\(modelId)) not found."])
        }
        return try documentSnapshot.data(as: Model.self)
    }

    // MARK: Delete Item
    func deleteItem() async {
        let batch = db.batch()

        let modelRef = db.collection("models").document(selectedItem.modelId)

        batch.deleteDocument(itemRef)
        batch.updateData([
            "itemIds": FieldValue.arrayRemove([selectedItem.id]),
            "availableItemCount": FieldValue.increment(Int64(-1)),
        ], forDocument: modelRef)

        do {
            try await batch.commit()
        } catch {
            print("Error committing batch delete for item \(selectedItem.id): \(error)")
        }
    }

    // MARK: Unstage Item
    func unstageItem(warehouseId: String) async -> Item {
        let modelRef = db.collection("models").document(selectedItem.modelId)
        let batch = db.batch()

        selectedItem.listId = warehouseId
        selectedItem.isAvailable = true
        
        batch.updateData(["listId": warehouseId, "isAvailable": true], forDocument: itemRef)
        batch.updateData(["availableItemCount": FieldValue.increment(Int64(1))], forDocument: modelRef)
        
        do {
            try await batch.commit()
        } catch {
            print("Error unstaging item: \(error.localizedDescription)")
        }
        return selectedItem
    }

    // MARK: Revert Item Unstage
    func revertItemUnstage(listId: String) async -> Item {
        let modelRef = db.collection("models").document(selectedItem.modelId)
        let batch = db.batch()

        selectedItem.listId = listId
        selectedItem.isAvailable = false
        
        batch.updateData(["listId": listId, "isAvailable": false], forDocument: itemRef)
        batch.updateData(["availableItemCount": FieldValue.increment(Int64(-1))], forDocument: modelRef)

        do {
            try await batch.commit()
        } catch {
            print("Error reverting item unstage: \(error.localizedDescription)")
        }
        return selectedItem
    }

    // MARK: Update Item
    func updateItem() async {
        do {
            if var image = selectedItem.image, image.imageType == .dirty {
                image.objectId = selectedItem.id
                selectedItem.image = try await FirebaseImageManager.shared.updateImage(image, resultImageType: .item) ?? RDImage()
            }
            try itemRef.setData(from: selectedItem)
        } catch {
            print("Error updating item: \(error)")
        }
    }
}
