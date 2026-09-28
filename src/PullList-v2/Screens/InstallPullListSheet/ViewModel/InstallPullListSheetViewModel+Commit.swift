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
    let storageBreakdown: [(warehouseName: String, count: Int)]
}

extension InstallPullListSheetViewModel {

    var confirmInstallSummary: ConfirmInstallSummary {
        let destinations = resolvedItemDestinations.values

        var storageCounts: [String: Int] = [:]
        for destination in destinations where destination.status == .inStorage {
            storageCounts[destination.locationId, default: 0] += 1
        }
        let breakdown = storageCounts.compactMap { warehouseId, count -> (warehouseName: String, count: Int)? in
            guard let name = warehouses.first(where: { $0.id == warehouseId })?.displayName else { return nil }
            return (warehouseName: name, count: count)
        }.sorted { $0.warehouseName < $1.warehouseName }

        return ConfirmInstallSummary(
            address: pullListState.address.getStreetAddress() ?? pullListState.address.formattedAddress,
            installedCount: destinations.filter { $0.status == .inInstalledList }.count,
            storageBreakdown: breakdown
        )
    }

    // MARK: createInstalledList

    /// Applies the whole plan. The transaction lives on
    /// `InstallSessionRepository` — this only handles the surrounding state.
    @MainActor
    func createInstalledList() async -> InstalledListV2? {
        guard isOwner else { return nil }
        isLoading = true
        defer { isLoading = false }

        do {
            let installedList = try await sessionRepo.commit(
                pullList: pullListState,
                rooms: rooms,
                essentialsGroup: essentialsGroupState,
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
