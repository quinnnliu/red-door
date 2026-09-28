//
//  UninstallInstalledListSheetViewModel+Commit.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/27/26.
//

import Foundation

/// Breakdown shown on the confirm sheet. Deliberately just labeled groups
/// rather than per-destination-type fields, so later destinations show up as
/// new groups without touching this type.
struct ConfirmUninstallSummary {
    let address: String
    let groups: [(label: String, count: Int)]
    let totalCount: Int
}

// MARK: - Commit gating

extension UninstallInstalledListSheetViewModel {

    var allRoomsLoaded: Bool {
        rooms.allSatisfy { itemsByRoom[$0.id] != nil }
    }

    var allAssigned: Bool {
        guard isOwner, !isLoading, allRoomsLoaded, let session = sessionState else { return false }
        let itemsAssigned = allRoomItems.allSatisfy { session.itemDestinations[$0.item.id] != nil }
        let essentialsAssigned = essentialsGroupState == nil || session.essentialsDestination != nil
        return itemsAssigned && essentialsAssigned
    }

    /// Essentials members are excluded from `assignedItemsByDestination` so they
    /// don't duplicate their own section, so their count is folded in here.
    var confirmUninstallSummary: ConfirmUninstallSummary {
        var groups = assignedItemsByDestination.map { (label: $0.label, count: $0.items.count) }

        if let label = essentialsDestinationLabel {
            if let index = groups.firstIndex(where: { $0.label == label }) {
                groups[index].count += essentialsItems.count
            } else {
                groups.append((label: label, count: essentialsItems.count))
            }
        }

        return ConfirmUninstallSummary(
            address: installedListState.address.getStreetAddress()
                ?? installedListState.address.formattedAddress,
            groups: groups,
            totalCount: groups.reduce(0) { $0 + $1.count }
        )
    }
}

// MARK: - Commit

extension UninstallInstalledListSheetViewModel {

    /// Applies the whole plan. Returns false and surfaces an alert on failure.
    /// The transaction itself lives on `UninstallSessionRepository` — this only
    /// handles the surrounding view state.
    @MainActor
    func commitUninstall() async -> Bool {
        guard isOwner else { return false }
        isLoading = true
        defer { isLoading = false }

        do {
            try await sessionRepo.commit(
                installedList: installedListState,
                rooms: rooms,
                essentialsGroup: essentialsGroupState,
                itemRepo: itemRepo,
                installedListRepo: installedListRepo,
                pullListRepo: pullListRepo,
                essentialsRepo: essentialsRepo,
                accessoriesRepo: accessoriesRepo
            )
            didCommit = true
            installedListState.uninstalled = true
            return true
        } catch {
            // If the session already vanished, that message is more useful than
            // the underlying "document not found" this throws.
            if !sessionEndedByOtherUser {
                alertMessage = "Failed to uninstall: \(error.localizedDescription)"
                showAlert = true
            }
            print("[ERROR] commitUninstall: \(error.localizedDescription)")
            return false
        }
    }
}
