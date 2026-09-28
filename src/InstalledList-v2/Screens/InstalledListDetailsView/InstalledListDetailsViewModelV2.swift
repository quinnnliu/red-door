//
//  InstalledListDetailsViewModelV2.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/25/26.
//

import Foundation
import Firebase

@Observable
final class InstalledListDetailsViewModelV2 {
    var installedListState: InstalledListV2
    var rooms: [RoomV2] = []
    var itemsByRoom: [String: [ItemV2]] = [:]
    var isLoading: Bool = false
    private let loader: ItemsListLoader

    var essentialsGroupState: EssentialsGroup? = nil
    var essentialsAccessories: Accessories? = nil

    var showAlert: Bool = false
    var alertMessage: String = ""

    private var roomsListener: ListenerRegistration? = nil
    private var listListener: ListenerRegistration? = nil

    private let installedListRepo: InstalledListRepository
    private let roomRepo: RoomRepository
    private let itemRepo: ItemRepository
    private let essentialsRepo: EssentialsRepository
    private let accessoriesRepo: AccessoriesRepository

    // MARK: init

    init(
        list: InstalledListV2,
        installedListRepo: InstalledListRepository,
        roomRepo: RoomRepository,
        itemRepo: ItemRepository,
        essentialsRepo: EssentialsRepository,
        accessoriesRepo: AccessoriesRepository
    ) {
        self.installedListState = list
        self.installedListRepo = installedListRepo
        self.roomRepo = roomRepo
        self.itemRepo = itemRepo
        self.essentialsRepo = essentialsRepo
        self.accessoriesRepo = accessoriesRepo
        self.loader = ItemsListLoader(itemRepo: itemRepo)
    }

    /// Detaches only: `deinit` can run on any thread, while the rest of
    /// `stopListening()` mutates state the UI reads on the main thread.
    deinit {
        roomsListener?.remove()
        listListener?.remove()
    }

    // MARK: start / stop listening

    @MainActor
    func startListening() async {
        guard roomsListener == nil else { return }
        isLoading = true
        alertMessage = ""

        roomsListener = roomRepo.addRoomsListener { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let rooms):
                    await self?.handleRoomSnapshot(rooms)
                case .failure(let error):
                    await self?.handleListenerError(error)
                }
            }
        }

        // The rooms listener alone misses changes to the list document itself —
        // an uninstall flips `uninstalled` without touching any room, so
        // without this the footer would keep offering to uninstall an already
        // uninstalled list.
        listListener = installedListRepo.addDocumentListener(id: installedListState.id) { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let list):
                    self?.installedListState = list
                case .failure(let error):
                    await self?.handleListenerError(error)
                }
            }
        }
    }

    func stopListening() {
        roomsListener?.remove()
        roomsListener = nil
        listListener?.remove()
        listListener = nil
        loader.invalidate()
        itemsByRoom.removeAll()
    }

    // MARK: handleRoomSnapshot

    @MainActor
    private func handleRoomSnapshot(_ rooms: [RoomV2]) async {
        isLoading = false
        self.rooms = rooms.sorted { $0.displayName < $1.displayName }

        for room in self.rooms {
            await fetchItemsForRoom(room)
        }

        await refreshInstalledListDetails()
        await fetchEssentialsGroup()
    }

    @MainActor
    private func handleListenerError(_ error: Error) async {
        isLoading = false
        showAlert = true
        alertMessage = error.localizedDescription
    }

    // MARK: fetchItemsForRoom

    @MainActor
    private func fetchItemsForRoom(_ room: RoomV2) async {
        do {
            let loadedItems = try await loader.items(for: room)
            let allItemsLoaded = loader.isComplete(room)

            if allItemsLoaded || room.itemIds.isEmpty {
                itemsByRoom[room.id] = loadedItems
                alertMessage = ""
            }
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }

    // MARK: refreshRoom

    func refreshRoom(_ roomId: String) {
        guard let room = rooms.first(where: { $0.id == roomId }) else { return }
        loader.invalidate(room.itemIds)
        Task { @MainActor in
            await fetchItemsForRoom(room)
        }
    }

    // MARK: refreshInstalledListAndRooms

    func refreshInstalledListAndRooms() {
        loader.invalidate()
        itemsByRoom.removeAll()
        Task { @MainActor in
            await refreshInstalledListDetails()
            for room in rooms {
                await fetchItemsForRoom(room)
            }
        }
    }

    // MARK: refreshInstalledListDetails

    func refreshInstalledListDetails() async {
        do {
            installedListState = try await installedListRepo.get(id: installedListState.id)
        } catch {
            alertMessage = "Error refreshing installed list, please try again"
            showAlert = true
        }
    }

    // MARK: fetchEssentialsGroup

    @MainActor
    func fetchEssentialsGroup() async {
        guard let groupId = installedListState.essentialGroupId else {
            essentialsGroupState = nil
            essentialsAccessories = nil
            return
        }
        do {
            let group = try await essentialsRepo.get(id: groupId)
            essentialsGroupState = group

            if let accessoriesId = group.accessoriesId {
                essentialsAccessories = try await accessoriesRepo.get(id: accessoriesId)
            } else {
                essentialsAccessories = nil
            }
        } catch {
            alertMessage = "Failed to load essentials group: \(error.localizedDescription)"
            showAlert = true
        }
    }
}
