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
    var itemsCache: [String: ItemV2] = [:] // key: itemId, value: ItemV2

    private var roomsListener: ListenerRegistration? = nil

    private let roomRepo: RoomRepository
    private let itemRepo: ItemRepository
    private let pullListRepo: PullListRepository
    
    var showAlert: Bool = false
    var alertMessage: String = ""
    var showInstallBlockedAlert: Bool = false

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
    
    // MARK: refreshPullListAndRooms

    func refreshPullListAndRooms() {
        itemsCache.removeAll()
        itemsByRoom.removeAll()
        Task { @MainActor in
            await refreshPullListDetails()
            for room in rooms {
                await fetchItemsForRoom(room)
            }
        }
    }
    
    // MARK: refreshPullListDetails
    
    func refreshPullListDetails() async {
        do {
            pullListState = try await pullListRepo.get(id: pullListState.id)
        } catch {
            alertMessage = "Error refreshing pull list, please try again"
            showAlert = true
        }
    }
    
    // MARK: deletePullList
    func deletePullList() async {
        let itemRepo = self.itemRepo
        let roomRepo = self.roomRepo
        let pullListRepo = self.pullListRepo
        let roomSnapshot = self.rooms
        let pullListId = self.pullListState.id

        do {
            _ = try await pullListRepo.db.runTransaction { (transaction, errorPointer) -> Any? in
                // Update all items: clear listId, mark as available
                let allItemIds = roomSnapshot.flatMap { $0.itemIds }
                for itemId in allItemIds {
                    itemRepo.update(
                        id: itemId,
                        fields: [
                            ItemV2.CodingKeys.status.stringValue: ItemStatus.inStorage.rawValue,
                            ItemV2.CodingKeys.locationId.stringValue: Warehouse.warehouse1.id
                        ],
                        in: transaction
                    )
                }

                // Delete all rooms
                for room in roomSnapshot {
                    roomRepo.delete(id: room.id, in: transaction)
                }

                // Delete the pull list
                pullListRepo.delete(id: pullListId, in: transaction)

                return true
            }
        } catch {
            alertMessage = "Failed to delete pull list: \(error.localizedDescription)"
            showAlert = true
            print("[ERROR]: Failed to delete pull list: \(error.localizedDescription)")
        }
    }

    // MARK: computedProperties

    var canOpenInstallSheet: Bool {
        pullListState.installingSession == nil
    }

    func getInstallBlockedMessage() -> String {
        guard let session = pullListState.installingSession else { return "" }
        return "This list is currently being installed by \(session.userId)"
    }

    // MARK: clearInstallingSession

    func clearInstallingSession() {
        let pullListId = pullListState.id
        Task {
            do {
                try await pullListRepo.update(
                    id: pullListId,
                    fields: [PullListV2.CodingKeys.installingSession.stringValue: NSNull()]
                )
                pullListState.installingSession = nil
                alertMessage = "Install lock cleared"
                showAlert = true
            } catch {
                alertMessage = "Failed to clear install lock: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }

    // MARK: createInstallingSession

    func createInstallingSession() async -> Bool {
        let pullListId = pullListState.id

        do {
            let freshList = try await pullListRepo.get(id: pullListId)
            guard freshList.installingSession == nil else {
                alertMessage = "This list is currently being installed by \(freshList.installingSession?.userId ?? "another user")"
                showInstallBlockedAlert = true
                return false
            }

            let session = InstallingSession(userId: "another user", startedAt: Date())
            let sessionData: [String: AnyHashable] = [
                InstallingSession.CodingKeys.userId.stringValue: session.userId,
                InstallingSession.CodingKeys.startedAt.stringValue: session.startedAt
            ]
            try await pullListRepo.update(
                id: pullListId,
                fields: [PullListV2.CodingKeys.installingSession.stringValue: sessionData]
            )
            pullListState.installingSession = session
            return true
        } catch {
            alertMessage = "Failed to create install session: \(error.localizedDescription)"
            showAlert = true
            return false
        }
    }
}

extension PullListV2DetailsViewModel {

    // MARK: createEmptyRoom

    // TODO: remove this duplicate (copy of CreatePullListViewModelV2
    func createEmptyRoom(_ roomName: String) async {
        guard !RoomV2.roomExists(newRoomName: roomName, rooms: rooms) else {
            alertMessage = "Room with same name already exists for this list"
            showAlert = true
            return
        }

        let newRoom = RoomV2(
            displayName: roomName,
            listId: pullListState.id
        )
        do {
            try roomRepo.set(document: newRoom)
            try await pullListRepo.update(
                id: pullListState.id,
                fields: [PullListV2.CodingKeys.roomIds.stringValue: newRoom.id]
            )
        } catch {
            alertMessage = "error adding \(newRoom.displayName): \(error.localizedDescription)"
            showAlert = true
            return
        }

        pullListState.roomIds.append(newRoom.id)
        rooms.append(newRoom)
    }
}
