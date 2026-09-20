//
//  EssentialsGroupDetailViewModel.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/25/26.
//

import Foundation
import Firebase

@Observable
final class EssentialsGroupDetailViewModel {
    private let essentialsRepo: EssentialsRepository = .init()
    private let itemRepo: ItemRepository = .init()
    private let accessoriesRepo: AccessoriesRepository = .init()

    var groupState: EssentialsGroup
    var accessoriesState: Accessories? = nil
    var availableAccessories: [Accessories] = []

    var items: [ItemV2] = []
    var isLoading: Bool = false
    var showAlert: Bool = false
    var alertMessage: String = ""

    private var groupListener: ListenerRegistration? = nil
    private var itemsCache: [String: ItemV2] = [:]

    init(group: EssentialsGroup) {
        self.groupState = group
    }

    deinit {
        stopListening()
    }

    // MARK: - Listeners

    func startListening() {
        guard groupListener == nil else { return }
        isLoading = true

        groupListener = essentialsRepo.addDocumentListener(id: groupState.id) { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let group):
                    await self?.handleGroupSnapshot(group)
                case .failure(let error):
                    await self?.handleListenerError(error)
                }
            }
        }
    }

    func stopListening() {
        groupListener?.remove()
        groupListener = nil
        itemsCache.removeAll()
    }

    @MainActor
    private func handleGroupSnapshot(_ snapshot: EssentialsGroup) async {
        isLoading = false
        groupState = snapshot
        let uncachedIds = snapshot.itemIds.filter { itemsCache[$0] == nil }
        if !uncachedIds.isEmpty {
            do {
                let fetched = try await itemRepo.get(ids: uncachedIds)
                for item in fetched {
                    itemsCache[item.id] = item
                }
            } catch {
                alertMessage = "Failed to load items: \(error.localizedDescription)"
                showAlert = true
            }
        }
        items = snapshot.itemIds.compactMap { itemsCache[$0] }.sorted { $0.displayName < $1.displayName }

        if let accessoriesId = snapshot.accessoriesId {
            if accessoriesState?.id != accessoriesId {
                do {
                    accessoriesState = try await accessoriesRepo.get(id: accessoriesId)
                } catch {
                    alertMessage = "Failed to load accessories: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        } else {
            accessoriesState = nil
        }
    }

    @MainActor
    private func handleListenerError(_ error: Error) async {
        isLoading = false
        alertMessage = "Failed to load group: \(error.localizedDescription)"
        showAlert = true
    }

    // MARK: - Accessories

    func fetchAvailableAccessories() async {
        do {
            availableAccessories = try await accessoriesRepo.getAll()
        } catch {
            alertMessage = "Failed to load accessories: \(error.localizedDescription)"
            showAlert = true
        }
    }

    func setAccessories(_ accessories: Accessories) async {
        do {
            try await essentialsRepo.update(
                id: groupState.id,
                fields: [EssentialsGroup.CodingKeys.accessoriesId.stringValue: accessories.id]
            )
            accessoriesState = accessories
            groupState.accessoriesId = accessories.id
        } catch {
            alertMessage = "Failed to set accessories: \(error.localizedDescription)"
            showAlert = true
        }
    }

    func removeAccessories() async {
        do {
            try await essentialsRepo.update(
                id: groupState.id,
                fields: [EssentialsGroup.CodingKeys.accessoriesId.stringValue: NSNull()]
            )
            accessoriesState = nil
            groupState.accessoriesId = nil
        } catch {
            alertMessage = "Failed to remove accessories: \(error.localizedDescription)"
            showAlert = true
        }
    }

    // MARK: - Remove Item

    func removeItem(_ item: ItemV2) async {
        let updatedItemIds = groupState.itemIds.filter { $0 != item.id }

        do {
            let batch = essentialsRepo.db.batch()
            essentialsRepo.update(
                id: groupState.id,
                fields: [EssentialsGroup.CodingKeys.itemIds.stringValue: updatedItemIds],
                inBatch: batch
            )
            itemRepo.update(
                id: item.id,
                fields: [ItemV2.CodingKeys.essentialGroupId.stringValue: NSNull()],
                inBatch: batch
            )
            try await batch.commit()
            itemsCache.removeValue(forKey: item.id)
        } catch {
            alertMessage = "Failed to remove \(item.displayName): \(error.localizedDescription)"
            showAlert = true
        }
    }
}
