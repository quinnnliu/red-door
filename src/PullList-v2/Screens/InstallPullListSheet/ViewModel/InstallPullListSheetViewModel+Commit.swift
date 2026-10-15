//
//  InstallPullListSheetViewModel+Commit.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/27/26.
//

import Foundation

struct ConfirmInstallSummary {
    let address: String
    let installedCount: Int
    let storageBreakdown: [(storageLocationName: String, count: Int)]
}

extension InstallPullListSheetViewModel {

    var confirmInstallSummary: ConfirmInstallSummary {
        let destinations = resolvedItemDestinations.values

        var storageCounts: [String: Int] = [:]
        for destination in destinations where destination.status == .inStorage {
            storageCounts[destination.locationId, default: 0] += 1
        }
        let breakdown = storageCounts.compactMap { storageLocationId, count -> (storageLocationName: String, count: Int)? in
            guard let name = storageLocations.first(where: { $0.id == storageLocationId })?.displayName else { return nil }
            return (storageLocationName: name, count: count)
        }.sorted { $0.storageLocationName < $1.storageLocationName }

        return ConfirmInstallSummary(
            address: pullListState.address.getStreetAddress() ?? pullListState.address.formattedAddress,
            installedCount: destinations.filter { $0.status == .inInstalledList }.count,
            storageBreakdown: breakdown
        )
    }

    /// Mirrors what the commit enforces, so the button is only offered when it
    /// can succeed. The transaction re-checks all of it.
    var canInstall: Bool {
        isOwner
            && !isLoading
            && allRoomsLoaded
            && pullListState.unassignedItemIds.isEmpty
            && (pullListState.essentialGroupId == nil || essentialsGroupState != nil)
    }

    // MARK: createInstalledList

    /// Applies the whole plan. The transaction lives on
    /// `InstallSessionRepository` — this only handles the surrounding state.
    @MainActor
    func createInstalledList() async -> InstalledListV2? {
        guard isOwner, let generation = myGeneration else { return nil }
        isLoading = true
        isCommitting = true
        defer {
            isLoading = false
            isCommitting = false
        }

        do {
            let installedList = try await sessionRepo.commit(
                pullListId: pullListState.id,
                expectedGeneration: generation,
                reviewedItemIds: Set(rooms.flatMap(\.itemIds)),
                reviewedEssentialsGroupId: essentialsGroupState?.id,
                itemRepo: itemRepo,
                roomRepo: roomRepo,
                pullListRepo: pullListRepo,
                installedListRepo: installedListRepo,
                installedRoomRepo: installedRoomRepo,
                essentialsRepo: essentialsRepo,
                accessoriesRepo: accessoriesRepo
            )
            didCommit = true
            return installedList
        } catch let error as ListCommitError {
            // The listeners have already refreshed the sheet; the alert says why
            // the commit was refused and the user can review and confirm again.
            alertText = error.localizedDescription
            showAlert = true
            return nil
        } catch {
            // If the session already vanished, that message is more useful than
            // the underlying "document not found" this throws.
            if !sessionEndedByOtherUser {
                alertText = "Failed to create installed list: \(error.localizedDescription)"
                showAlert = true
            }
            print("[ERROR] createInstalledList: \(error.localizedDescription)")
            return nil
        }
    }
}
