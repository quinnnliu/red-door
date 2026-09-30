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
    var availableStorageLocations: [StorageLocation] = []
    var isLoading: Bool = false
    var showAlert: Bool = false
    var alertMessage: String = ""
    var uninstalled: Bool

    private var roomListener: ListenerRegistration? = nil
    private let loader: ItemsListLoader

    init(
        room: RoomV2,
        roomRepo: RoomRepository,
        items: [ItemV2] = [],
        uninstalled: Bool = false
    ) {
        self.roomRepo = roomRepo
        self.itemRepo = ItemRepository()
        self.roomState = room
        self.items = items
        self.uninstalled = uninstalled
        self.loader = ItemsListLoader(itemRepo: self.itemRepo, seed: items)
    }

    /// Detaches only: `deinit` can run on any thread, while the rest of
    /// `stopListening()` mutates state the UI reads on the main thread.
    deinit {
        roomListener?.remove()
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

    // MARK: - fetchAvailableStorageLocations

    func fetchAvailableStorageLocations() async {
        do {
            availableStorageLocations = try await ConfigurationService.shared.getAll(using: StorageLocationRepository())
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
