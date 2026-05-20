//
//  PullListV2DetailsViewModel.swift
//  RedDoor
//
//  Created by Quinn Liu on 5/17/26.
//

import Foundation
import Firebase

@Observable
final class PullListV2DetailsViewModel {
    var pullListState: PullListV2
    var rooms: [RoomV2] = []
    var itemsByRoom: [String: [ItemV2]] = [:] // key: roomId, value: [ItemV2]
    var isLoading: Bool = false
    var errorMessage: String? = nil

    private var roomsListener: ListenerRegistration? = nil
    private var itemsCache: [String: ItemV2] = [:] // key: itemId, value: ItemV2

    private let roomRepo: RoomRepository
    private let itemRepo: ItemRepository

    init(from list: PullListV2) {
        self.pullListState = list
        guard let roomRepo = RoomRepository(list: list) else {
            fatalError("PullListV2DetailsViewModel init failed: list is not a PullListV2")
        }
        self.roomRepo = roomRepo
        self.itemRepo = ItemRepository()
    }

    deinit {
        stopListening()
    }

    func startListening() {
        guard roomsListener == nil else { return }
        isLoading = true
        errorMessage = nil

        roomsListener = roomRepo.addRoomsListener { [weak self] snapshot in
            Task { @MainActor in
                await self?.handleRoomSnapshot(snapshot)
            }
        }
    }

    func stopListening() {
        roomsListener?.remove()
        roomsListener = nil
        itemsCache.removeAll()
        itemsByRoom.removeAll()
    }

    @MainActor
    private func handleRoomSnapshot(_ snapshot: RoomRepository.RoomsListenerSnapshot) async {
        isLoading = false
        rooms = snapshot.rooms.sorted { $0.displayName < $1.displayName }

        for change in snapshot.changes {
            if change.type == .added || change.type == .modified {
                guard let room = snapshot.rooms.first(where: { $0.id == change.document.documentID }) else { continue }
                await fetchItemsForRoom(room)
            } else if change.type == .removed {
                itemsByRoom.removeValue(forKey: change.document.documentID)
            }
        }
    }

    @MainActor
    private func fetchItemsForRoom(_ room: RoomV2) async {
        do {
            let uncachedIds = room.items.filter { itemsCache[$0] == nil }
            if !uncachedIds.isEmpty {
                let fetched = try await itemRepo.get(ids: Array(uncachedIds))
                for item in fetched {
                    itemsCache[item.id] = item
                }
            }

            let loadedItems = room.items.compactMap { itemsCache[$0] }.sorted { $0.name < $1.name }
            let allItemsLoaded = room.items.allSatisfy { itemsCache[$0] != nil }

            if allItemsLoaded || room.items.isEmpty {
                itemsByRoom[room.id] = loadedItems
                errorMessage = nil
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refreshRoom(_ roomId: String) {
        guard let room = rooms.first(where: { $0.id == roomId }) else { return }
        let roomItemIds = Set(room.items)
        for id in roomItemIds {
            itemsCache.removeValue(forKey: id)
        }
        Task { @MainActor in
            await fetchItemsForRoom(room)
        }
    }

    func refreshPullList() {
        itemsCache.removeAll()
        itemsByRoom.removeAll()
        Task { @MainActor in
            for room in rooms {
                await fetchItemsForRoom(room)
            }
        }
    }
}
