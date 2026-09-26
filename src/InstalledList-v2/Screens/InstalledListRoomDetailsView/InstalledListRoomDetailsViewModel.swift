//
//  InstalledListRoomDetailsViewModel.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/25/26.
//

import Foundation
import Firebase

@Observable
final class InstalledListRoomDetailsViewModel {
    private let roomRepo: RoomRepository
    private let itemRepo: ItemRepository

    var roomState: RoomV2
    var items: [ItemV2]
    var availableWarehouses: [WarehouseV2] = []
    var isLoading: Bool = false
    var showAlert: Bool = false
    var alertMessage: String = ""

    private var roomListener: ListenerRegistration? = nil
    private var itemsCache: [String: ItemV2] = [:]

    init(room: RoomV2, roomRepo: RoomRepository, items: [ItemV2] = []) {
        self.roomRepo = roomRepo
        self.itemRepo = ItemRepository()
        self.roomState = room
        self.items = items

        for item in items {
            itemsCache[item.id] = item
        }
    }

    deinit {
        stopListening()
    }

    // MARK: - Listeners

    func startListening() {
        guard roomListener == nil else { return }
        isLoading = true

        roomListener = roomRepo.addRoomListener(roomId: roomState.id) { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let room):
                    await self?.handleRoomSnapshot(room)
                case .failure(let error):
                    await self?.handleListenerError(error)
                }
            }
        }
    }

    func stopListening() {
        roomListener?.remove()
        roomListener = nil
        itemsCache.removeAll()
    }

    @MainActor
    private func handleRoomSnapshot(_ snapshot: RoomV2) async {
        isLoading = false
        roomState = snapshot
        await fetchItemsForRoom(snapshot)
    }

    @MainActor
    private func handleListenerError(_ error: Error) async {
        isLoading = false
        alertMessage = "Failed to load room: \(error.localizedDescription)"
        showAlert = true
    }

    // MARK: - fetchItemsForRoom

    @MainActor
    private func fetchItemsForRoom(_ room: RoomV2) async {
        do {
            let uncachedIds = room.itemIds.filter { itemsCache[$0] == nil }
            if !uncachedIds.isEmpty {
                let fetched = try await itemRepo.get(ids: Array(uncachedIds))
                for item in fetched {
                    itemsCache[item.id] = item
                }
            }

            items = room.itemIds.compactMap { itemsCache[$0] }.sorted { $0.displayName < $1.displayName }
        } catch {
            alertMessage = "Failed to load items: \(error.localizedDescription)"
            showAlert = true
        }
    }

    func refreshRoom() {
        itemsCache.removeAll()
        items.removeAll()
        Task { @MainActor in
            await fetchItemsForRoom(roomState)
        }
    }

    // MARK: - fetchAvailableWarehouses

    func fetchAvailableWarehouses() async {
        do {
            availableWarehouses = try await ConfigurationService.shared.getAll(using: WarehouseRepository())
        } catch {
            alertMessage = "Failed to load storage locations: \(error.localizedDescription)"
            showAlert = true
        }
    }

    // MARK: - removeItemToWarehouse

    func removeItemToWarehouse(item: ItemV2, warehouse: WarehouseV2) async {
        let originalItems = roomState.itemIds
        var updatedItems = roomState.itemIds
        updatedItems.remove(item.id)

        do {
            let batch = roomRepo.db.batch()
            let storageLocationData = try Firestore.Encoder().encode(
                DocumentLocation(status: .inStorage, locationId: warehouse.id)
            )
            itemRepo.update(
                id: item.id,
                fields: [ItemV2.CodingKeys.location.stringValue: storageLocationData],
                inBatch: batch
            )
            roomRepo.update(
                id: roomState.id,
                fields: [RoomV2.CodingKeys.itemIds.stringValue: Array(updatedItems)],
                inBatch: batch
            )
            try await batch.commit()
            itemsCache.removeValue(forKey: item.id)
            roomState.itemIds = updatedItems
        } catch {
            roomState.itemIds = originalItems
            alertMessage = "Failed to remove item: \(error.localizedDescription)"
            showAlert = true
        }
    }

    // MARK: - updateRoomImage

    @MainActor
    func updateRoomImage(_ updatedImage: RDImage, isBefore: Bool) async {
        isLoading = true
        defer { isLoading = false }

        var imageToUpdate = updatedImage
        imageToUpdate.documentId = roomState.id

        let imageField = isBefore ? RoomV2.CodingKeys.beforeImage.stringValue : RoomV2.CodingKeys.afterImage.stringValue

        do {
            let imageType: RDImageType = isBefore ? .roomBefore : .roomAfter
            if let updatedImage = try await FirebaseImageManager.shared.updateImage(imageToUpdate, resultImageType: imageType) {
                try await roomRepo.update(id: roomState.id, fields: [
                    imageField: encodeRDImage(updatedImage)
                ])
            } else {
                try await roomRepo.update(id: roomState.id, fields: [
                    imageField: NSNull()
                ])
            }
        } catch {
            alertMessage = "Failed to update \(isBefore ? "before" : "after") image: \(error.localizedDescription)"
            showAlert = true
        }
    }

    private func encodeRDImage(_ image: RDImage) -> [String: AnyHashable] {
        var dict: [String: AnyHashable] = [
            "id": image.id,
            "imageType": image.imageType.rawValue
        ]
        if let documentId = image.documentId { dict["document_id"] = documentId }
        if let url = image.imageURL { dict["imageURL"] = url.absoluteString }
        return dict
    }
}
