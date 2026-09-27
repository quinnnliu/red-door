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
    var warehouses: [WarehouseV2] = []

    /// Server truth for the uninstall plan, replaced wholesale by the listener.
    var sessionState: UninstallSession? = nil

    // MARK: - Local UI state

    /// Ephemeral per-user state. Deliberately NOT stored on the session:
    /// selection is not shared between users, only assignments are.
    var selectedItemIds: Set<String> = []

    var isLoading: Bool = false
    var showAlert: Bool = false
    var alertMessage: String = ""
    var showDestinationSheet: Bool = false
    var showConfirmSheet: Bool = false

    // MARK: - Session bookkeeping

    /// The lock generation this client claimed. In-memory only: if the app is
    /// killed the owner forgets it holds the lock and reopens as a viewer,
    /// which costs one tap to reclaim. Persisting it would reintroduce
    /// per-device state for no real gain.
    var myGeneration: Int? = nil

    /// True once a real session document has been seen. The listener fires
    /// `.success(nil)` at startup because it is attached before the session is
    /// created, so "vanished" can only be inferred after observing one.
    var didObserveSession: Bool = false

    /// Set when this client's own commit succeeded, so consuming the session
    /// ourselves isn't mistaken for another user finishing it.
    var didCommit: Bool = false

    /// The session disappeared out from under us. The view reads this to send
    /// the user back once they acknowledge the alert.
    var sessionEndedByOtherUser: Bool = false

    // MARK: - Collaborators

    let loader: ItemsListLoader
    let installedListRepo: InstalledListRepository
    let itemRepo: ItemRepository
    let sessionRepo: UninstallSessionRepository
    let pullListRepo: PullListRepository
    let warehouseRepo: WarehouseRepository
    let configService: ConfigurationService

    private let installedRoomRepo: RoomRepository
    private var roomsListener: ListenerRegistration? = nil
    private var sessionListener: ListenerRegistration? = nil

    // MARK: - init

    init(
        list: InstalledListV2,
        installedListRepo: InstalledListRepository,
        installedRoomRepo: RoomRepository,
        itemRepo: ItemRepository,
        sessionRepo: UninstallSessionRepository,
        pullListRepo: PullListRepository,
        warehouseRepo: WarehouseRepository,
        configService: ConfigurationService = .shared
    ) {
        self.installedListState = list
        self.installedListRepo = installedListRepo
        self.installedRoomRepo = installedRoomRepo
        self.itemRepo = itemRepo
        self.sessionRepo = sessionRepo
        self.pullListRepo = pullListRepo
        self.warehouseRepo = warehouseRepo
        self.configService = configService
        self.loader = ItemsListLoader(itemRepo: itemRepo)
    }

    deinit {
        stopListening()
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
        await loadWarehouses()
    }

    func stopListening() {
        roomsListener?.remove()
        roomsListener = nil
        sessionListener?.remove()
        sessionListener = nil
        loader.invalidate()
        itemsByRoom.removeAll()
        selectedItemIds.removeAll()
    }

    // MARK: - present

    func present(_ error: Error) {
        alertMessage = error.localizedDescription
        showAlert = true
    }
}
