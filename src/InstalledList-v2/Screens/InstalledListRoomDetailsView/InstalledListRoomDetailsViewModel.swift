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
    private let roomRepo: RoomRepository<InstalledListV2>
    private let itemRepo: ItemRepository
    private let installedListRepo: InstalledListRepository

    var roomState: RoomV2
    var items: [ItemV2]
    var availableStorageLocations: [StorageLocation] = []
    var isLoading: Bool = false
    var showAlert: Bool = false
    /// A write found the list gone, uninstalled or changed; the view presents it.
    var staleWriteError: StaleWriteError? = nil
    var alertMessage: String = ""
    var uninstalled: Bool

    private var roomListener: ListenerRegistration? = nil
    private var listListener: ListenerRegistration? = nil
    private let loader: ItemsListLoader

    init(
        room: RoomV2,
        roomRepo: RoomRepository<InstalledListV2>,
        installedListRepo: InstalledListRepository,
        items: [ItemV2] = [],
        uninstalled: Bool = false
    ) {
        self.roomRepo = roomRepo
        self.itemRepo = ItemRepository()
        self.installedListRepo = installedListRepo
        self.roomState = room
        self.items = items
        self.uninstalled = uninstalled
        self.loader = ItemsListLoader(itemRepo: self.itemRepo, seed: items)
    }

    /// Detaches only: `deinit` can run on any thread, while the rest of
    /// `stopListening()` mutates state the UI reads on the main thread.
    deinit {
        roomListener?.remove()
        listListener?.remove()
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

        // An uninstall flips `uninstalled` on the list document without touching
        // the room, so the room listener alone never sees it.
        listListener = installedListRepo.addDocumentListener(id: roomState.listId) { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let list):
                    self?.uninstalled = list.uninstalled
                case .failure(let error):
                    await self?.handleListenerError(error)
                }
            }
        }
    }

    func stopListening() {
        roomListener?.remove()
        roomListener = nil
        listListener?.remove()
        listListener = nil
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
            if let stale = StaleWriteError(error) {
                staleWriteError = stale
                return
            }
            alertMessage = "Failed to remove item: \(error.localizedDescription)"
            showAlert = true
        }
    }

    // MARK: - updateRoomImage

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
            do {
                try await roomRepo.updateRoom(id: roomState.id, fields: [imageField: value])
            } catch {
                // The upload already happened and nothing points at it.
                if let persisted {
                    try? await FirebaseImageManager.shared.delete(persisted, type: imageType)
                }
                throw error
            }

            // After the write, so a failed save never points the room at a deleted file.
            if let cleanup {
                try? await FirebaseImageManager.shared.delete(cleanup, type: imageType)
            }
        } catch {
            if let stale = StaleWriteError(error) {
                staleWriteError = stale
                return
            }
            alertMessage = "Failed to update \(isBefore ? "before" : "after") image: \(error.localizedDescription)"
            showAlert = true
        }
    }
}
