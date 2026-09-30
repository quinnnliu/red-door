//
//  PullListDetailsViewModelV2.swift
//  RedDoor
//
//  Created by Quinn Liu on 5/17/26.
//

import Foundation
import Firebase

@Observable
final class PullListDetailsViewModelV2 {
    var pullListState: PullListV2
    var rooms: [RoomV2] = []
    var itemsByRoom: [String: [ItemV2]] = [:] // key: roomId, value: [ItemV2]
    var unassignedItems: Set<ItemV2> = []
    var selectedUnassignedItems: Set<ItemV2> = []
    var isLoading: Bool = false
    private let loader: ItemsListLoader

    var essentialsGroupState: EssentialsGroup? = nil
    var essentialsAccessories: Accessories? = nil
    var availableStorageLocations: [StorageLocation] = []

    private var roomsListener: ListenerRegistration? = nil
    private var listListener: ListenerRegistration? = nil
    private var didApplyFirstListSnapshot = false

    private let roomRepo: RoomRepository<PullListV2>
    private let itemRepo: ItemRepository
    private let pullListRepo: PullListRepository
    private let essentialsRepo: EssentialsRepository
    private let accessoriesRepo: AccessoriesRepository

    var showAlert: Bool = false
    var alertMessage: String = ""

    // MARK: init

    init(
        list: PullListV2,
        roomRepo: RoomRepository<PullListV2>,
        itemRepo: ItemRepository,
        pullListRepo: PullListRepository,
        essentialsRepo: EssentialsRepository,
        accessoriesRepo: AccessoriesRepository
    ) {
        self.pullListState = list
        self.roomRepo = roomRepo
        self.itemRepo = itemRepo
        self.pullListRepo = pullListRepo
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

        // The rooms listener alone misses changes to the list document itself
        // — attaching an essentials group or assigning an item from another
        // device rewrites `unassignedItemIds` without touching any room.
        // Loading the essentials group and the unassigned pool hangs off this
        // listener's first snapshot rather than a separate fetch here, so the
        // list document has exactly one writer.
        listListener = pullListRepo.addDocumentListener(id: pullListState.id) { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let list):
                    await self?.handleListSnapshot(list)
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
        didApplyFirstListSnapshot = false
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
    }

    // MARK: handleListSnapshot

    /// Gated on what actually changed: the list document is rewritten by room
    /// creation and by every item assignment, so refetching unconditionally
    /// would re-read the whole unassigned pool on writes that never touched
    /// it. Compared as sets because `arrayUnion` appends and `arrayRemove`
    /// compacts, so the stored order churns without the membership moving.
    @MainActor
    private func handleListSnapshot(_ list: PullListV2) async {
        let isFirstSnapshot = !didApplyFirstListSnapshot
        didApplyFirstListSnapshot = true

        let unassignedChanged = isFirstSnapshot
            || Set(list.unassignedItemIds) != Set(pullListState.unassignedItemIds)
        let essentialsChanged = isFirstSnapshot
            || list.essentialGroupId != pullListState.essentialGroupId

        pullListState = list

        if essentialsChanged { await fetchEssentialsGroup() }
        if unassignedChanged { await fetchUnassignedItems() }
    }

    @MainActor
    private func handleListenerError(_ error: Error) async {
        isLoading = false

        // Committing an install deletes this list while the install sheet is
        // still covering this screen. The screen is on its way out; there is
        // nothing to tell the user.
        guard !RepositoryError.isDocumentNotFound(error) else { return }

        showAlert = true
        alertMessage = error.localizedDescription
    }

    // MARK: fetchUnassignedItems

