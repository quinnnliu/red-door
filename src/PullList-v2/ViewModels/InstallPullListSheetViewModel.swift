//
//  InstallPullListSheetViewModel.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/6/26.
//

import Foundation
import Firebase

struct ConfirmInstallSummary {
    let address: String
    let installedCount: Int
    let storageBreakdown: [(warehouseName: String, count: Int)]
}

@Observable
final class InstallPullListSheetViewModel {
    var pullListState: PullListV2
    var rooms: [RoomV2] = []
    var itemsByRoom: [String: [ItemV2]] = [:] // key: roomId, value: [ItemV2]
    var isLoading: Bool = false
    var itemsCache: [String: ItemV2] = [:] // key: itemId, value: ItemV2
    var itemInstallStates: [String: (status: LocationStatus, locationId: String)] = [:] // key: itemId
    var warehouses: [WarehouseV2] = []
    
    private var roomsListener: ListenerRegistration? = nil

    private let roomRepo: RoomRepository
    private let itemRepo: ItemRepository
    private let pullListRepo: PullListRepository
    private let warehouseRepo: WarehouseRepository
    private let installedListRepo: InstalledListRepository
    private let installedRoomRepo: RoomRepository

    var showAlert: Bool = false
    var alertText: String = ""
    var showConfirmSheet: Bool = false

    // MARK: init

    init(from list: PullListV2, rooms: [RoomV2] = [], itemsByRoom: [String: [ItemV2]] = [:]) {
        self.pullListState = list
        self.roomRepo = RoomRepository(list: list)
        self.itemRepo = ItemRepository()
        self.pullListRepo = PullListRepository()
        self.warehouseRepo = WarehouseRepository()
        self.installedListRepo = InstalledListRepository()
        self.installedRoomRepo = RoomRepository(parentCollectionName: InstalledListV2.collectionName, listId: list.id)
        self.rooms = rooms
        self.itemsByRoom = itemsByRoom
        for item in itemsByRoom.values.joined() {
            self.itemInstallStates[item.id] = (status: .inInstalledList, locationId: item.locationId)
            self.itemsCache[item.id] = item
        }
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
                    if itemInstallStates[item.id] == nil {
                        itemInstallStates[item.id] = (status: .inInstalledList, locationId: item.locationId)
                    }
                }
            }

            let loadedItems = room.itemIds.compactMap { itemsCache[$0] }.sorted { $0.displayName < $1.displayName }
            let allItemsLoaded = room.itemIds.allSatisfy { itemsCache[$0] != nil }

            if allItemsLoaded || room.itemIds.isEmpty {
                itemsByRoom[room.id] = loadedItems
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
    
    // MARK: getWarehouses
    func getWarehouses() async {
        warehouses = await warehouseRepo.getWarehouses()
    }

    // MARK: confirmInstallSummary

    var confirmInstallSummary: ConfirmInstallSummary {
        let installedCount = itemInstallStates.values.filter { $0.status == .inInstalledList }.count
        var storageCounts: [String: Int] = [:]
        for state in itemInstallStates.values where state.status == .inStorage {
            storageCounts[state.locationId, default: 0] += 1
        }
        let breakdown = storageCounts.compactMap { warehouseId, count -> (warehouseName: String, count: Int)? in
            guard let name = warehouses.first(where: { $0.id == warehouseId })?.displayName else { return nil }
            return (warehouseName: name, count: count)
        }.sorted { $0.warehouseName < $1.warehouseName }

        return ConfirmInstallSummary(
            address: pullListState.address.getStreetAddress() ?? pullListState.address.formattedAddress,
            installedCount: installedCount,
            storageBreakdown: breakdown
        )
    }

    // MARK: createInstalledList
    @MainActor
    func createInstalledList() async -> InstalledListV2? {
        let installedList = InstalledListV2(from: pullListState)
        let roomSnapshot = rooms
        let stateSnapshot = itemInstallStates
        let installedListRepo = self.installedListRepo
        let installedRoomRepo = self.installedRoomRepo
        let itemRepo = self.itemRepo
        let roomRepo = self.roomRepo
        let pullListRepo = self.pullListRepo

        isLoading = true
        defer { isLoading = false }

        do {
            let batch = installedListRepo.newBatch()

            // 1. Create InstalledListV2 document
            try installedListRepo.set(document: installedList, id: installedList.id, inBatch: batch)

            // 2. Create room documents under installed list
            for room in roomSnapshot {
                try installedRoomRepo.set(document: room, id: room.id, inBatch: batch)
            }

            // 3. Update item statuses and locations
            for (itemId, state) in stateSnapshot {
                itemRepo.update(
                    id: itemId,
                    fields: [
                        ItemV2.CodingKeys.status.stringValue: state.status.rawValue,
                        ItemV2.CodingKeys.locationId.stringValue: state.locationId
                    ],
                    inBatch: batch
                )
            }

            // 4. Delete original pull list rooms
            for room in roomSnapshot {
                roomRepo.delete(id: room.id, inBatch: batch)
            }

            // 5. Delete original pull list document
            pullListRepo.delete(id: installedList.id, inBatch: batch)

            try await batch.commit()
            return installedList
        } catch {
            alertText = "Failed to create installed list: \(error.localizedDescription)"
            showAlert = true
            print("[ERROR] createInstalledList: \(error.localizedDescription)")
            return nil
        }
    }
}
