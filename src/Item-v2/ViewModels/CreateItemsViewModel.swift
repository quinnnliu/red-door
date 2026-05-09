//
//  CreateModelViewModel.swift
//  RedDoor
//
//  Created by Quinn Liu on 4/25/26.
//

import SwiftUI

@Observable
final class CreateItemsViewModel {
    private let itemRepo: ItemRepository = ItemRepository()
    
    // MARK: itemState
    var itemState: ItemV2
    private let modelId: String
    
    // MARK: ViewState
    
    var itemCount: Int // Separate from ModelV2 — a create-only input that produces itemIds at commit time
    var isLoading: Bool

    // Image Overlay
    var selectedRDImage: RDImage?
    var isImageSelected: Bool
    
    init() {
        self.modelId = "model-\(UUID().uuidString)"
        self.itemState = ItemV2(
            id: UUID().uuidString,
            modelId: self.modelId,
            name: "",
            primaryImage: RDImage(),
            type: .misc,
            color: .black,
            material: .none,
            attention: false,
            description: "",
            isEssential: false,
            isAvailable: true
        )
        self.itemCount = 0
        self.selectedRDImage = nil
        self.isImageSelected = false
        self.isLoading = false
    }
    
    func createItems() async {
        var items: [ItemV2] = []
        var itemIds: [String] = []
        for _ in (0..<itemCount) {
            let newItem = ItemV2(item: itemState)
            items.append(newItem)
            itemIds.append(newItem.id)
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            var batch = itemRepo.db.batch()
            for item in items {
                try itemRepo.set(item, id: item.id, inBatch: batch)
            }
            
            try await batch.commit()
            // TODO: need to set the images
        } catch {
            print("error creating items for: \(itemState.name)")
        }
    }
}
