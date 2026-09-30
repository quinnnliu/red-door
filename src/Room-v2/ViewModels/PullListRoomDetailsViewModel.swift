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
    private let pullListRepo: PullListRepository

    var roomState: RoomV2
    var items: [ItemV2]
    var storageLocations: [StorageLocation] = []
    var isLoading: Bool = false
    var showAlert: Bool = false
    var alertMessage: String = ""

    private var roomListener: ListenerRegistration? = nil
    private let loader: ItemsListLoader

    init(
        room: RoomV2,
        items: [ItemV2] = []
    ) {
        self.roomRepo = RoomRepository(room: room)
        self.itemRepo = ItemRepository()
        self.pullListRepo = PullListRepository()
        self.roomState = room
        self.items = items
        self.loader = ItemsListLoader(itemRepo: self.itemRepo, seed: items)
    }
    
    // MARK: - Listeners

    /// Detaches only: `deinit` can run on any thread, while the rest of
    /// `stopListening()` mutates state the UI reads on the main thread.
    deinit {
        roomListener?.remove()
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
        loader.invalidate()
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
            items = try await loader.items(for: room)
        } catch {
            alertMessage = "Failed to load items: \(error.localizedDescription)"
            showAlert = true
        }
    }
    
    func refreshRoom() {
        loader.invalidate()
        items.removeAll()
        Task { @MainActor in
            await fetchItemsForRoom(roomState)
        }
    }
}


extension PullListRoomDetailsViewModel {

    // MARK: - fetchAvailableStorageLocations

    func fetchAvailableStorageLocations() async {
        do {
            storageLocations = try await ConfigurationService.shared.getAll(using: StorageLocationRepository())
        } catch {
            alertMessage = "Failed to load storage locations: \(error.localizedDescription)"
            showAlert = true
        }
    }

    // MARK: - removeItemToStorage

    @MainActor
    func removeItemToStorage(item: ItemV2, storageLocation: StorageLocation) async {
        do {
            try await roomRepo.removeItem(
                item.id,
                fromRoomId: roomState.id,
                toStorageLocationId: storageLocation.id,
                itemRepo: itemRepo
            )
            loader.invalidate([item.id])
            roomState.itemIds.remove(item.id)
        } catch {
            alertMessage = "Failed to remove item: \(error.localizedDescription)"
            showAlert = true
        }
    }

    // MARK: - moveItemToUnassigned

    @MainActor
    func moveItemToUnassigned(item: ItemV2) async {
        do {
            try await roomRepo.unassignItem(
                item.id,
                fromRoomId: roomState.id,
                listId: roomState.listId,
                pullListRepo: pullListRepo
            )
            loader.invalidate([item.id])
            roomState.itemIds.remove(item.id)
        } catch {
            alertMessage = "Failed to unassign item: \(error.localizedDescription)"
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
                RoomV2.CodingKeys.baseName.stringValue: newRoomName
            ])
            roomState.baseName = newRoomName
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
