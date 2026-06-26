//
//  CreateModelViewModel.swift
//  RedDoor
//
//  Created by Quinn Liu on 4/25/26.
//

import SwiftUI

@Observable
final class CreateItemsViewModel {
    private let itemRepo: ItemRepository = .init()
    
    // MARK: itemState
    var itemState: ItemV2
    private let modelUUID: String

    private var modelId: String {
        let parts = [
            itemState.displayName,
            itemState.type.rawValue,
            itemState.color.rawValue,
            itemState.material.rawValue,
            "model",
            modelUUID
        ]
        return parts
            .map { $0.lowercased().replacingOccurrences(of: " ", with: "-") }
            .joined(separator: "-")
    }
    
    // MARK: ViewState
    
    var itemCount: Int // Separate from ModelV2 — a create-only input that produces itemIds at commit time
    var isLoading: Bool

    // Image Overlay
    var selectedRDImage: RDImage?
    var isImageSelected: Bool
    
    init() {
        self.modelUUID = UUID().uuidString
        self.itemState = ItemV2(
            id: UUID().uuidString,
            modelId: "",
            displayName: "",
            primaryImage: RDImage(),
            type: .misc,
            color: .black,
            material: .none,
            attention: false,
            description: "",
            essentialGroupId: "" // TODO: use a custom binding like the other optional fields
        )
        self.itemCount = 1
        self.selectedRDImage = nil
        self.isImageSelected = false
        self.isLoading = false
    }
    
    func createItems() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        let resolvedModelId = modelId
        var items: [ItemV2] = []
        itemState.nameLowercased = itemState.displayName.lowercased()

        do {
            let startingNumber = try await itemRepo.maxItemNumber(forModelId: resolvedModelId)
            for i in 0..<itemCount {
                var newItem = ItemV2(item: itemState)
                newItem.modelId = resolvedModelId
                newItem.itemNumber = startingNumber + i + 1
                newItem.primaryImage.objectId = newItem.id
                items.append(newItem)
            }
        } catch {
            print("error fetching max item number for modelId \(resolvedModelId): \(error.localizedDescription)")
            return
        }

        do {
            let updatedItems: [ItemV2] = try await withThrowingTaskGroup(of: ItemV2.self) { group in
                for item in items {
                    group.addTask {
                        var updated = item
                        if let uploadedImage = try await FirebaseImageManager.shared.updateImage(
                            item.primaryImage,
                            resultImageType: .item
                        ) {
                            updated.primaryImage = uploadedImage
                        }
                        return updated
                    }
                }
                var results: [ItemV2] = []
                for try await item in group { results.append(item) }
                return results
            }

            let batch = itemRepo.db.batch()
            for item in updatedItems {
                try itemRepo.set(document: item, id: item.id, inBatch: batch)
            }
            try await batch.commit()

        } catch {
            print("error creating items for: \(itemState.displayName)")
        }
    }
}
