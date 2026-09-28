//
//  InstallPullListSheetViewModel+Loading.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/27/26.
//

import Foundation

extension InstallPullListSheetViewModel {

    // MARK: handleRoomSnapshot

    @MainActor
    func handleRoomSnapshot(_ rooms: [RoomV2]) async {
        isLoading = false
        self.rooms = rooms.sorted { $0.displayName < $1.displayName }

        for room in self.rooms {
            await fetchItemsForRoom(room)
        }

        await fetchEssentialsGroup()
    }

    @MainActor
    func handleListenerError(_ error: Error) {
        isLoading = false
        present(error)
    }

    // MARK: fetchItemsForRoom

    @MainActor
    func fetchItemsForRoom(_ room: RoomV2) async {
        do {
            let loadedItems = try await loader.items(for: room)
            if loader.isComplete(room) || room.itemIds.isEmpty {
                itemsByRoom[room.id] = loadedItems
            }
        } catch {
            present(error)
        }
    }

    // MARK: fetchEssentialsGroup

    @MainActor
    func fetchEssentialsGroup() async {
        guard let groupId = pullListState.essentialGroupId else {
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
            alertText = "Failed to load essentials group: \(error.localizedDescription)"
            showAlert = true
        }
    }

    // MARK: getWarehouses

    @MainActor
    func getWarehouses() async {
        do {
            warehouses = try await configService.getAll(using: warehouseRepo)
        } catch {
            present(error)
        }
    }

    // MARK: refresh

    func refreshRoom(_ roomId: String) {
        guard let room = rooms.first(where: { $0.id == roomId }) else { return }
        loader.invalidate(room.itemIds)
        Task { @MainActor in
            await fetchItemsForRoom(room)
        }
    }

    func refreshPullList() {
        loader.invalidate()
        itemsByRoom.removeAll()
        Task { @MainActor in
            for room in rooms {
                await fetchItemsForRoom(room)
            }
        }
    }
}
