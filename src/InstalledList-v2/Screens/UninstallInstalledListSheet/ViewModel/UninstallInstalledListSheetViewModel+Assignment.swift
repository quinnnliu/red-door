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

    /// Picking the address is what brings the copy into existence: it mints the
    /// pull list's ID alongside it, so nothing can be routed to a copy that has
    /// nowhere to go. The `PullListV2` document itself still isn't created
    /// until commit, so backing out afterward leaves nothing behind.
    @MainActor
    func setCopyAddress(_ address: Address) async {
        guard isOwner, let session = sessionState else { return }

        do {
            try await sessionRepo.setCopyDestination(
                sessionId: session.id,
                copyId: session.copyPullListId ?? UUID().uuidString,
                address: address
            )
        } catch {
            present(error)
        }
    }

    func copyDestination() -> UninstallDestination? {
        guard isOwner,
              let session = sessionState,
              let copyId = session.copyPullListId,
              session.copyListAddress != nil
        else { return nil }

        return UninstallDestination(type: .copy, locationId: copyId)
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

    var unassignedItemsByRoom: [(room: RoomV2, items: [ItemV2])] {
        rooms.map { room in
            let items = (itemsByRoom[room.id] ?? [])
                .filter { !essentialsItemIds.contains($0.id) && destination(for: $0.id) == nil }
                .sorted { $0.displayName < $1.displayName }
            return (room: room, items: items)
        }
    }
}

// MARK: - UninstallDestinationSectioning

extension UninstallInstalledListSheetViewModel: UninstallDestinationSectioning {

    var uninstallSession: UninstallSession? { sessionState }

    var copyOriginDisplayName: String { installedListState.displayName }

    var showCopySection: Bool { sessionState?.copyListAddress != nil }

    var showExistingSection: Bool { sessionState?.existingPullListId != nil }
}
