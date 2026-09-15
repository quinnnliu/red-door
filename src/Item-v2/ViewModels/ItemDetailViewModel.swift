//
//  ItemDetailsViewModel.swift
//  RedDoor
//
//  Created by Quinn Liu on 5/14/26.
//

import SwiftUI
import Firebase

@Observable
final class ItemDetailViewModel {
    private let itemRepo: ItemRepository = ItemRepository()
    private let essentialsRepo: EssentialsRepository = .init()

    // MARK: Item State
    var itemState: ItemV2

    // MARK: Essentials
    var availableGroups: [EssentialsGroup] = []

    // MARK: View State
    var isLoading: Bool = false

    // MARK: Listener
    private var itemListener: ListenerRegistration? = nil

    deinit {
        stopListening()
    }

    init(item: ItemV2) {
        self.itemState = item
    }

    // MARK: - Listeners

    func startListening() {
        guard itemListener == nil else { return }
        itemListener = itemRepo.addDocumentListener(id: itemState.id) { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let updatedItem):
                    self?.itemState = updatedItem
                case .failure(let error):
                    print("item listener error: \(error.localizedDescription)")
                }
            }
        }
    }

    func stopListening() {
        itemListener?.remove()
        itemListener = nil
    }

    // MARK: - loadGroups

    func loadGroups() async {
        do { availableGroups = try await essentialsRepo.getAll() }
        catch { print("error loading groups: \(error)") }
    }

    // MARK: - updateItem

    func updateItem(oldGroupId: String?) async {
        isLoading = true
        defer { isLoading = false }
        do {
            var updatedItem = itemState
            updatedItem.baseNameLowercased = updatedItem.baseName.lowercased()
            if let uploadedImage = try await FirebaseImageManager.shared.updateImage(
                itemState.primaryImage,
                resultImageType: .item
            ) {
                updatedItem.primaryImage = uploadedImage
            } else {
                updatedItem.primaryImage = RDImage()
            }
            itemState = updatedItem
            try itemRepo.set(document: itemState)

            let newGroupId = itemState.essentialGroupId
            if newGroupId != oldGroupId {
                if let old = oldGroupId {
                    try await essentialsRepo.removeItem(itemState.id, fromGroup: old)
                }
                if let new = newGroupId {
                    try await essentialsRepo.addItem(itemState.id, toGroup: new)
                }
            }
        } catch {
            print("Error updating item \(itemState.id): \(error.localizedDescription)")
        }
    }

    // MARK: - deleteItem

    func deleteItem() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await FirebaseImageManager.shared.deleteDocumentImages(document: itemState, imageType: .item)
            try await itemRepo.delete(id: itemState.id)
        } catch {
            print("error deleting \(itemState.displayName): \(error.localizedDescription)")
        }
    }
}
