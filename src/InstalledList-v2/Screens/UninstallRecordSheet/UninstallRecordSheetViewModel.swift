//
//  UninstallRecordSheetViewModel.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/28/26.
//

import Foundation

@Observable
final class UninstallRecordSheetViewModel {

    // MARK: - Documents

    let installedList: InstalledListV2
    var record: UninstallSession? = nil
    var rooms: [RoomV2] = []
    var itemsByRoom: [String: [ItemV2]] = [:] // key: roomId
    var storageLocations: [StorageLocation] = []

    var essentialsGroupState: EssentialsGroup? = nil
    var essentialsAccessories: Accessories? = nil
    var essentialsItems: [ItemV2] = []

    var copyPullList: PullListV2? = nil
    var existingPullList: PullListV2? = nil

    // MARK: - Local UI state

    var isLoading: Bool = false

    /// Uninstalled before records were kept, so there is nothing to show.
    var recordMissing: Bool = false
    var showAlert: Bool = false
    var alertMessage: String = ""

    // MARK: - Collaborators

    private let loader: ItemsListLoader
    private let installedRoomRepo: RoomRepository
    private let itemRepo: ItemRepository
    private let sessionRepo: UninstallSessionRepository
    private let pullListRepo: PullListRepository
    private let essentialsRepo: EssentialsRepository
    private let accessoriesRepo: AccessoriesRepository
    private let storageLocationRepo: StorageLocationRepository
    private let configService: ConfigurationService

    // MARK: - init

    init(
        list: InstalledListV2,
        installedRoomRepo: RoomRepository,
        itemRepo: ItemRepository,
        sessionRepo: UninstallSessionRepository,
        pullListRepo: PullListRepository,
        essentialsRepo: EssentialsRepository,
        accessoriesRepo: AccessoriesRepository,
        storageLocationRepo: StorageLocationRepository,
        configService: ConfigurationService = .shared
    ) {
        self.installedList = list
        self.installedRoomRepo = installedRoomRepo
        self.itemRepo = itemRepo
        self.sessionRepo = sessionRepo
        self.pullListRepo = pullListRepo
        self.essentialsRepo = essentialsRepo
        self.accessoriesRepo = accessoriesRepo
        self.storageLocationRepo = storageLocationRepo
        self.configService = configService
        self.loader = ItemsListLoader(itemRepo: itemRepo)
    }
}

// MARK: - Loading

extension UninstallRecordSheetViewModel {

    /// One pass, no listeners: a committed record never changes.
    @MainActor
    func load() async {
        guard record == nil, !recordMissing else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let record = try await sessionRepo.get(id: installedList.id)
            guard record.uninstalled else {
                recordMissing = true
                return
            }
            self.record = record
        } catch {
            recordMissing = true
            return
        }

        do {
            rooms = try await installedRoomRepo.getAll()
            for room in rooms {
                itemsByRoom[room.id] = try await loader.items(for: room)
            }
            storageLocations = try await configService.getAll(using: storageLocationRepo)
            try await loadEssentials()
            await resolveTargetLists()
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }

    @MainActor
    private func loadEssentials() async throws {
        guard let record, let groupId = record.essentialsGroupId else { return }

        essentialsGroupState = try await essentialsRepo.get(id: groupId)

        // Members come from the record's own snapshot rather than the group's
        // current membership, which changes the moment it is restaged elsewhere.
        essentialsItems = try await itemRepo.get(ids: record.essentialsItemIds)
            .sorted { $0.displayName < $1.displayName }

        if let accessoriesId = essentialsGroupState?.accessoriesId {
            essentialsAccessories = try await accessoriesRepo.get(id: accessoriesId)
        }
    }

    /// Names only, and best-effort: a target list that has since been installed
    /// or deleted falls back to a generic label rather than failing the screen.
    @MainActor
    private func resolveTargetLists() async {
        guard let record else { return }

        if let copyId = record.copyPullListId, record.targetsCopy {
            copyPullList = try? await pullListRepo.get(id: copyId)
        }
        if let existingId = record.existingPullListId {
            existingPullList = try? await pullListRepo.get(id: existingId)
        }
    }
}

// MARK: - Derived state

extension UninstallRecordSheetViewModel {

    var essentialsItemIds: Set<String> {
        Set(record?.essentialsItemIds ?? [])
    }

    var uninstalledDateLabel: String? {
        guard let raw = record?.uninstalledDate,
              let date = ISO8601DateFormatter().date(from: raw)
        else { return nil }
        return date.formatted(date: .abbreviated, time: .shortened)
    }

}

// MARK: - UninstallDestinationSectioning

extension UninstallRecordSheetViewModel: UninstallDestinationSectioning {

    var uninstallSession: UninstallSession? { record }

    var copyOriginDisplayName: String { installedList.displayName }

    var copyListAddress: Address? { record?.copyListAddress ?? copyPullList?.address }

    /// A record only lists destinations something actually went to — nothing
    /// here is a drop target.
    var showCopySection: Bool { record?.targetsCopy == true }

    var showExistingSection: Bool { record?.targetsExistingList == true }
}
