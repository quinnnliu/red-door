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
    let groups: [(title: String, subtitle: String?, count: Int)]
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
        // Commit refuses to build a copy with no address, so don't offer it.
        let copyAddressed = !session.targetsCopy || session.copyListAddress != nil
        return itemsAssigned && essentialsAssigned && copyAddressed
    }

    /// Mirrors the three destination sections. Essentials members are excluded
    /// from those sections so they don't duplicate their own row, so their
    /// count is folded into whichever destination they're headed for.
    var confirmUninstallSummary: ConfirmUninstallSummary {
        let essentials = sessionState?.essentialsDestination
        let essentialsCount = essentialsItems.count

        var groups: [(title: String, subtitle: String?, count: Int)] = []
        var essentialsCounted = false

        func count(_ base: Int, addingEssentialsFor type: UninstallDestinationType, locationId: String? = nil) -> Int {
            guard let essentials, essentials.type == type else { return base }
            if let locationId, essentials.locationId != locationId { return base }
            essentialsCounted = true
            return base + essentialsCount
        }

        for group in storageGroups {
            groups.append((
                title: group.storageLocation,
                subtitle: nil,
                count: count(group.items.count, addingEssentialsFor: .storage, locationId: group.storageLocationId)
            ))
        }

        let copyCount = count(copyItems.count, addingEssentialsFor: .copy)
        if copyCount > 0 {
            groups.append((title: copySectionTitle, subtitle: copySectionSubtitle, count: copyCount))
        }

        let existingCount = count(existingListItems.count, addingEssentialsFor: .existingList)
        if existingCount > 0 {
            groups.append((title: existingSectionTitle, subtitle: nil, count: existingCount))
        }

        // Essentials can be the only thing sent to a given storage location, which has
        // no storage group of its own to fold into.
        if let essentials, !essentialsCounted, essentialsCount > 0 {
            let essentialsLabel = label(for: essentials)
            groups.append((
                title: essentialsLabel.title,
                subtitle: essentialsLabel.subtitle,
                count: essentialsCount
            ))
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
