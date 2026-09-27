//
//  UninstallInstalledListSheetViewModel.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/27/26.
//

import Foundation
import Firebase

@Observable
final class UninstallInstalledListSheetViewModel {
    var installedListState: InstalledListV2
    var rooms: [RoomV2] = []
    var itemsByRoom: [String: [ItemV2]] = [:] // key: roomId
    var itemsCache: [String: ItemV2] = [:] // key: itemId

    var isLoading: Bool = false
    var showAlert: Bool = false
    var alertMessage: String = ""

    private var roomsListener: ListenerRegistration? = nil

    private let installedRoomRepo: RoomRepository
    private let itemRepo: ItemRepository

    // MARK: init

    init(
        list: InstalledListV2,
        installedRoomRepo: RoomRepository,
        itemRepo: ItemRepository
    ) {
        self.installedListState = list
        self.installedRoomRepo = installedRoomRepo
        self.itemRepo = itemRepo
    }

    deinit {
        stopListening()
    }

    // MARK: start / stop listening

    @MainActor
    func startListening() async {
        guard roomsListener == nil else { return }
        isLoading = true
        alertMessage = ""

        roomsListener = installedRoomRepo.addRoomsListener { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let rooms):
                    await self?.handleRoomSnapshot(rooms)
                case .failure(let error):
                    self?.handleListenerError(error)
                }
            }
        }
    }

    func stopListening() {
        roomsListener?.remove()
        roomsListener = nil
        itemsCache.removeAll()
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
    }

    @MainActor
    private func handleListenerError(_ error: Error) {
        isLoading = false
        present(error)
    }

    // MARK: fetchItemsForRoom

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

            let loadedItems = room.itemIds.compactMap { itemsCache[$0] }
                .sorted { $0.displayName < $1.displayName }
            let allItemsLoaded = room.itemIds.allSatisfy { itemsCache[$0] != nil }

            if allItemsLoaded || room.itemIds.isEmpty {
                itemsByRoom[room.id] = loadedItems
                alertMessage = ""
            }
        } catch {
            present(error)
        }
    }

    // MARK: refreshItems

    func refreshItems() {
        itemsCache.removeAll()
        itemsByRoom.removeAll()
        Task { @MainActor in
            for room in rooms {
                await fetchItemsForRoom(room)
            }
        }
    }

    // MARK: refreshRoom

    /// Re-fetches a single room's items. Mirrors
    /// `InstalledListDetailsViewModelV2.refreshRoom`.
    func refreshRoom(_ roomId: String) {
        guard let room = rooms.first(where: { $0.id == roomId }) else { return }
        for id in room.itemIds {
            itemsCache.removeValue(forKey: id)
        }
        Task { @MainActor in
            await fetchItemsForRoom(room)
        }
    }

    // MARK: present

    private func present(_ error: Error) {
        alertMessage = error.localizedDescription
        showAlert = true
    }
}
