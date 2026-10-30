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
    private let pullListRepo: PullListRepository = .init()

    var groupState: EssentialsGroup
    var accessoriesState: Accessories? = nil

    var items: [ItemV2] = []
    var isLoading: Bool = false
    var showAlert: Bool = false
    var alertMessage: String = ""
    /// The pull list being assigned to is gone or changed; the view presents it.
    var staleWriteError: StaleWriteError? = nil

    private var groupListener: ListenerRegistration? = nil
    private let itemsLoader = ItemsListLoader()

    init(group: EssentialsGroup) {
        self.groupState = group
    }

    deinit {
        groupListener?.remove()
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
        itemsLoader.invalidate()
    }

    @MainActor
    private func handleGroupSnapshot(_ snapshot: EssentialsGroup) async {
        isLoading = false
        groupState = snapshot
        do {
            items = try await itemsLoader.items(for: snapshot)
        } catch {
            alertMessage = "Failed to load items: \(error.localizedDescription)"
            showAlert = true
        }

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

        guard !RepositoryError.isDocumentNotFound(error) else { return }

        alertMessage = "Failed to load group: \(error.localizedDescription)"
        showAlert = true
    }

    // MARK: - Accessories

    /// Both sides of the link move together: the group's `accessoriesId` and
    /// the accessory's `essentialsGroupId`. A half-applied write would leave an
    /// accessory permanently unpickable, since the picker filters on the
    /// back-reference.
    func setAccessories(_ accessories: Accessories) async {
        let batch = essentialsRepo.db.batch()

        essentialsRepo.update(
            id: groupState.id,
            fields: [EssentialsGroup.CodingKeys.accessoriesId.stringValue: accessories.id],
            inBatch: batch
        )
        accessoriesRepo.update(
            id: accessories.id,
            fields: [Accessories.CodingKeys.essentialsGroupId.stringValue: groupState.id],
            inBatch: batch
        )

        // Release the accessory being displaced, if this is a replacement.
        if let previousId = groupState.accessoriesId, previousId != accessories.id {
            accessoriesRepo.update(
                id: previousId,
                fields: [Accessories.CodingKeys.essentialsGroupId.stringValue: NSNull()],
                inBatch: batch
            )
        }

        do {
            try await batch.commit()
            accessoriesState = accessories
            groupState.accessoriesId = accessories.id
        } catch {
            alertMessage = "Failed to set accessories: \(error.localizedDescription)"
            showAlert = true
        }
    }

    func removeAccessories() async {
        guard let accessoriesId = groupState.accessoriesId else { return }

        let batch = essentialsRepo.db.batch()

        essentialsRepo.update(
            id: groupState.id,
            fields: [EssentialsGroup.CodingKeys.accessoriesId.stringValue: NSNull()],
            inBatch: batch
        )
        accessoriesRepo.update(
            id: accessoriesId,
            fields: [Accessories.CodingKeys.essentialsGroupId.stringValue: NSNull()],
            inBatch: batch
        )

        do {
            try await batch.commit()
            accessoriesState = nil
            groupState.accessoriesId = nil
        } catch {
            alertMessage = "Failed to remove accessories: \(error.localizedDescription)"
            showAlert = true
        }
    }

    // MARK: - Assign to Pull List

    func assignToPullList(_ pullList: PullListV2) async {
        guard groupState.location.status != .inPullList else {
            alertMessage = "This essentials group is already assigned to a pull list."
            showAlert = true
            return
        }

        do {
            try await essentialsRepo.assign(
                groupId: groupState.id,
                toPullListId: pullList.id,
                itemRepo: itemRepo,
                accessoriesRepo: accessoriesRepo,
                pullListRepo: pullListRepo
            )
            itemsLoader.invalidate(groupState.itemIds)
        } catch {
            if let stale = StaleWriteError(error) {
                staleWriteError = stale
            } else if let assignError = error as? EssentialsAssignError {
                alertMessage = assignError.localizedDescription
                showAlert = true
            } else {
                alertMessage = "Failed to assign to pull list: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }

    // MARK: - Remove Item

    func removeItem(_ item: ItemV2) async {
        let updatedItemIds = groupState.itemIds.filter { $0 != item.id }

        do {
            let batch = essentialsRepo.db.batch()
            essentialsRepo.update(
                id: groupState.id,
                fields: [EssentialsGroup.CodingKeys.itemIds.stringValue: Array(updatedItemIds)],
                inBatch: batch
            )
            itemRepo.update(
                id: item.id,
                fields: [ItemV2.CodingKeys.essentialGroupId.stringValue: NSNull()],
                inBatch: batch
            )
            try await batch.commit()
            itemsLoader.invalidate([item.id])
        } catch {
            alertMessage = "Failed to remove \(item.displayName): \(error.localizedDescription)"
            showAlert = true
        }
    }
}
