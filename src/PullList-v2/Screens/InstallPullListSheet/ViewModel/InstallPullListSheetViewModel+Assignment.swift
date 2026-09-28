//
//  InstallPullListSheetViewModel+Assignment.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/27/26.
//

import Foundation

extension InstallPullListSheetViewModel {

    /// What the pickers render. The session stores only diversions to storage,
    /// so the install default is filled in here — otherwise an untouched item
    /// would show no segment selected.
    var resolvedItemDestinations: [String: DocumentLocation] {
        let installed = DocumentLocation(status: .inInstalledList, locationId: pullListState.id)
        var resolved: [String: DocumentLocation] = [:]
        for item in itemsByRoom.values.joined() {
            resolved[item.id] = sessionState?.itemDestinations[item.id] ?? installed
        }
        return resolved
    }

    @MainActor
    func storeItem(itemId: String, warehouseId: String) async {
        guard isOwner, let session = sessionState else { return }
        do {
            try await sessionRepo.assign(
                sessionId: session.id,
                itemIds: [itemId],
                destination: DocumentLocation(status: .inStorage, locationId: warehouseId)
            )
        } catch {
            present(error)
        }
    }

    /// Installing is the default, so this clears the diversion rather than
    /// writing one.
    @MainActor
    func installItem(itemId: String) async {
        guard isOwner, let session = sessionState else { return }
        do {
            try await sessionRepo.unassign(sessionId: session.id, itemIds: [itemId])
        } catch {
            present(error)
        }
    }
}
