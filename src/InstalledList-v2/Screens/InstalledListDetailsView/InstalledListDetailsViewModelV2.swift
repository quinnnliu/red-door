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
    var itemsCache: [String: ItemV2] = [:]

    var showAlert: Bool = false
    var alertMessage: String = ""

    private var roomsListener: ListenerRegistration? = nil

    private let installedListRepo: InstalledListRepository
    private let roomRepo: RoomRepository
    private let itemRepo: ItemRepository

    // MARK: init

    init(
        list: InstalledListV2,
        installedListRepo: InstalledListRepository,
        roomRepo: RoomRepository,
        itemRepo: ItemRepository
    ) {
        self.installedListState = list
        self.installedListRepo = installedListRepo
        self.roomRepo = roomRepo
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

        await refreshInstalledListDetails()
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
            let uncachedIds = room.itemIds.filter { itemsCache[$0] == nil }
            if !uncachedIds.isEmpty {
                let fetched = try await itemRepo.get(ids: Array(uncachedIds))
                for item in fetched {
                    itemsCache[item.id] = item
                }
            }

            let loadedItems = room.itemIds.compactMap { itemsCache[$0] }.sorted { $0.displayName < $1.displayName }
            let allItemsLoaded = room.itemIds.allSatisfy { itemsCache[$0] != nil }

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
        let roomItemIds = Set(room.itemIds)
        for id in roomItemIds {
            itemsCache.removeValue(forKey: id)
        }
        Task { @MainActor in
            await fetchItemsForRoom(room)
        }
    }

    // MARK: refreshInstalledListAndRooms

    func refreshInstalledListAndRooms() {
        itemsCache.removeAll()
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
}
