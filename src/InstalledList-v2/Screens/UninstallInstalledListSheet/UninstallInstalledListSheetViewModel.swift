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
    var warehouses: [WarehouseV2] = []

    /// Server truth for the uninstall plan, replaced wholesale by the listener.
    var sessionState: UninstallSession? = nil

    /// Ephemeral per-user UI state. Deliberately NOT stored on the session:
    /// selection is not shared between users, only assignments are.
    var selectedItemIds: Set<String> = []

    /// The lock generation this client claimed. In-memory only: if the app is
    /// killed the owner forgets it holds the lock and reopens as a viewer,
    /// which costs one tap to reclaim. Persisting it would reintroduce
    /// per-device state for no real gain.
    private var myGeneration: Int? = nil

    var isLoading: Bool = false
    var showAlert: Bool = false
    var alertMessage: String = ""
    var showDestinationSheet: Bool = false

    private var roomsListener: ListenerRegistration? = nil
    private var sessionListener: ListenerRegistration? = nil

    private let installedRoomRepo: RoomRepository
    private let itemRepo: ItemRepository
    private let sessionRepo: UninstallSessionRepository
    private let warehouseRepo: WarehouseRepository
    private let configService: ConfigurationService

    // MARK: init

    init(
        list: InstalledListV2,
        installedRoomRepo: RoomRepository,
        itemRepo: ItemRepository,
        sessionRepo: UninstallSessionRepository,
        warehouseRepo: WarehouseRepository,
        configService: ConfigurationService = .shared
    ) {
        self.installedListState = list
        self.installedRoomRepo = installedRoomRepo
        self.itemRepo = itemRepo
        self.sessionRepo = sessionRepo
        self.warehouseRepo = warehouseRepo
        self.configService = configService
    }

    deinit {
        stopListening()
    }

    // MARK: Ownership

    /// Correct from the start, but not yet load-bearing: mutations are
    /// ungated until the collaboration phase wires this into the UI.
    var isOwner: Bool {
        guard let mine = myGeneration, let session = sessionState else { return false }
        return mine == session.lockGeneration
    }

    var isReadOnly: Bool { !isOwner }

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

        sessionListener = sessionRepo.addSessionListener(id: installedListState.id) { [weak self] result in
            Task { @MainActor in
                self?.handleSessionSnapshot(result)
            }
        }

        await joinOrCreateSession()
        await loadWarehouses()
    }

    func stopListening() {
        roomsListener?.remove()
        roomsListener = nil
        sessionListener?.remove()
        sessionListener = nil
        itemsCache.removeAll()
        itemsByRoom.removeAll()
        selectedItemIds.removeAll()
    }

    // MARK: joinOrCreateSession

    @MainActor
    private func joinOrCreateSession() async {
        do {
            myGeneration = try await sessionRepo.createSession(id: installedListState.id)
            // nil -> a session already existed; we joined it and the listener
            //        will deliver its state.

            // Seed optimistically when we created it, so ownership reads as true
            // immediately rather than after the first snapshot arrives.
            if let generation = myGeneration, sessionState == nil {
                sessionState = UninstallSession(
                    id: installedListState.id,
                    lockGeneration: generation
                )
            }
        } catch {
            present(error)
        }
    }

    // MARK: handleSessionSnapshot

    @MainActor
    private func handleSessionSnapshot(_ result: Result<UninstallSession?, Error>) {
        switch result {
        case .success(let session):
            sessionState = session
            if session == nil {
                myGeneration = nil
                selectedItemIds.removeAll()
            }
        case .failure(let error):
            present(error)
        }
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

    // MARK: loadWarehouses

    @MainActor
    private func loadWarehouses() async {
        do {
            warehouses = try await configService.getAll(using: warehouseRepo)
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

    // MARK: Selection

    func isSelected(_ itemId: String) -> Bool {
        selectedItemIds.contains(itemId)
    }

    func toggleSelection(_ itemId: String) {
        if selectedItemIds.contains(itemId) {
            selectedItemIds.remove(itemId)
        } else {
            selectedItemIds.insert(itemId)
        }
    }

    func clearSelection() {
        selectedItemIds.removeAll()
    }

    var selectionCount: Int { selectedItemIds.count }

    var selectedItems: [ItemV2] {
        selectedItemIds
            .compactMap { itemsCache[$0] }
            .sorted { $0.displayName < $1.displayName }
    }

    // MARK: Assignment

    /// Writes every selected item's destination in one Firestore update.
    @MainActor
    func assignSelection(to destination: UninstallDestination) async {
        guard let session = sessionState else { return }
        let itemIds = Array(selectedItemIds)
        guard !itemIds.isEmpty else { return }

        do {
            try await sessionRepo.assign(
                sessionId: session.id,
                itemIds: itemIds,
                destination: destination
            )
            clearSelection()
        } catch {
            present(error)
        }
    }

    @MainActor
    func unassign(itemId: String) async {
        guard let session = sessionState else { return }
        do {
            try await sessionRepo.unassign(sessionId: session.id, itemIds: [itemId])
        } catch {
            present(error)
        }
    }

    // MARK: Derived state

    /// Every item across every room, flat, paired with the room it belongs to
    /// so each row can show its room chip.
    private var allRoomItems: [(item: ItemV2, room: RoomV2)] {
        rooms.flatMap { room in
            (itemsByRoom[room.id] ?? []).map { (item: $0, room: room) }
        }
    }

    /// Unassigned items, grouped by room. Nothing has moved yet, so the room
    /// is still the most useful way to browse what's left — one entry per
    /// room (even empty ones, matching `InstallPullListSheet`'s room list).
    var unassignedItemsByRoom: [(room: RoomV2, items: [ItemV2])] {
        rooms.map { room in
            let items = (itemsByRoom[room.id] ?? [])
                .filter { destination(for: $0.id) == nil }
                .sorted { $0.displayName < $1.displayName }
            return (room: room, items: items)
        }
    }

    /// Assigned items, flattened across rooms and grouped by where they're
    /// headed. Once an item is assigned, its room of origin is no longer the
    /// organizing question — the destination is. Groups appear in the order
    /// their first item was assigned.
    var assignedItemsByDestination: [(label: String, items: [(item: ItemV2, room: RoomV2)])] {
        var order: [String] = []
        var groups: [String: [(item: ItemV2, room: RoomV2)]] = [:]

        for entry in allRoomItems {
            guard let label = destinationLabel(for: entry.item.id) else { continue }
            if groups[label] == nil {
                order.append(label)
                groups[label] = []
            }
            groups[label]?.append(entry)
        }

        return order.map { label in
            (label: label, items: groups[label]!.sorted { $0.item.displayName < $1.item.displayName })
        }
    }

    var assignedItemCount: Int {
        assignedItemsByDestination.reduce(0) { $0 + $1.items.count }
    }

    func destination(for itemId: String) -> UninstallDestination? {
        sessionState?.itemDestinations[itemId]
    }

    func destinationLabel(for itemId: String) -> String? {
        destination(for: itemId).map { label(for: $0) }
    }

    func label(for destination: UninstallDestination) -> String {
        switch destination.type {
        case .warehouse:
            return warehouses.first(where: { $0.id == destination.locationId })?.displayName ?? "Warehouse"
        case .copy:
            return "Copy of \(installedListState.displayName)"
        case .existingList:
            return "Pull list"
        }
    }

    // MARK: present

    private func present(_ error: Error) {
        alertMessage = error.localizedDescription
        showAlert = true
    }
}
