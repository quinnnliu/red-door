//
//  ItemDetailsViewModel.swift
//  RedDoor
//
//  Created by Quinn Liu on 5/14/26.
//

import SwiftUI

@Observable
final class ItemDetailsViewModel {
    private let itemRepo: ItemRepository = ItemRepository()

    // MARK: Item State
    var item: ItemV2

    // MARK: View State
    var isLoading: Bool = false

    // Image Overlay
    var selectedRDImage: RDImage?
    var isImageSelected: Bool = false

    init(item: ItemV2) {
        self.item = item
    }

    func updateItem() async {
        isLoading = true
        defer { isLoading = false }
        do {
            var updatedItem = item
            if let uploadedImage = try await FirebaseImageManager.shared.updateImage(
                item.primaryImage,
                resultImageType: .item
            ) {
                updatedItem.primaryImage = uploadedImage
            }
            item = updatedItem
            try itemRepo.set(document: item)
        } catch {
            print("Error updating item \(item.id): \(error.localizedDescription)")
        }
    }

    func deleteItem() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await itemRepo.delete(id: item.id)
        } catch {
            print("error deleting \(item.name): \(error.localizedDescription)")
        }
    }
}
