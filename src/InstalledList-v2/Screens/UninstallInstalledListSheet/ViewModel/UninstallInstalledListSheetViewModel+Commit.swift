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
        guard !isLoading, allRoomsLoaded, let session = sessionState else { return false }
        return allRoomItems.allSatisfy { session.itemDestinations[$0.item.id] != nil }
    }

    var confirmUninstallSummary: ConfirmUninstallSummary {
        ConfirmUninstallSummary(
            address: installedListState.address.getStreetAddress()
                ?? installedListState.address.formattedAddress,
            groups: assignedItemsByDestination.map { (label: $0.label, count: $0.items.count) },
            totalCount: assignedItemCount
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
        isLoading = true
        defer { isLoading = false }

        do {
            try await sessionRepo.commit(
                installedListId: installedListState.id,
                itemRepo: itemRepo,
                installedListRepo: installedListRepo
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
