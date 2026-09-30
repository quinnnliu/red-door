//
//  UninstallInstalledListSheetViewModel+Loading.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/27/26.
//

import Foundation

// MARK: - Rooms, items, and storageLocations

extension UninstallInstalledListSheetViewModel {

    // MARK: handleRoomSnapshot

    @MainActor
    func handleRoomSnapshot(_ rooms: [RoomV2]) async {
        isLoading = false
        self.rooms = rooms.sorted { $0.displayName < $1.displayName }

        for room in self.rooms {
            await fetchItemsForRoom(room)
        }
    }

    @MainActor
    func handleListenerError(_ error: Error) {
        isLoading = false
        present(error)
    }

    // MARK: fetchItemsForRoom

    /// Only publishes a room once every one of its items resolved, so the UI
    /// never shows a half-filled room. `allRoomsLoaded` relies on that: a
    /// present `itemsByRoom` key means that room is complete.
    @MainActor
    func fetchItemsForRoom(_ room: RoomV2) async {
        do {
            let items = try await loader.items(for: room)
            if loader.isComplete(room) || room.itemIds.isEmpty {
                itemsByRoom[room.id] = items
            }
        } catch {
            present(error)
        }
    }

    // MARK: loadStorageLocations

    @MainActor
    func loadStorageLocations() async {
        do {
            storageLocations = try await configService.getAll(using: storageLocationRepo)
        } catch {
            present(error)
        }
    }

    // MARK: loadEssentialsGroup

    @MainActor
    func loadEssentialsGroup() async {
        guard let groupId = installedListState.essentialGroupId else {
            essentialsGroupState = nil
            essentialsAccessories = nil
            essentialsItems = []
            return
        }

        do {
            let group = try await essentialsRepo.get(id: groupId)
            essentialsGroupState = group
            essentialsItems = try await loader.items(for: group)
            if let accessoriesId = group.accessoriesId {
                essentialsAccessories = try await accessoriesRepo.get(id: accessoriesId)
            } else {
                essentialsAccessories = nil
            }
        } catch {
            present(error)
        }
    }

    // MARK: refreshItems

    func refreshItems() {
        loader.invalidate()
        itemsByRoom.removeAll()
        Task { @MainActor in
            for room in rooms {
                await fetchItemsForRoom(room)
            }
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
}
