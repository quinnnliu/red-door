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
    private let itemRepo: ItemRepository
    private let essentialsRepo: EssentialsRepository

    // MARK: Item State
    var itemState: ItemV2

    // MARK: Essentials
    var essentialsGroup: EssentialsGroup? = nil

    // MARK: Listener
    private var itemListener: ListenerRegistration? = nil
 
    deinit {
        itemListener?.remove()
    }

    init(item: ItemV2, itemRepo: ItemRepository, essentialsRepo: EssentialsRepository) {
        self.itemState = item
        self.itemRepo = itemRepo
        self.essentialsRepo = essentialsRepo
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
                    guard !RepositoryError.isDocumentNotFound(error) else { return }
                    print("item listener error: \(error.localizedDescription)")
                }
            }
        }
    }

    func stopListening() {
        itemListener?.remove()
        itemListener = nil
    }

    // MARK: - loadEssentialsGroup

    func loadEssentialsGroup() async {
        guard let groupId = itemState.essentialGroupId else {
            essentialsGroup = nil
            return
        }
        do { essentialsGroup = try await essentialsRepo.get(id: groupId) }
        catch { print("error loading essentials group: \(error)") }
    }
}
