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
    private let roomRepo: RoomRepository<PullListV2>
    private let itemRepo: ItemRepository
    private let pullListRepo: PullListRepository

    var roomState: RoomV2
    var items: [ItemV2]
    var storageLocations: [StorageLocation] = []
    var isLoading: Bool = false
    var isDeleting: Bool = false
    var showAlert: Bool = false
    var alertMessage: String = ""

    private var roomListener: ListenerRegistration? = nil
    private let loader: ItemsListLoader

    init(
        room: RoomV2,
        items: [ItemV2] = []
    ) {
        self.roomRepo = RoomRepository<PullListV2>(room: room)
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

        // A deleted document ends its listener normally — an install deletes
        // the pull list and its rooms, and a detail screen can still be
        // listening as it dismisses. Nothing to tell the user.
        guard !RepositoryError.isDocumentNotFound(error) else { return }

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
    
    @MainActor
    func deleteRoom() async -> Bool {
        guard roomState.canDelete else {
            alertMessage = RoomDeleteError.notEmpty.localizedDescription
            showAlert = true
            return false
        }
        guard !isDeleting else { return false }

        isDeleting = true
        defer { isDeleting = false }
        do {
            try await roomRepo.deleteRoom(id: roomState.id)
            return true
        } catch {
            alertMessage = "Failed to delete room: \(error.localizedDescription)"
            showAlert = true
            return false
        }
    }

    // MARK: - updateRoomDetails
    func updateRoomDetails(roomId: String, newRoomName: String, squareFootage: String?) async {
        do {
            let newNameId = RoomV2.nameToId(newRoomName)
            try await roomRepo.update(id: roomId, fields: [
                RoomV2.CodingKeys.nameId.stringValue: newNameId,
                RoomV2.CodingKeys.baseName.stringValue: newRoomName,
                RoomV2.CodingKeys.squareFootage.stringValue: (squareFootage as Any?) ?? FieldValue.delete()
            ])
            roomState.baseName = newRoomName
            roomState.squareFootage = squareFootage
        } catch {
            alertMessage = "Failed to update \(roomState.displayName)"
            showAlert = true
        }
    }
}

extension PullListRoomDetailsViewModel {
        
    @MainActor
    func updateRoomImage(_ action: ImageEditorAction, isBefore: Bool) async {
        isLoading = true
        defer { isLoading = false }

        let original = isBefore ? roomState.beforeImage : roomState.afterImage
        let updated: RDImage?
        switch action {
        case .newImage(let uiImage):
            updated = RDImage(uiImage: uiImage, documentId: roomState.imageOwnerId)
        case .deleteImage:
            updated = nil
        }

        let imageField = isBefore ? RoomV2.CodingKeys.beforeImage.stringValue : RoomV2.CodingKeys.afterImage.stringValue
        let imageType: RDImageType = isBefore ? .roomBefore : .roomAfter

        do {
            let (persisted, cleanup) = try await FirebaseImageManager.shared.resolve(
                original: original,
                updated: updated,
                type: imageType
            )
            let value: Any = try persisted.map { try Firestore.Encoder().encode($0) } ?? NSNull()
            try await roomRepo.update(id: roomState.id, fields: [imageField: value])

            // After the write, so a failed save never points the room at a deleted file.
            if let cleanup {
                try? await FirebaseImageManager.shared.delete(cleanup, type: imageType)
            }
        } catch {
            alertMessage = "Failed to update \(isBefore ? "before" : "after") image: \(error.localizedDescription)"
            showAlert = true
        }
    }
}
