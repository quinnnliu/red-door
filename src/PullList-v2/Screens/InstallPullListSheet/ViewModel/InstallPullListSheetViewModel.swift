//
//  InstallPullListSheetViewModel.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/6/26.
//

import Foundation
import Firebase

/// Split across `+Loading`, `+Session`, `+Assignment`, and `+Commit` files.
@Observable
final class InstallPullListSheetViewModel {

    // MARK: - Documents

    var pullListState: PullListV2
    var rooms: [RoomV2] = []
    var itemsByRoom: [String: [ItemV2]] = [:] // key: roomId
    var storageLocations: [StorageLocation] = []

    var essentialsGroupState: EssentialsGroup? = nil
    var essentialsAccessories: Accessories? = nil

    /// Server truth for the install plan, replaced wholesale by the listener.
    var sessionState: InstallSession? = nil

    // MARK: - Local UI state

    var isLoading: Bool = false
    var showAlert: Bool = false
    var alertText: String = ""
    var showConfirmSheet: Bool = false

    // MARK: - Session bookkeeping

    var myGeneration: Int? = nil
    var didObserveSession: Bool = false
    var didCommit: Bool = false
    var sessionEndedByOtherUser: Bool = false

    // MARK: - Collaborators

    let loader: ItemsListLoader
    let itemRepo: ItemRepository
    let roomRepo: RoomRepository
    let pullListRepo: PullListRepository
    let sessionRepo: InstallSessionRepository
    let installedListRepo: InstalledListRepository
    let installedRoomRepo: RoomRepository
    let essentialsRepo: EssentialsRepository
    let accessoriesRepo: AccessoriesRepository
    let storageLocationRepo: StorageLocationRepository
    let configService: ConfigurationService

    private var roomsListener: ListenerRegistration? = nil
    private var sessionListener: ListenerRegistration? = nil

    // MARK: - init

    init(
        from list: PullListV2,
        rooms: [RoomV2] = [],
        itemsByRoom: [String: [ItemV2]] = [:],
        configService: ConfigurationService = .shared
    ) {
        self.pullListState = list
        self.itemRepo = ItemRepository()
        self.roomRepo = RoomRepository(list: list)
        self.pullListRepo = PullListRepository()
        self.sessionRepo = InstallSessionRepository()
        self.installedListRepo = InstalledListRepository()
        self.installedRoomRepo = RoomRepository(parentCollectionName: InstalledListV2.collectionName, listId: list.id)
        self.essentialsRepo = EssentialsRepository()
        self.accessoriesRepo = AccessoriesRepository()
        self.storageLocationRepo = StorageLocationRepository()
        self.configService = configService
        self.rooms = rooms
        self.itemsByRoom = itemsByRoom
        self.loader = ItemsListLoader(itemRepo: self.itemRepo, seed: Array(itemsByRoom.values.joined()))
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
        alertText = ""

        roomsListener = roomRepo.addRoomsListener { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let rooms):
                    await self?.handleRoomSnapshot(rooms)
                case .failure(let error):
                    self?.handleListenerError(error)
                }
            }
        }

        sessionListener = sessionRepo.addSessionListener(id: pullListState.id) { [weak self] result in
            Task { @MainActor in
                self?.handleSessionSnapshot(result)
            }
        }

        await joinOrCreateSession()
        await getStorageLocations()
    }

    func stopListening() {
        roomsListener?.remove()
        roomsListener = nil
        sessionListener?.remove()
        sessionListener = nil
        loader.invalidate()
        itemsByRoom.removeAll()
    }

    // MARK: - present

    func present(_ error: Error) {
        alertText = error.localizedDescription
        showAlert = true
    }
}
