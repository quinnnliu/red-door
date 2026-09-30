//
//  UninstallDestinationSections.swift
//  RedDoor
//
//  Created by Quinn Liu on 09/28/26.
//

import Foundation

protocol UninstallDestinationSectioning {
    var uninstallSession: UninstallSession? { get }
    var rooms: [RoomV2] { get }
    var itemsByRoom: [String: [ItemV2]] { get }
    var storageLocations: [StorageLocation] { get }
    var essentialsItemIds: Set<String> { get }
    var existingPullList: PullListV2? { get }

    /// The installed list the copy came from, which is what names the section.
    var copyOriginDisplayName: String { get }
    var copyListAddress: Address? { get }

    var showCopySection: Bool { get }
    var showExistingSection: Bool { get }
}

// MARK: - Items

extension UninstallDestinationSectioning {

    var copyListAddress: Address? { uninstallSession?.copyListAddress }

    func destination(for itemId: String) -> UninstallDestination? {
        uninstallSession?.itemDestinations[itemId]
    }

    /// Excludes essentials members throughout: they render in their own
    /// section and move as a unit.
    var allRoomItems: [(item: ItemV2, room: RoomV2)] {
        rooms.flatMap { room in
            (itemsByRoom[room.id] ?? [])
                .filter { !essentialsItemIds.contains($0.id) }
                .map { (item: $0, room: room) }
        }
    }

    private func items(for type: UninstallDestinationType) -> [(item: ItemV2, room: RoomV2)] {
        allRoomItems
            .filter { destination(for: $0.item.id)?.type == type }
            .sorted { $0.item.displayName < $1.item.displayName }
    }

    /// Storage is the only destination that can fan out — every storage location is
    /// offered — so it keeps a grouping level the other two don't need.
    var storageGroups: [(storageLocationId: String, storageLocation: String, items: [(item: ItemV2, room: RoomV2)])] {
        var order: [String] = []
        var groups: [String: [(item: ItemV2, room: RoomV2)]] = [:]

        for entry in items(for: .storage) {
            guard let storageLocationId = destination(for: entry.item.id)?.locationId else { continue }
            if groups[storageLocationId] == nil {
                order.append(storageLocationId)
                groups[storageLocationId] = []
            }
            groups[storageLocationId]?.append(entry)
        }

        return order.map { id in
            (storageLocationId: id, storageLocation: storageLocationName(id), items: groups[id]!)
        }
    }

    var storageItemCount: Int { storageGroups.reduce(0) { $0 + $1.items.count } }

    var copyItems: [(item: ItemV2, room: RoomV2)] { items(for: .copy) }

    var existingListItems: [(item: ItemV2, room: RoomV2)] { items(for: .existingList) }
}

// MARK: - Labels

extension UninstallDestinationSectioning {

    func storageLocationName(_ id: String) -> String {
        storageLocations.first(where: { $0.id == id })?.displayName ?? "Storage"
    }

    var copySectionTitle: String { "Copy of \(copyOriginDisplayName)" }

    var copySectionSubtitle: String? {
        copyListAddress.map { $0.getStreetAddress() ?? $0.formattedAddress }
    }

    var existingSectionTitle: String { existingPullList?.displayName ?? "Pull list" }

    var essentialsDestinationLabel: (title: String, subtitle: String?)? {
        uninstallSession?.essentialsDestination.map { label(for: $0) }
    }

    func label(for destination: UninstallDestination) -> (title: String, subtitle: String?) {
        switch destination.type {
        case .storage:
            return (storageLocationName(destination.locationId), nil)
        case .copy:
            return (copySectionTitle, copySectionSubtitle)
        case .existingList:
            return (existingSectionTitle, nil)
        }
    }
}
