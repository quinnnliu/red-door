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
                let fetched = try await itemRepo.get(ids: Array(uncachedIds))
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

    // MARK: - Assign to Pull List

    func assignToPullList(_ pullList: PullListV2) async {
        guard groupState.location.status != .inPullList else {
            alertMessage = "This essentials group is already assigned to a pull list."
            showAlert = true
            return
        }

        let unavailable = unavailableNames()
        if !unavailable.isEmpty {
            let list = unavailable.map { "• \($0)" }.joined(separator: "\n")
            alertMessage = "The following are not in storage and cannot be assigned:\n\n\(list)"
            showAlert = true
            return
        }

        let batch = essentialsRepo.db.batch()
        let locationFields: [String: Any] = DocumentLocation(
            status: .inPullList,
            locationId: pullList.id
        ).firebaseUpdateFields

        for itemId in groupState.itemIds {
            itemRepo.update(id: itemId, fields: locationFields, inBatch: batch)
        }

        if let accessoriesId = groupState.accessoriesId {
            accessoriesRepo.update(id: accessoriesId, fields: locationFields, inBatch: batch)
        }

        essentialsRepo.update(id: groupState.id, fields: locationFields, inBatch: batch)

        pullListRepo.update(
            id: pullList.id,
            fields: [
                PullListV2.CodingKeys.essentialGroupId.stringValue: groupState.id,
                PullListV2.CodingKeys.unassignedItemIds.stringValue: FieldValue.arrayUnion(Array(groupState.itemIds))
            ],
            inBatch: batch
        )

        do {
            try await batch.commit()
        } catch {
            alertMessage = "Failed to assign to pull list: \(error.localizedDescription)"
            showAlert = true
        }
    }

    private func unavailableNames() -> [String] {
        var names: [String] = items
            .filter { $0.location.status != .inStorage }
            .map { $0.displayName }
        if let accessories = accessoriesState, accessories.location.status != .inStorage {
            names.append(accessories.displayName)
        }
        return names
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
            itemsCache.removeValue(forKey: item.id)
        } catch {
            alertMessage = "Failed to remove \(item.displayName): \(error.localizedDescription)"
            showAlert = true
        }
    }
}
