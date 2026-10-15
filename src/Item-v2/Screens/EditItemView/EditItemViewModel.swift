//
//  EditItemViewModel.swift
//  RedDoor
//
//  Created by Quinn Liu on 10/4/26.
//

import SwiftUI
import Firebase

@Observable
final class EditItemViewModel {
    private let itemRepo: ItemRepository
    private let essentialsRepo: EssentialsRepository

    // MARK: Item State
    let originalItem: ItemV2
    var updatedItem: ItemV2

    // MARK: Essentials
    var availableGroups: [EssentialsGroup] = []
    var selectedGroup: EssentialsGroup?

    // MARK: View State
    var isLoading: Bool = false
    var isDeleting: Bool = false
    var showAlert: Bool = false
    var alertMessage: String = ""

    init(
        item: ItemV2,
        essentialsGroup: EssentialsGroup?,
        itemRepo: ItemRepository,
        essentialsRepo: EssentialsRepository
    ) {
        self.originalItem = item
        self.updatedItem = item
        self.selectedGroup = essentialsGroup
        self.itemRepo = itemRepo
        self.essentialsRepo = essentialsRepo
    }

    // MARK: - loadGroups

    func loadGroups() async {
        do {
            availableGroups = try await essentialsRepo.getAll()
            if selectedGroup == nil, let groupId = updatedItem.essentialGroupId {
                selectedGroup = availableGroups.first { $0.id == groupId }
            }
        } catch {
            showError(error)
        }
    }

    // MARK: - Image

    func setPrimaryImage(_ uiImage: UIImage) {
        updatedItem.primaryImage = RDImage(uiImage: uiImage, documentId: originalItem.id)
    }

    func clearPrimaryImage() {
        updatedItem.primaryImage = .empty(for: originalItem.id)
    }

    // MARK: - save

    /// Writes `updatedItem` to the original item's document. Returns `true` on success.
    func save() async -> Bool {
        isLoading = true
        defer { isLoading = false }
        do {
            var item = updatedItem
            item.essentialGroupId = selectedGroup?.id
            item.baseNameLowercased = item.baseName.lowercased()

            let (persistedImage, cleanup) = try await FirebaseImageManager.shared.resolve(
                original: originalItem.primaryImage,
                updated: item.primaryImage,
                type: .item
            )
            item.primaryImage = persistedImage ?? .empty(for: originalItem.id)

            let batch = itemRepo.newBatch()
            try itemRepo.set(document: item, id: originalItem.id, inBatch: batch)

            let oldGroupId = originalItem.essentialGroupId
            let newGroupId = item.essentialGroupId
            if newGroupId != oldGroupId {
                if let oldGroupId {
                    essentialsRepo.removeItem(originalItem.id, fromGroup: oldGroupId, inBatch: batch)
                }
                if let newGroupId {
                    essentialsRepo.addItem(originalItem.id, toGroup: newGroupId, inBatch: batch)
                }
            }
            try await batch.commit()

            updatedItem = item

            if let cleanup, cleanup.documentId == originalItem.id {
                try? await FirebaseImageManager.shared.delete(cleanup, type: .item)
            }
            return true
        } catch {
            showError(error)
            return false
        }
    }

    // MARK: - delete

    func delete() async -> Bool {
        guard originalItem.canDelete, !isLoading else { return false }
        isLoading = true
        isDeleting = true
        defer {
            isLoading = false
            isDeleting = false
        }
        do {
            try await itemRepo.deleteItem(id: originalItem.id)
            return true
        } catch {
            showError(error)
            return false
        }
    }

    // MARK: - Helpers

    private func showError(_ error: Error) {
        alertMessage = error.localizedDescription
        showAlert = true
    }
}
