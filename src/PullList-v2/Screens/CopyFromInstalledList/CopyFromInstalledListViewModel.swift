//
//  CopyFromInstalledListViewModel.swift
//  RedDoor
//
//  Created by Quinn Liu on 09/29/26.
//

import Foundation

@Observable
final class CopyFromInstalledListViewModel {

    // MARK: - Source documents

    let installedList: InstalledListV2
    var rooms: [RoomV2] = []
    var itemsByRoom: [String: [ItemV2]] = [:] // key: roomId
    var essentialsGroup: EssentialsGroup? = nil
    var essentialsAccessories: Accessories? = nil
    var essentialsItems: [ItemV2] = []

    // MARK: - Draft for the new list

    let newListId: String = UUID().uuidString
    var address: Address? = nil
    var installDate: Date = .now
    var uninstallDate: Date = .now
    var clientId: String

    // MARK: - Local UI state

    var isLoading: Bool = false
    var isCreating: Bool = false
    var showAlert: Bool = false
    var alertMessage: String = ""

    // MARK: - Collaborators

    private let loader: ItemsListLoader
    private let installedRoomRepo: RoomRepository<InstalledListV2>
    private let itemRepo: ItemRepository
    private let pullListRepo: PullListRepository
    private let essentialsRepo: EssentialsRepository
    private let accessoriesRepo: AccessoriesRepository

    // MARK: - init

    init(
        installedList: InstalledListV2,
        installedRoomRepo: RoomRepository<InstalledListV2>,
        itemRepo: ItemRepository,
        pullListRepo: PullListRepository,
        essentialsRepo: EssentialsRepository,
        accessoriesRepo: AccessoriesRepository
    ) {
        self.installedList = installedList
        self.clientId = installedList.clientId
        self.installedRoomRepo = installedRoomRepo
        self.itemRepo = itemRepo
        self.pullListRepo = pullListRepo
        self.essentialsRepo = essentialsRepo
        self.accessoriesRepo = accessoriesRepo
        self.loader = ItemsListLoader(itemRepo: itemRepo)
    }

    // MARK: - Loading

    @MainActor
    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            rooms = try await installedRoomRepo
                .get(ids: installedList.roomIds)
                .sorted { $0.displayName < $1.displayName }

            for room in rooms {
                itemsByRoom[room.id] = try await loader.items(for: room)
            }

            try await loadEssentials()
        } catch {
            present(error)
        }
    }

    @MainActor
    private func loadEssentials() async throws {
        guard let groupId = installedList.essentialGroupId else { return }

        let group = try await essentialsRepo.get(id: groupId)
        essentialsGroup = group
        essentialsItems = try await loader.items(for: group)

        if let accessoriesId = group.accessoriesId {
            essentialsAccessories = try await accessoriesRepo.get(id: accessoriesId)
        }
    }
}

// MARK: - Availability

extension CopyFromInstalledListViewModel {

    var allSourceItems: [ItemV2] {
        rooms.flatMap { itemsByRoom[$0.id] ?? [] }
    }

    var totalItemCount: Int { allSourceItems.count }

    var copyableItemCount: Int { allSourceItems.filter(isCopyable).count }

    var isEssentialsGroupCopyable: Bool {
        guard let group = essentialsGroup, group.location.status.isAvailable else { return false }
        if let accessories = essentialsAccessories, !accessories.location.status.isAvailable {
            return false
        }
        return essentialsItems.allSatisfy { $0.location.status.isAvailable }
    }

    func isCopyable(_ item: ItemV2) -> Bool {
        isGroupMember(item) ? isEssentialsGroupCopyable : item.location.status.isAvailable
    }

    /// Guards against an item that belongs to some *other* essentials group being
    /// judged against this list's group.
    func isGroupMember(_ item: ItemV2) -> Bool {
        guard let groupId = essentialsGroup?.id else { return false }
        return item.essentialGroupId == groupId
    }

    func unavailableReason(for item: ItemV2) -> String? {
        guard !isCopyable(item) else { return nil }
        if isGroupMember(item) { return "Essentials group unavailable" }
        return item.location.status.displayTitle
    }

    /// Items claimed individually. Group members are excluded because the commit
    /// re-derives them from the group itself.
    var candidateItemIds: Set<String> {
        Set(
            allSourceItems
                .filter { !isGroupMember($0) && $0.location.status.isAvailable }
                .map(\.id)
        )
    }

    var canCreate: Bool { address != nil && !isLoading && !isCreating }

    var confirmationMessage: String {
        "\(copyableItemCount) of \(totalItemCount) items can be copied over. Proceed?"
    }
}

// MARK: - Commit

extension CopyFromInstalledListViewModel {

    @MainActor
    func createCopy() async -> CopyFromInstalledOutcome? {
        guard let address else { return nil }

        isCreating = true
        defer { isCreating = false }

        do {
            return try await pullListRepo.createCopy(
                from: installedList,
                newListId: newListId,
                address: address,
                installDate: installDate,
                uninstallDate: uninstallDate,
                clientId: clientId,
                sourceRooms: rooms,
                candidateItemIds: candidateItemIds,
                essentialsGroup: isEssentialsGroupCopyable ? essentialsGroup : nil,
                itemRepo: itemRepo,
                essentialsRepo: essentialsRepo,
                accessoriesRepo: accessoriesRepo
            )
        } catch {
            present(error)
            return nil
        }
    }

    /// Something was claimed between previewing the counts and confirming them.
    func droppedMessage(for outcome: CopyFromInstalledOutcome) -> String? {
        var parts: [String] = []
        if outcome.droppedItemCount > 0 {
            let noun = outcome.droppedItemCount == 1 ? "item" : "items"
            parts.append("\(outcome.droppedItemCount) \(noun)")
        }
        if outcome.droppedEssentialsGroup {
            parts.append("the essentials group")
        }
        guard !parts.isEmpty else { return nil }
        return "Created, but \(parts.joined(separator: " and ")) got claimed by another list first."
    }

    @MainActor
    func present(_ error: Error) {
        alertMessage = error.localizedDescription
        showAlert = true
    }
}
