//
//  UninstallInstalledListSheetViewModel.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/27/26.
//

import Foundation
import Firebase

/// Split across `+Loading`, `+Session`, `+Assignment`, and `+Commit` files. Stored
/// properties have to live here (Swift extensions can't add them), and the
/// session flags are `internal` rather than `private` so those extensions can
/// reach them across file boundaries.
@Observable
final class UninstallInstalledListSheetViewModel {

    // MARK: - Documents

    var installedListState: InstalledListV2
    var rooms: [RoomV2] = []
    var itemsByRoom: [String: [ItemV2]] = [:] // key: roomId
    var storageLocations: [StorageLocation] = []

    var essentialsGroupState: EssentialsGroup? = nil
    var essentialsAccessories: Accessories? = nil

    /// Loaded so the flow can show what moves as a unit, even though the group
    /// is assigned with a single action.
    var essentialsItems: [ItemV2] = []

    var sessionState: UninstallSession? = nil

    var existingPullList: PullListV2? = nil

    // MARK: - Local UI state

    var selectedItemIds: Set<String> = []
    var essentialsSelected: Bool = false

    var isLoading: Bool = false
    var showAlert: Bool = false
    var alertMessage: String = ""
    var showDestinationSheet: Bool = false
    var showConfirmSheet: Bool = false

    // MARK: - Session bookkeeping

    /// The lock generation this client claimed.
    var myGeneration: Int? = nil

    var didObserveSession: Bool = false

    var didCommit: Bool = false

    var sessionEndedByOtherUser: Bool = false

    // MARK: - Collaborators

    let loader: ItemsListLoader
    let installedListRepo: InstalledListRepository
    let itemRepo: ItemRepository
    let sessionRepo: UninstallSessionRepository
    let pullListRepo: PullListRepository
    let essentialsRepo: EssentialsRepository
    let accessoriesRepo: AccessoriesRepository
    let storageLocationRepo: StorageLocationRepository
    let configService: ConfigurationService

    private let installedRoomRepo: RoomRepository<InstalledListV2>
    private var roomsListener: ListenerRegistration? = nil
    private var sessionListener: ListenerRegistration? = nil

    // MARK: - init

    init(
        list: InstalledListV2,
        installedListRepo: InstalledListRepository,
        installedRoomRepo: RoomRepository<InstalledListV2>,
        itemRepo: ItemRepository,
        sessionRepo: UninstallSessionRepository,
        pullListRepo: PullListRepository,
        essentialsRepo: EssentialsRepository,
        accessoriesRepo: AccessoriesRepository,
        storageLocationRepo: StorageLocationRepository,
        configService: ConfigurationService = .shared
    ) {
        self.installedListState = list
        self.installedListRepo = installedListRepo
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

    /// Detaches only: `deinit` can run on any thread, while the rest of
    /// `stopListening()` mutates state the UI reads on the main thread.
    deinit {
        roomsListener?.remove()
        sessionListener?.remove()
    }

    // MARK: - start / stop listening

    @MainActor
    func startListening() async {
        guard roomsListener == nil else { return }
        isLoading = true
        alertMessage = ""

        roomsListener = installedRoomRepo.addRoomsListener { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let rooms):
                    await self?.handleRoomSnapshot(rooms)
                case .failure(let error):
                    self?.handleListenerError(error)
                }
            }
        }

        sessionListener = sessionRepo.addSessionListener(id: installedListState.id) { [weak self] result in
            Task { @MainActor in
                self?.handleSessionSnapshot(result)
            }
        }

        await joinOrCreateSession()
        await loadStorageLocations()
        await loadEssentialsGroup()
    }

    func stopListening() {
        roomsListener?.remove()
        roomsListener = nil
        sessionListener?.remove()
        sessionListener = nil
        loader.invalidate()
        itemsByRoom.removeAll()
        selectedItemIds.removeAll()
        essentialsSelected = false
    }

    // MARK: - present

    func present(_ error: Error) {
        alertMessage = error.localizedDescription
        showAlert = true
    }
}
