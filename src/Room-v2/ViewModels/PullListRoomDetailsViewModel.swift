//
//  PullListRoomDetailsViewModel.swift
//  RedDoor
//
//  Created by Quinn Liu on 5/30/26.
//

import Foundation
import Firebase

@Observable
final class PullListRoomDetailsViewModel {
    private let roomRepo: RoomRepository
    private let itemRepo: ItemRepository

    var roomState: RoomV2
    var items: [ItemV2]
    var isLoading: Bool = false
    var showAlert: Bool = false
    var alertMessage: String = ""

    private var roomListener: ListenerRegistration? = nil
    private var itemsCache: [String: ItemV2] = [:]

    init(
        room: RoomV2,
        items: [ItemV2] = []
    ) {
        self.roomRepo = RoomRepository(room: room)
        self.itemRepo = ItemRepository()
        self.roomState = room
        self.items = items

        for item in items {
            itemsCache[item.id] = item
        }
    }
    
    // MARK: - Listeners

    deinit {
        stopListening()
    }

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
}


extension PullListRoomDetailsViewModel {
    // MARK: - removeItemFromRoom
    
    func removeItemFromRoom(item: ItemV2) async {
        let originalItems = roomState.itemIds
        let updatedItems = roomState.itemIds.filter { $0 != item.id }
        
        do {
            let batch = roomRepo.db.batch()
            itemRepo.update(
                id: item.id,
                fields: [
                    ItemV2.CodingKeys.status.stringValue: ItemStatus.inStorage.rawValue,
                    ItemV2.CodingKeys.locationId.stringValue: Warehouse.warehouse1.id
                ],
                inBatch: batch
            )
            roomRepo.update(
                id: roomState.id,
                fields: [RoomV2.CodingKeys.itemIds.stringValue: Array(updatedItems)],
                inBatch: batch
            )
            try await batch.commit()
            itemsCache.removeValue(forKey: item.id)
            alertMessage = "Removed item: \(item.displayName)"
            showAlert = true
            roomState.itemIds = updatedItems
        } catch {
            roomState.itemIds = originalItems
            alertMessage = "Failed to remove item: \(error.localizedDescription)"
            showAlert = true
        }
    }
    
    // MARK: - deleteRoom
    
    func deleteRoom() async {
        do {
            try await roomRepo.delete(id: roomState.id)
        } catch {
            alertMessage = "Failed to delete room: \(error.localizedDescription)"
            showAlert = true
        }
    }
    
    // MARK: - renameRoom
    func renameRoom(roomId: String, newRoomName: String) async {
        do {
            let newNameId = RoomV2.nameToId(newRoomName)
            try await roomRepo.update(id: roomId, fields: [
                RoomV2.CodingKeys.nameId.stringValue: newNameId,
                RoomV2.CodingKeys.displayName.stringValue: newRoomName
            ])
            roomState.displayName = newRoomName
        } catch {
            alertMessage = "Failed to rename \(roomState.displayName) to \(newRoomName)"
            showAlert = true
        }
    }
}

extension PullListRoomDetailsViewModel {
        
    @MainActor
    func updateRoomImage(_ updatedImage: RDImage, isBefore: Bool) async {
        isLoading = true
        defer { isLoading = false }

        var imageToUpdate = updatedImage
        imageToUpdate.objectId = roomState.id
        
        let imageField = isBefore ? RoomV2.CodingKeys.beforeImage.stringValue : RoomV2.CodingKeys.afterImage.stringValue
        
        do {
            if let updatedImage = try await FirebaseImageManager.shared.updateImage(imageToUpdate, resultImageType: .roomBefore) {
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
        if let objectId = image.objectId { dict["objectId"] = objectId }
        if let url = image.imageURL { dict["imageURL"] = url.absoluteString }
        return dict
    }
}
