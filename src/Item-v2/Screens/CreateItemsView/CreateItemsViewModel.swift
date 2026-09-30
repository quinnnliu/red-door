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
    private let essentialsRepo: EssentialsRepository = .init()
    private let storageLocationRepo: StorageLocationRepository
    private let configService: ConfigurationService

    // MARK: Essentials
    var availableGroups: [EssentialsGroup] = []
    var selectedGroup: EssentialsGroup? = nil

    // MARK: Storage Location
    var storageLocations: [StorageLocation] = []
    var selectedStorageLocation: StorageLocation? = nil

    // MARK: itemState
    var itemState: ItemV2
    let templateState: ItemV2?
    private let modelUUID: String

    private var modelId: String {
        if let templateState { return templateState.modelId }
        let parts = [
            itemState.baseName,
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
    
    init(
        template: ItemV2? = nil,
        storageLocationRepo: StorageLocationRepository = StorageLocationRepository(),
        configService: ConfigurationService = .shared
    ) {
        self.storageLocationRepo = storageLocationRepo
        self.configService = configService
        self.modelUUID = UUID().uuidString
        self.templateState = template
        self.itemState = template.map { ItemV2(item: $0) } ?? ItemV2(
            id: UUID().uuidString,
            modelId: "",
            baseName: "",
            primaryImage: RDImage(),
            type: .misc,
            color: .black,
            material: .none,
            location: .unselectedStorage,
            attention: false,
            description: ""
        )
        self.itemCount = 1
        self.selectedRDImage = nil
        self.isImageSelected = false
        self.isLoading = false
    }

    func loadGroups() async {
        do {
            availableGroups = try await essentialsRepo.getAll()
            if let groupId = itemState.essentialGroupId {
                selectedGroup = availableGroups.first { $0.id == groupId }
            }
        } catch { print("error loading groups: \(error)") }
    }

    // MARK: Storage Location

    func loadStorageLocations() async {
        do {
            storageLocations = try await configService.getAll(using: storageLocationRepo)
            if selectedStorageLocation == nil, storageLocations.count == 1 {
                selectedStorageLocation = storageLocations.first
            }
        } catch { print("error loading storage locations: \(error)") }
    }

    func refreshStorageLocations() async {
        configService.invalidate(StorageLocation.self)
        await loadStorageLocations()
    }

    func createItems() async -> Bool {
        guard !isLoading else { return false }
        guard let storageLocation = selectedStorageLocation else { return false }
        isLoading = true
        defer { isLoading = false }

        let resolvedModelId = modelId
        var items: [ItemV2] = []
        itemState.baseNameLowercased = itemState.baseName.lowercased()

        itemState.essentialGroupId = selectedGroup?.id
        itemState.location = DocumentLocation(status: .inStorage, locationId: storageLocation.id)

        do {
            let startingNumber = try await itemRepo.maxItemNumber(forModelId: resolvedModelId)
            for i in 0..<itemCount {
                var newItem = ItemV2(item: itemState)
                newItem.modelId = resolvedModelId
                newItem.itemNumber = startingNumber + i + 1
                newItem.primaryImage.documentId = newItem.id
                items.append(newItem)
            }
        } catch {
            print("error fetching max item number for modelId \(resolvedModelId): \(error.localizedDescription)")
            return false
        }

        do {
            let updatedItems: [ItemV2] = try await withThrowingTaskGroup(of: ItemV2.self) { taskGroup in
                for item in items {
                    taskGroup.addTask {
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
                for try await item in taskGroup { results.append(item) }
                return results
            }

            let batch = itemRepo.db.batch()
            for item in updatedItems {
                try itemRepo.set(document: item, id: item.id, inBatch: batch)
            }
            try await batch.commit()

            if let group = selectedGroup {
                for item in updatedItems {
                    try await essentialsRepo.addItem(item.id, toGroup: group.id)
                }
            }

            return true
        } catch {
            print("error creating items for: \(itemState.displayName)")
            return false
        }
    }
}