    @MainActor
    func fetchUnassignedItems() async {
        let ids = pullListState.unassignedItemIds
        guard !ids.isEmpty else {
            unassignedItems = []
            selectedUnassignedItems = []
            return
        }
        do {
            // Selection is re-derived by ID, not carried over: another device
            // can pull an item out of the pool from under a selection, and a
            // refetched item is a different value even when it is the same
            // item, which `Set<ItemV2>` membership would miss.
            let selectedIds = Set(selectedUnassignedItems.map(\.id))
            unassignedItems = Set(try await loader.items(ids: ids))
            selectedUnassignedItems = unassignedItems.filter { selectedIds.contains($0.id) }
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
        }
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

    // MARK: refreshPullListAndRooms

    /// The list document and its rooms arrive via listeners, so only the item
    /// and essentials documents they reference need a manual re-read. Re-reading
    /// the list here too would race its own listener with a staler value.
    func refreshPullListAndRooms() {
        loader.invalidate()
        itemsByRoom.removeAll()
        Task { @MainActor in
            for room in rooms {
                await fetchItemsForRoom(room)
            }
            await fetchEssentialsGroup()
            await fetchUnassignedItems()
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
            alertMessage = "Failed to load essentials group: \(error.localizedDescription)"
            showAlert = true
        }
    }

    // MARK: fetchAvailableStorageLocations

    func fetchAvailableStorageLocations() async {
        do {
            availableStorageLocations = try await ConfigurationService.shared.getAll(using: StorageLocationRepository())
        } catch {
            alertMessage = "Failed to load storage locations: \(error.localizedDescription)"
            showAlert = true
        }
    }

    // MARK: removeEssentialsGroup

    @MainActor
    func removeEssentialsGroup(to storageLocation: StorageLocation) async {
        guard let group = essentialsGroupState else { return }

        let batch = essentialsRepo.db.batch()

        let storageFields: [String: Any] = DocumentLocation(
            status: .inStorage,
            locationId: storageLocation.id
        ).firebaseUpdateFields

        for itemId in group.itemIds {
            itemRepo.update(id: itemId, fields: storageFields, inBatch: batch)
        }

        if let accessoriesId = group.accessoriesId {
            accessoriesRepo.update(id: accessoriesId, fields: storageFields, inBatch: batch)
        }

        essentialsRepo.update(id: group.id, fields: storageFields, inBatch: batch)

        pullListRepo.update(
            id: pullListState.id,
            fields: [
                PullListV2.CodingKeys.essentialGroupId.stringValue: NSNull(),
                PullListV2.CodingKeys.unassignedItemIds.stringValue: FieldValue.arrayRemove(Array(group.itemIds))
            ],
            inBatch: batch
        )

        let essentialItemSet = Set(group.itemIds)
        for room in rooms {
            let overlap = room.itemIds.intersection(essentialItemSet)
            if !overlap.isEmpty {
                roomRepo.update(
                    id: room.id,
                    fields: [RoomV2.CodingKeys.itemIds.stringValue: FieldValue.arrayRemove(Array(overlap))],
                    inBatch: batch
                )
            }
        }

        do {
            try await batch.commit()
            // These items' locations just moved to storage; the cached copies
            // still say otherwise.
            loader.invalidate(group.itemIds)
            pullListState.essentialGroupId = nil
            pullListState.unassignedItemIds.removeAll { essentialItemSet.contains($0) }
            unassignedItems = unassignedItems.filter { !essentialItemSet.contains($0.id) }
            selectedUnassignedItems = selectedUnassignedItems.filter { !essentialItemSet.contains($0.id) }
            essentialsGroupState = nil
            essentialsAccessories = nil
            availableStorageLocations = []
        } catch {
            alertMessage = "Failed to remove essentials group: \(error.localizedDescription)"
            showAlert = true
        }
    }

    // MARK: deletePullList

    /// A list holds items in three places — its rooms, its unassigned pool, and
    /// an attached essentials group. All three must be clear before deleting,
    /// because deletion doesn't relocate anything.
    ///
    /// Reads `essentialGroupId` off the list document rather than the fetched
    /// `essentialsGroupState`, which is still nil while loading.
    var isEmptyOfItems: Bool {
        rooms.allSatisfy { $0.itemIds.isEmpty }
            && pullListState.unassignedItemIds.isEmpty
            && pullListState.essentialGroupId == nil
    }

    @MainActor
    func deletePullList() async -> Bool {
        guard isEmptyOfItems else {
            alertMessage = "Remove all items and any essentials group before deleting this pull list."
            showAlert = true
            return false
        }

        do {
            try await pullListRepo.delete(
                pullListState.id,
                rooms: rooms,
                roomRepo: roomRepo
            )
            return true
        } catch {
            alertMessage = "Failed to delete pull list: \(error.localizedDescription)"
            showAlert = true
            print("[ERROR]: Failed to delete pull list: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: computedProperties
}

extension PullListDetailsViewModelV2 {

    // MARK: createEmptyRoom

    // TODO: remove this duplicate (copy of CreatePullListViewModelV2
    func createEmptyRoom(_ roomName: String) async {
        guard !RoomV2.roomExists(newRoomName: roomName, rooms: rooms) else {
            alertMessage = "Room with same name already exists for this list"
            showAlert = true
            return
        }

        let newRoom = RoomV2(
            baseName: roomName,
            listId: pullListState.id
        )
        do {
            try roomRepo.set(document: newRoom)
            try await pullListRepo.update(
                id: pullListState.id,
                fields: [PullListV2.CodingKeys.roomIds.stringValue: FieldValue.arrayUnion([newRoom.id])]
            )
        } catch {
            alertMessage = "error adding \(newRoom.displayName): \(error.localizedDescription)"
            showAlert = true
            return
        }
    }
}

// MARK: - Unassigned Item Selection

extension PullListDetailsViewModelV2 {
    func isUnassignedSelected(_ item: ItemV2) -> Bool {
        selectedUnassignedItems.contains(item)
    }

    func selectUnassigned(_ item: ItemV2) {
        selectedUnassignedItems.insert(item)
    }

    func deselectUnassigned(_ item: ItemV2) {
        selectedUnassignedItems.remove(item)
    }

    func deselectAllUnassigned() {
        selectedUnassignedItems.removeAll()
    }
}

// MARK: - Assign Unassigned Items to Room

extension PullListDetailsViewModelV2 {
    @MainActor
    func assignSelectedItemsToRoom(_ room: RoomV2) async {
        guard !selectedUnassignedItems.isEmpty else { return }

        let itemIds = selectedUnassignedItems.map { $0.id }

        do {
            try await roomRepo.assignUnassignedItems(
                itemIds,
                toRoomId: room.id,
                itemRepo: itemRepo,
                pullListRepo: pullListRepo
            )

            loader.invalidate(itemIds)
            unassignedItems.subtract(selectedUnassignedItems)
            pullListState.unassignedItemIds.removeAll { itemIds.contains($0) }
            selectedUnassignedItems.removeAll()
        } catch {
            alertMessage = "Failed to assign items to \(room.displayName): \(error.localizedDescription)"
            showAlert = true
        }
    }

    // MARK: storeUnassignedItem

    /// Essentials items leave the list with their group, never on their own.
    @MainActor
    func storeUnassignedItem(_ item: ItemV2, in storageLocation: StorageLocation) async {
        guard item.essentialGroupId == nil else {
            alertMessage = "\(item.displayName) belongs to an essentials group and must be removed with the group"
            showAlert = true
            return
        }

        do {
            try await pullListRepo.storeUnassignedItems(
                [item.id],
                fromListId: pullListState.id,
                toStorageId: storageLocation.id,
                itemRepo: itemRepo
            )

            loader.invalidate([item.id])
            pullListState.unassignedItemIds.removeAll { $0 == item.id }
            unassignedItems = unassignedItems.filter { $0.id != item.id }
            selectedUnassignedItems = selectedUnassignedItems.filter { $0.id != item.id }
        } catch {
            alertMessage = "Failed to store \(item.displayName): \(error.localizedDescription)"
            showAlert = true
        }
    }
}
