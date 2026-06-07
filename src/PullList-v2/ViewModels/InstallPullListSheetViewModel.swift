//
//  InstallPullListSheetViewModel.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/6/26.
//

import Foundation
import Firebase

@Observable
final class InstallPullListSheetViewModel {
    var pullListState: PullListV2
    var rooms: [RoomV2] = []
    var itemsByRoom: [String: [ItemV2]] = [:] // key: roomId, value: [ItemV2]
    var isLoading: Bool = false
    var itemsCache: [String: ItemV2] = [:] // key: itemId, value: ItemV2

    private var roomsListener: ListenerRegistration? = nil

    private let roomRepo: RoomRepository
    private let itemRepo: ItemRepository
    private let pullListRepo: PullListRepository

    var showAlert: Bool = false
    var alertText: String = ""

    // MARK: init

    init(from list: PullListV2) {
        self.pullListState = list
        self.roomRepo = RoomRepository(list: list)
        self.itemRepo = ItemRepository()
        self.pullListRepo = PullListRepository()
    }

    deinit {
        stopListening()
    }

    // MARK: start / stop listening

    func startListening() {
        guard roomsListener == nil else { return }
        isLoading = true
        alertText = ""

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
    }

    @MainActor
    private func handleListenerError(_ error: Error) async {
        isLoading = false
        showAlert = true
        alertText = error.localizedDescription
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

            let loadedItems = room.itemIds.compactMap { itemsCache[$0] }.sorted { $0.name < $1.name }
            let allItemsLoaded = room.itemIds.allSatisfy { itemsCache[$0] != nil }

            if allItemsLoaded || room.itemIds.isEmpty {
                itemsByRoom[room.id] = loadedItems
                alertText = ""
            }
        } catch {
            alertText = error.localizedDescription
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

    // MARK: refreshPullList

    func refreshPullList() {
        itemsCache.removeAll()
        itemsByRoom.removeAll()
        Task { @MainActor in
            for room in rooms {
                await fetchItemsForRoom(room)
            }
        }
    }

    // MARK: clearInstallingSession

    func clearInstallingSession() async {
        let pullListId = pullListState.id
        do {
            try await pullListRepo.update(
                id: pullListId,
                fields: [PullListV2.CodingKeys.installingSession.stringValue: NSNull()]
            )
            pullListState.installingSession = nil
        } catch {
            alertText = "Failed to clear install session: \(error.localizedDescription)"
            showAlert = true
            print("[ERROR] Failed to clear install session: \(error.localizedDescription)")
        }
    }
}
