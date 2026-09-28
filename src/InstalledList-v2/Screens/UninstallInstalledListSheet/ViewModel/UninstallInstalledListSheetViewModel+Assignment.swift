//
//  UninstallInstalledListSheetViewModel+Assignment.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/27/26.
//

import Foundation

// MARK: - Selection

extension UninstallInstalledListSheetViewModel {

    func isSelected(_ itemId: String) -> Bool {
        selectedItemIds.contains(itemId)
    }

    func toggleSelection(_ itemId: String) {
        guard isOwner else { return }
        if selectedItemIds.contains(itemId) {
            selectedItemIds.remove(itemId)
        } else {
            selectedItemIds.insert(itemId)
        }
    }

    func clearSelection() {
        selectedItemIds.removeAll()
        essentialsSelected = false
    }

    var essentialsItemIds: Set<String> {
        essentialsGroupState?.itemIds ?? []
    }

    /// The group moves as a unit, so its members are selected together and
    /// never individually.
    func toggleEssentialsSelection() {
        guard isOwner, essentialsGroupState != nil else { return }
        essentialsSelected.toggle()
        if essentialsSelected {
            selectedItemIds.formUnion(essentialsItemIds)
        } else {
            selectedItemIds.subtract(essentialsItemIds)
        }
    }

    var selectionCount: Int { selectedItemIds.count }

    var selectedItems: [ItemV2] {
        selectedItemIds
            .compactMap { loader.cached($0) }
            .sorted { $0.displayName < $1.displayName }
    }
}

// MARK: - Assignment

extension UninstallInstalledListSheetViewModel {

    @MainActor
    func assignSelection(to destination: UninstallDestination) async {
        guard isOwner, let session = sessionState else { return }
        let itemIds = Array(selectedItemIds.subtracting(essentialsItemIds))
        guard !itemIds.isEmpty || essentialsSelected else { return }

        do {
            if !itemIds.isEmpty {
                try await sessionRepo.assign(
                    sessionId: session.id,
                    itemIds: itemIds,
                    destination: destination
                )
            }
            if essentialsSelected {
                try await sessionRepo.assignEssentials(sessionId: session.id, destination: destination)
            }
            clearSelection()
        } catch {
            present(error)
        }
    }

    /// Mints the copy pull list's ID the first time anything is routed to it.
    /// The `PullListV2` document itself isn't created until commit, so opening
    /// this option and then backing out leaves nothing behind.
    @MainActor
    func copyDestination() async -> UninstallDestination? {
        guard isOwner, let session = sessionState else { return nil }

        if let existing = session.copyPullListId {
            return UninstallDestination(type: .copy, locationId: existing)
        }

        let newId = UUID().uuidString
        do {
            try await sessionRepo.setCopyPullListId(sessionId: session.id, newId)
            return UninstallDestination(type: .copy, locationId: newId)
        } catch {
            present(error)
            return nil
        }
    }

    @MainActor
    func existingListDestination(_ list: PullListV2) async -> UninstallDestination? {
        guard isOwner, let session = sessionState else { return nil }

        // `PullListV2.essentialGroupId` holds a single group, so a target that
        // already has one can't also receive ours.
        let essentialsHeadedHere = essentialsSelected
            || session.essentialsDestination?.type == .existingList
        if essentialsHeadedHere, list.essentialGroupId != nil {
            alertMessage = "\(list.displayName) already has an essentials group. Pick a different list, or send essentials elsewhere."
            showAlert = true
            return nil
        }

        do {
            try await sessionRepo.setExistingPullListId(sessionId: session.id, list.id)
            existingPullList = list
            return UninstallDestination(type: .existingList, locationId: list.id)
        } catch {
            present(error)
            return nil
        }
    }

    @MainActor
    func unassignEssentials() async {
        guard isOwner, let session = sessionState else { return }
        do {
            try await sessionRepo.assignEssentials(sessionId: session.id, destination: nil)
        } catch {
            present(error)
        }
    }

    @MainActor
    func unassign(itemId: String) async {
        guard isOwner, let session = sessionState else { return }
        do {
            try await sessionRepo.unassign(sessionId: session.id, itemIds: [itemId])
        } catch {
            present(error)
        }
    }
}

// MARK: - Grouping

extension UninstallInstalledListSheetViewModel {
    /// Excludes essentials members throughout: they render in their own
    /// section and are assigned as a unit, so they must never appear as an
    /// individually assignable room row.
    var allRoomItems: [(item: ItemV2, room: RoomV2)] {
        rooms.flatMap { room in
            (itemsByRoom[room.id] ?? [])
                .filter { !essentialsItemIds.contains($0.id) }
                .map { (item: $0, room: room) }
        }
    }

    var unassignedItemsByRoom: [(room: RoomV2, items: [ItemV2])] {
        rooms.map { room in
            let items = (itemsByRoom[room.id] ?? [])
                .filter { !essentialsItemIds.contains($0.id) && destination(for: $0.id) == nil }
                .sorted { $0.displayName < $1.displayName }
            return (room: room, items: items)
        }
    }

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
}

// MARK: - Destination lookup

extension UninstallInstalledListSheetViewModel {

    func destination(for itemId: String) -> UninstallDestination? {
        sessionState?.itemDestinations[itemId]
    }

    var essentialsDestinationLabel: String? {
        sessionState?.essentialsDestination.map { label(for: $0) }
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
            return existingPullList?.displayName ?? "Pull list"
        }
    }
}
